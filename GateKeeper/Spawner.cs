using Godot;
using System;
using System.Collections.Generic;
using System.IO;

public partial class Spawner : Node3D
{
	// REMOVED FrameScene (A15 uses template duplication)	
	// [A15][SEGMENT_ALIGN_WITH_FRAMES]
	// Segment debe duplicarse por frame usando mismo Z
	[Export] public PackedScene WallScene;
	[Export] public PackedScene FloorScene;
	[Export] public PackedScene CeilingScene;
	[Export] public PackedScene CornerPieceScene;
	private static Node3D GetOrCreateContainer(Node3D parent, string containerName)
	{
		var existing = parent.GetNodeOrNull<Node3D>(containerName);
		if (existing != null)
			return existing;

		var n = new Node3D { Name = containerName };
		parent.AddChild(n);
		return n;
	}

	private void SpawnPiece(PackedScene scene, Vector3 position, Node3D container)
	{
		if (scene == null || container == null)
		{
			GD.Print("[SPAWNER][PIECE_SKIP]");
			return;
		}

		var seg = scene.Instantiate<Node3D>();
		container.AddChild(seg);
		seg.Position = position;
		GD.Print($"[SPAWNER][SEGMENT] pos={position}");
	}


		// [A15][REQUIRED] path hacia contenedor Frames
	[Export] public NodePath FramesRootPath { get; set; } = new NodePath("../Frames");

	private Node3D _framesRoot;
	private RealmController _rc;

	private bool _snapshotLoaded = false;

	// [Cambio 273] diagnóstico refresh — evitar spam (1 Hz)
	private double _snapshotRefreshCheckTimer = 0;
	private readonly Dictionary<string, string> _lastWallSignatureByKey = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
	private readonly Dictionary<string, string> _lastFrameDisplaySignatureByKey = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

	/// <summary>Tras rechazar snapshot (bridge ≠ JSON): backoff antes de reintentar con refresh_now.</summary>
	private double _snapshotReloadBackoffSec;

	private static string RealmSnapshotDir => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "snapshot");
	private static string SnapshotCurrentJsonPath => Path.Combine(RealmSnapshotDir, "current.json");

	// --- Corredor recto Z: QuadMesh Size=(PanelHeight,PanelWidth); con rot -90°Y la extensión en +Z es PanelHeight. ---
	public const int FrameSlotCount = 20;
	private const float PanelWidth = 3.32f;
	private const float PanelHeight = 4.33f;
	/// <summary>Metros del panel a lo largo del corredor (eje Z tras rotar el quad).</summary>
	private const float PanelExtentAlongCorridorZ = PanelHeight;
	/// <summary>Mínimo entre bordes de dos fotos consecutivas en la misma pared (centros = extent + esto).</summary>
	private const float MinMetersBetweenWallPhotosZ = 0.25f;
	private static float PanelCenterStepAlongZ => PanelExtentAlongCorridorZ + MinMetersBetweenWallPhotosZ;
	private const float SafetyMargin = 1.45f;
	private const float MinSegmentGap = 6.0f;
	/// <summary>Margen Z entre el collage de un tramo y el marco siguiente (el collage queda más hacia -Z).</summary>
	private const float CollageClearBeforeNextFrameZ = -0.60f;
	/// <summary>Separación marco ↔ fin del collage en su propio tramo (empuja paneles hacia -Z, lejos del locus).</summary>
	private const float ParcourOffset = 1.1f;
	/// <summary>Centro del pasillo en X (cámara); el marco sigue en <see cref="MarcoStartX"/>.</summary>
	private const float CorridorCameraRigX = 0f;
	/// <summary>
	/// Desplazamiento extra en X (negativo = alejarse del plano de collage en +X) para no quedar incrustado en la pared lateral.
	/// </summary>
	private const float CorridorCameraLateralAwayFromWallX = -2.95f;
	/// <summary>En MAZE: empuja la cámara hacia el centro del pasillo (−<c>right</c>, mismo lado que el corredor Z).</summary>
	private const float CameraMazeLateralAwayFromWallMeters = 2f;
	/// <summary>Metros que retrocede la cámara desde el plano del marco hacia el interior del tramo (evita spawn pegado a collage/pared).</summary>
	private const float CameraStandoffFromFrameMeters = 4.6f;
	private const float WallWidthConst = 3.2f;
	private const float FloorCeilingExtraLengthMeters = 3.5f;
	/// <summary>Plano de pared en X (coincide con ancho de panel en eje X tras rotación -90°).</summary>
	private const float WallPlaneX = 3.2f;
	private const float MarcoStartX = 2.8f;
	private const float MarcoStartY = 1.6f;
	private const float MarcoStartZ = 10.0f;

	/// <summary>Dirección del tramo de entrada al marco 0 (antes de cualquier <c>spatialTurn</c> en seq 0).</summary>
	private static readonly Vector3 MazeIncomingToFrame0 = new Vector3(0f, 0f, 1f);

	/// <summary>Metros rectos **después** del marco que declara el giro, antes de cambiar de dirección (buffer; no es “lead” del collage).</summary>
	private const float MazeFrameTurnBufferMeters = 1.5f;

	/// <summary>Metros en la **nueva** dirección tras el buffer (hacia el siguiente marco).</summary>
	private const float MazeOutgoingAfterTurnMeters = 6f;

	/// <summary>Tramo sin giro: una sola recta de 6 m.</summary>
	private const float MazeStraightEdgeMeters = 6f;

	private readonly float[] _frameZPositions = new float[FrameSlotCount];
	private bool _corridorLayoutBuilt;

	/// <summary>Posiciones de marco en MAZE tras expandir tramos para <see cref="ComputeSegmentGap"/> (collages).</summary>
	private Vector3[] _mazeExpandedFramePositions;

	// [SCOPE:MAZE_OVERRIDE]
	private Dictionary<int, Vector3> _mazeDirections = new Dictionary<int, Vector3>();

	/// <summary>LB snapshot <c>spatialTurn</c> por <c>seq</c> (left/right; vacío = recto). El yaw del marco <c>seq</c> acumula giros en 0..seq-1.</summary>
	private readonly string[] _spatialTurnBySeq = new string[FrameSlotCount];

	// [SCOPE:SEGMENT_FRAME_BASE]
	private struct SegmentFrame
	{
		public Vector3 Position;
		public Vector3 Forward;
		public Vector3 Right;
		public Vector3 Up;
	}

	// [SCOPE:LAYOUT_MODE]
	private bool HasSpatialTurns()
	{
		for (var i = 0; i < FrameSlotCount; i++)
		{
			if (_spatialTurnBySeq[i] == "left" || _spatialTurnBySeq[i] == "right")
				return true;
		}
		return false;
	}

	private string GetLayoutMode()
	{
		return HasSpatialTurns() ? "MAZE" : "CORRIDOR_Z";
	}

	private static string[] EmptyKeysCorridor()
	{
		var a = new string[FrameSlotCount];
		for (var i = 0; i < FrameSlotCount; i++)
			a[i] = "";
		return a;
	}

	/// <summary>Longitud Z ocupada por los paneles (borde del primero → borde del último).</summary>
	private static float TotalZSpanForPanels(int count)
	{
		if (count <= 0)
			return 0f;
		return PanelExtentAlongCorridorZ + Mathf.Max(0, count - 1) * PanelCenterStepAlongZ;
	}

	/// <summary>Gaps entre marcos: paneles + márgenes + hueco para no invadir el marco anterior (quad ~2 m en Z).</summary>
	private static float ComputeSegmentGap(int imageCount)
	{
		if (imageCount == 0)
			return MinSegmentGap;
		var span = TotalZSpanForPanels(imageCount) + 2f * SafetyMargin + CollageClearBeforeNextFrameZ;
		return Mathf.Max(MinSegmentGap, span);
	}

	private void RebuildCorridorZLayout(string[] keysBySeq)
	{
		_frameZPositions[0] = MarcoStartZ;
		for (var i = 1; i < FrameSlotCount; i++)
		{
			var k = i < keysBySeq.Length ? keysBySeq[i] : "";
			var n = AlexandriaAssets.GetWallCollageGroups(k).Count;
			_frameZPositions[i] = _frameZPositions[i - 1] + ComputeSegmentGap(n);
		}

		_corridorLayoutBuilt = true;
	}

	/// <summary>
	/// Recorre el mismo grafo que <see cref="BuildAllMazeSegments"/>; cada arista (recta o salida tras esquina) tiene longitud
	/// ≥ <see cref="ComputeSegmentGap"/> del locus destino, para que los collages no se recorten.
	/// </summary>
	private void RebuildMazeExpandedFramePositions(string[] keysBySeq)
	{
		_mazeExpandedFramePositions = new Vector3[FrameSlotCount];
		_mazeExpandedFramePositions[0] = GetPositionFromSeq(0);

		for (var dest = 1; dest < FrameSlotCount; dest++)
		{
			var k = dest < keysBySeq.Length ? keysBySeq[dest] : "";
			var requiredGap = ComputeSegmentGap(AlexandriaAssets.GetWallCollageGroups(k).Count);
			var pPrev = _mazeExpandedFramePositions[dest - 1];
			var turnAtEdge = _spatialTurnBySeq[dest - 1];

			if (turnAtEdge == "left" || turnAtEdge == "right")
			{
				var incoming = dest - 1 > 0
					? GetPersistentDirection(dest - 2)
					: new Vector3(0f, 0f, 1f);
				var corner = pPrev + incoming * MazeFrameTurnBufferMeters;
				var outgoing = GetPersistentDirection(dest - 1).Normalized();
				var along = Mathf.Max(requiredGap, MazeOutgoingAfterTurnMeters);
				_mazeExpandedFramePositions[dest] = new Vector3(
					corner.X + outgoing.X * along,
					MarcoStartY,
					corner.Z + outgoing.Z * along);
			}
			else
			{
				var forward = GetPersistentDirection(dest - 1).Normalized();
				var along = Mathf.Max(requiredGap, MazeStraightEdgeMeters);
				_mazeExpandedFramePositions[dest] = new Vector3(
					pPrev.X + forward.X * along,
					MarcoStartY,
					pPrev.Z + forward.Z * along);
			}
		}
	}

	private static bool ResolveSnapshotPath(string bridgeCtx, out string path, out bool usedCurrentJsonFallback)
	{
		usedCurrentJsonFallback = false;
		bridgeCtx = (bridgeCtx ?? "").Trim();
		if (string.IsNullOrEmpty(bridgeCtx))
		{
			path = SnapshotCurrentJsonPath;
			return File.Exists(path);
		}

		var keyed = Path.Combine(RealmSnapshotDir, bridgeCtx + ".json");
		if (File.Exists(keyed))
		{
			path = keyed;
			return true;
		}

		if (File.Exists(SnapshotCurrentJsonPath))
		{
			path = SnapshotCurrentJsonPath;
			usedCurrentJsonFallback = true;
			return true;
		}

		path = keyed;
		return false;
	}

	/// <summary>
	/// Evita aplicar <c>current.json</c> del hijo cuando el bridge ya apuntó al padre
	/// (GK corre antes que LibraryBuild). JSON nuevo incluye <c>contextKey</c>; legado: nombre de archivo keyed.
	/// </summary>
	private static bool SnapshotDataMatchesBridge(Godot.Collections.Dictionary data, string bridgeCtx, string resolvedPath, bool usedCurrentJsonFallback)
	{
		bridgeCtx = (bridgeCtx ?? "").Trim();
		if (string.IsNullOrEmpty(bridgeCtx))
			return true;

		if (data.ContainsKey("contextKey"))
		{
			var v = data["contextKey"];
			var snapCtx = v.VariantType == Variant.Type.String ? v.AsString().Trim() : "";
			return string.Equals(snapCtx, bridgeCtx, StringComparison.OrdinalIgnoreCase);
		}

		if (!usedCurrentJsonFallback)
		{
			var fn = Path.GetFileNameWithoutExtension(resolvedPath);
			return string.Equals(fn, bridgeCtx, StringComparison.OrdinalIgnoreCase);
		}

		return false;
	}

	private bool TryReadSnapshotKeysFromDisk(string[] keysBySeq)
	{
		for (var i = 0; i < keysBySeq.Length; i++)
			keysBySeq[i] = "";
		var bridgeCtx = BridgeSpatial.ReadContextKey()?.Trim() ?? "";
		if (!ResolveSnapshotPath(bridgeCtx, out var path, out var usedFb))
			return false;

		try
		{
			var jsonText = File.ReadAllText(path);
			var jsonNode = new Json();
			if (jsonNode.Parse(jsonText) != Error.Ok)
				return false;
			var data = jsonNode.Data.AsGodotDictionary();
			if (!data.ContainsKey("frames"))
				return false;
			if (!SnapshotDataMatchesBridge(data, bridgeCtx, path, usedFb))
				return false;
			var frames = data["frames"].AsGodotArray();
			foreach (Variant f in frames)
			{
				var d = f.AsGodotDictionary();
				var seq = d["seq"].AsInt32();
				var key = d["key"].AsString();
				if (seq >= 0 && seq < keysBySeq.Length)
					keysBySeq[seq] = key;
			}

			return true;
		}
		catch
		{
			return false;
		}
	}

	private string[] GatherKeysFromFrames()
	{
		var arr = EmptyKeysCorridor();
		var fc = _framesRoot?.GetNodeOrNull<Node3D>("FramesContainer");
		if (fc == null)
			return arr;
		var n = Mathf.Min(FrameSlotCount, fc.GetChildCount());
		for (var i = 0; i < n; i++)
		{
			if (fc.GetChild(i) is FrameTemplate ft)
				arr[i] = ft.GetLocusKey() ?? "";
		}

		return arr;
	}

	private static void ClearContainerChildren(Node3D container)
	{
		if (container == null)
			return;
		var list = new List<Node>();
		foreach (var c in container.GetChildren())
			list.Add(c);
		foreach (var c in list)
			c.QueueFree();
	}

	private bool TryComputePanelBounds(float zA, float zB, int requestedCount, out int fittedCount, out float startZ, out float endZ)
	{
		fittedCount = Mathf.Max(0, requestedCount);
		while (fittedCount > 0)
		{
			var totalReserved = TotalZSpanForPanels(fittedCount);
			endZ = zB - ParcourOffset;
			startZ = endZ - totalReserved;
			if (startZ >= zA - 0.001f)
				return true;
			fittedCount--;
		}

		startZ = zA;
		endZ = zA;
		return false;
	}

	private void BuildPanelsForTramo(Node3D wallsContainer, float zA, float zB, List<AlexandriaAssets.CollageGroup> groups, string segmentName)
	{
		var segmentLength = Mathf.Max(0.01f, zB - zA);
		var backing = new MeshInstance3D { Name = segmentName + "_Backing" };
		var quadBack = new QuadMesh();
		quadBack.Size = new Vector2(WallWidthConst, segmentLength);
		backing.Mesh = quadBack;
		backing.Position = new Vector3(WallPlaneX, MarcoStartY, (zA + zB) * 0.5f);
		backing.RotationDegrees = new Vector3(0f, -90f, 0f);
		backing.Visible = false;
		wallsContainer.AddChild(backing);

		var working = new List<AlexandriaAssets.CollageGroup>(groups);
		if (!TryComputePanelBounds(zA, zB, working.Count, out var fittedCount, out var startZ, out var endZ))
			return;
		if (fittedCount < working.Count)
			working.RemoveRange(fittedCount, working.Count - fittedCount);

		if (working.Count == 0)
			return;

		if (working.Count < groups.Count)
			GD.PrintErr($"[PANEL_TRIM] {segmentName} trimmed {groups.Count - working.Count} collage groups (overflow)");

		var cursorZ = startZ + PanelExtentAlongCorridorZ * 0.5f;
		for (var i = 0; i < working.Count; i++)
		{
			var panel = new MeshInstance3D { Name = $"{segmentName}_Panel_{i:00}" };
			var q = new QuadMesh();
			q.Size = new Vector2(PanelHeight, PanelWidth);
			panel.Mesh = q;
			panel.Position = new Vector3(WallPlaneX, MarcoStartY, cursorZ);
			panel.RotationDegrees = new Vector3(0f, -90f, 0f);
			var tex = AlexandriaAssets.BuildCollageTexture(working[i].ImagePaths);
			if (tex != null)
			{
				var mat = new StandardMaterial3D();
				mat.AlbedoTexture = tex;
				mat.AlbedoColor = Colors.White;
				mat.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
				mat.CullMode = BaseMaterial3D.CullModeEnum.Disabled;
				panel.MaterialOverride = mat;
			}

			wallsContainer.AddChild(panel);
			cursorZ += PanelCenterStepAlongZ;
		}
	}

	private void SpawnFloorCeilingSegment(PackedScene scene, Node3D container, string nodeName, float y, float zA,
		float zB)
	{
		if (scene == null || container == null)
			return;
		var seg = scene.Instantiate<Node3D>();
		seg.Name = nodeName;
		container.AddChild(seg);
		var midZ = (zA + zB) * 0.5f;
		var len = Mathf.Max(0.01f, (zB - zA) + FloorCeilingExtraLengthMeters);
		seg.Position = new Vector3(0f, y, midZ);
		var s = len / 6f;
		seg.Scale = new Vector3(1f, 1f, s);
		CorridorVisualTheme.ApplyToFloorCeilingSegment(seg, y > 1.5f);
		GD.Print($"[SPAWNER][FLOOR_CEIL] {nodeName} zA={zA} zB={zB} len={len}");
	}

	private void BuildAllCorridorSegments(string[] keysBySeq, Node3D walls, Node3D floors, Node3D ceilings)
	{
		if (walls == null)
			return;
		for (var dest = 0; dest < FrameSlotCount; dest++)
		{
			var zB = _frameZPositions[dest];
			var k = dest < keysBySeq.Length ? keysBySeq[dest] : "";
			var groups = AlexandriaAssets.GetWallCollageGroups(k);
			var n = groups.Count;
			var zA = dest == 0 ? zB - ComputeSegmentGap(n) : _frameZPositions[dest - 1];
			BuildPanelsForTramo(walls, zA, zB, groups, $"Seg_{dest}");
			var floorA = zA;
			var floorB = zB;
			if (TryComputePanelBounds(zA, zB, groups.Count, out _, out var panelStartZ, out var panelEndZ))
			{
				floorA = panelStartZ;
				floorB = panelEndZ;
			}
			SpawnFloorCeilingSegment(FloorScene, floors, $"FloorSeg_{dest}", 0f, floorA, floorB);
			SpawnFloorCeilingSegment(CeilingScene, ceilings, $"CeilingSeg_{dest}", 3.2f, floorA, floorB);
		}
	}

	/// <summary>Offset lateral corredor Z: de marco (MarcoStartX) a plano de pared (WallPlaneX).</summary>
	private static float WallSideOffsetFromPath => WallPlaneX - MarcoStartX;

	/// <summary>Collage + suelo + techo a lo largo del tramo en planta (MAZE).</summary>
	private void BuildPanelsForTramoMaze(Node3D wallsContainer, Vector3 pA, Vector3 pB,
		List<AlexandriaAssets.CollageGroup> groups, string segmentName)
	{
		var flatA = new Vector3(pA.X, 0f, pA.Z);
		var flatB = new Vector3(pB.X, 0f, pB.Z);
		var segVec = flatB - flatA;
		var segLen = segVec.Length();
		if (segLen < 0.01f)
			return;
		var forward = segVec / segLen;
		var right = Vector3.Up.Cross(forward).Normalized();
		var wallOff = WallSideOffsetFromPath;
		var yawDeg = Mathf.RadToDeg(Mathf.Atan2(forward.X, forward.Z));

		var segmentLength = Mathf.Max(0.01f, segLen);
		var backing = new MeshInstance3D { Name = segmentName + "_Backing" };
		var quadBack = new QuadMesh();
		quadBack.Size = new Vector2(WallWidthConst, segmentLength);
		backing.Mesh = quadBack;
		var backMid = (flatA + flatB) * 0.5f + right * wallOff;
		backing.Position = new Vector3(backMid.X, MarcoStartY, backMid.Z);
		backing.RotationDegrees = new Vector3(0f, yawDeg - 90f, 0f);
		backing.Visible = false;
		wallsContainer.AddChild(backing);

		var working = new List<AlexandriaAssets.CollageGroup>(groups);
		if (!TryComputePanelBounds(0f, segLen, working.Count, out var fittedCount, out var startAlong, out var endAlong))
			return;
		if (fittedCount < working.Count)
			working.RemoveRange(fittedCount, working.Count - fittedCount);

		if (working.Count == 0)
			return;

		if (working.Count < groups.Count)
			GD.PrintErr($"[PANEL_TRIM_MAZE] {segmentName} trimmed {groups.Count - working.Count} collage groups (overflow)");

		var cursorAlong = startAlong + PanelExtentAlongCorridorZ * 0.5f;
		for (var i = 0; i < working.Count; i++)
		{
			var panel = new MeshInstance3D { Name = $"{segmentName}_Panel_{i:00}" };
			var q = new QuadMesh();
			q.Size = new Vector2(PanelHeight, PanelWidth);
			panel.Mesh = q;
			var posPath = flatA + forward * cursorAlong + right * wallOff;
			panel.Position = new Vector3(posPath.X, MarcoStartY, posPath.Z);
			panel.RotationDegrees = new Vector3(0f, yawDeg - 90f, 0f);
			var tex = AlexandriaAssets.BuildCollageTexture(working[i].ImagePaths);
			if (tex != null)
			{
				var mat = new StandardMaterial3D();
				mat.AlbedoTexture = tex;
				mat.AlbedoColor = Colors.White;
				mat.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
				mat.CullMode = BaseMaterial3D.CullModeEnum.Disabled;
				panel.MaterialOverride = mat;
			}

			wallsContainer.AddChild(panel);
			cursorAlong += PanelCenterStepAlongZ;
		}
	}

	/// <summary>
	/// Corredor Z: suelo en X=0, marco en <see cref="MarcoStartX"/>. En MAZE el tramo estaba centrado en la línea del
	/// recorrido (mismo X que el marco), el marco quedaba en medio de la losa; se desplaza el centro del suelo/techo
	/// con <c>-right * MarcoStartX</c> respecto al punto medio del segmento, como lateral del pasillo.
	/// </summary>
	private void SpawnFloorCeilingMazeSegment(PackedScene scene, Node3D container, string nodeName, float y,
		Vector3 flatA, Vector3 flatB)
	{
		if (scene == null || container == null)
			return;
		var segVec = new Vector3(flatB.X - flatA.X, 0f, flatB.Z - flatA.Z);
		var len = Mathf.Max(0.01f, segVec.Length() + FloorCeilingExtraLengthMeters);
		var forward = segVec.Length() > 0.001f ? segVec.Normalized() : new Vector3(0f, 0f, 1f);
		var right = Vector3.Up.Cross(forward).Normalized();
		var midFlat = (flatA + flatB) * 0.5f;
		var floorCenterFlat = midFlat - right * MarcoStartX;
		var yawDeg = Mathf.RadToDeg(Mathf.Atan2(forward.X, forward.Z));
		var seg = scene.Instantiate<Node3D>();
		seg.Name = nodeName;
		container.AddChild(seg);
		seg.Position = new Vector3(floorCenterFlat.X, y, floorCenterFlat.Z);
		seg.RotationDegrees = new Vector3(0f, yawDeg, 0f);
		var s = len / 6f;
		seg.Scale = new Vector3(1f, 1f, s);
		CorridorVisualTheme.ApplyToFloorCeilingSegment(seg, y > 1.5f);
		GD.Print($"[SPAWNER][FLOOR_CEIL_MAZE] {nodeName} len={len} yaw={yawDeg}");
	}

	private void BuildAllMazeSegments(string[] keysBySeq, Node3D walls, Node3D floors, Node3D ceilings)
	{
		if (walls == null || _mazeExpandedFramePositions == null || _mazeExpandedFramePositions.Length < FrameSlotCount)
			return;
		for (var dest = 0; dest < FrameSlotCount; dest++)
		{
			var k = dest < keysBySeq.Length ? keysBySeq[dest] : "";
			var groups = AlexandriaAssets.GetWallCollageGroups(k);
			var n = groups.Count;
			var pB = _mazeExpandedFramePositions[dest];
			Vector3 pA;
			if (dest == 0)
			{
				var gap = ComputeSegmentGap(n);
				// No usar GetPersistentDirection(0): ese vector ya aplica el giro en seq 0 (arco hacia marco 1).
				// El tramo que llega al marco 0 sigue siempre el eje +Z; si no, suelo/pared giran al revés que el marco 0.
				pA = pB - MazeIncomingToFrame0 * gap;
			}
			else
				pA = _mazeExpandedFramePositions[dest - 1];

			var turnAtEdge = dest > 0 && dest - 1 < FrameSlotCount
				? _spatialTurnBySeq[dest - 1]
				: "";
			if (dest > 0 && (turnAtEdge == "left" || turnAtEdge == "right"))
			{
				// Misma geometría que GetPositionFromSeq (MAZE): recta entrante (buffer) y luego recta saliente.
				// Evita la cuerda diagonal pA→pB, que hacía que el collage girara “desde” el marco pA.
				var incoming = dest - 1 > 0
					? GetPersistentDirection(dest - 2)
					: new Vector3(0f, 0f, 1f);
				var corner = pA + incoming * MazeFrameTurnBufferMeters;
				BuildPanelsForTramoMaze(walls, pA, corner, new List<AlexandriaAssets.CollageGroup>(),
					$"Seg_{dest}_turnBuffer");
				BuildPanelsForTramoMaze(walls, corner, pB, groups, $"Seg_{dest}");

				var flatCorner = new Vector3(corner.X, 0f, corner.Z);
				var flatA = new Vector3(pA.X, 0f, pA.Z);
				var flatB = new Vector3(pB.X, 0f, pB.Z);
				SpawnFloorCeilingMazeSegment(FloorScene, floors, $"FloorSeg_{dest}_buf", 0f, flatA, flatCorner);
				SpawnFloorCeilingMazeSegment(FloorScene, floors, $"FloorSeg_{dest}", 0f, flatCorner, flatB);
				SpawnFloorCeilingMazeSegment(CeilingScene, ceilings, $"CeilingSeg_{dest}_buf", 3.2f, flatA, flatCorner);
				SpawnFloorCeilingMazeSegment(CeilingScene, ceilings, $"CeilingSeg_{dest}", 3.2f, flatCorner, flatB);
			}
			else
			{
				BuildPanelsForTramoMaze(walls, pA, pB, groups, $"Seg_{dest}");

				var flatA = new Vector3(pA.X, 0f, pA.Z);
				var flatB = new Vector3(pB.X, 0f, pB.Z);
				SpawnFloorCeilingMazeSegment(FloorScene, floors, $"FloorSeg_{dest}", 0f, flatA, flatB);
				SpawnFloorCeilingMazeSegment(CeilingScene, ceilings, $"CeilingSeg_{dest}", 3.2f, flatA, flatB);
			}
		}
	}

	private void PrimeWallManifestSignatures()
	{
		_lastWallSignatureByKey.Clear();
		var keys = GatherKeysFromFrames();
		for (var i = 0; i < keys.Length; i++)
		{
			var k = keys[i] ?? "";
			if (string.IsNullOrWhiteSpace(k))
				continue;
			_lastWallSignatureByKey[k] = AlexandriaAssets.GetWallSourceSignature(k);
		}
	}

	private bool DidWallManifestChange()
	{
		var keys = GatherKeysFromFrames();
		var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		var changed = false;
		for (var i = 0; i < keys.Length; i++)
		{
			var k = (keys[i] ?? "").Trim();
			if (string.IsNullOrEmpty(k) || !seen.Add(k))
				continue;
			var sig = AlexandriaAssets.GetWallSourceSignature(k);
			if (!_lastWallSignatureByKey.TryGetValue(k, out var prev) || !string.Equals(prev, sig, StringComparison.Ordinal))
			{
				_lastWallSignatureByKey[k] = sig;
				changed = true;
			}
		}

		var stale = new List<string>();
		foreach (var k in _lastWallSignatureByKey.Keys)
		{
			if (!seen.Contains(k))
				stale.Add(k);
		}
		foreach (var k in stale)
			_lastWallSignatureByKey.Remove(k);

		return changed;
	}

	private void PrimeFrameDisplaySignatures()
	{
		_lastFrameDisplaySignatureByKey.Clear();
		var keys = GatherKeysFromFrames();
		for (var i = 0; i < keys.Length; i++)
		{
			var k = keys[i] ?? "";
			if (string.IsNullOrWhiteSpace(k))
				continue;
			_lastFrameDisplaySignatureByKey[k] = AlexandriaAssets.GetFrameDisplaySignature(k);
		}
	}

	private bool DidFrameDisplayChange()
	{
		var keys = GatherKeysFromFrames();
		var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		var changed = false;
		for (var i = 0; i < keys.Length; i++)
		{
			var k = (keys[i] ?? "").Trim();
			if (string.IsNullOrEmpty(k) || !seen.Add(k))
				continue;
			var sig = AlexandriaAssets.GetFrameDisplaySignature(k);
			if (!_lastFrameDisplaySignatureByKey.TryGetValue(k, out var prev) || !string.Equals(prev, sig, StringComparison.Ordinal))
			{
				GD.Print($"[SPAWNER][FRAME_DISP_CHANGE] key={k} prev={(prev ?? "(none)")} next={sig}");
				_lastFrameDisplaySignatureByKey[k] = sig;
				changed = true;
			}
		}

		var stale = new List<string>();
		foreach (var k in _lastFrameDisplaySignatureByKey.Keys)
		{
			if (!seen.Contains(k))
				stale.Add(k);
		}
		foreach (var k in stale)
			_lastFrameDisplaySignatureByKey.Remove(k);

		return changed;
	}

	private void RefreshAllFrameHeroMaterials()
	{
		if (_framesRoot == null)
			return;
		var fc = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
		if (fc == null)
			return;
		var n = Mathf.Min(FrameSlotCount, fc.GetChildCount());
		for (var i = 0; i < n; i++)
		{
			if (fc.GetChild(i) is FrameTemplate ft)
				ft.RefreshHeroFromDisk();
		}
	}

	private void ApplyCorridorGeometryAfterSnapshot()
	{
		if (_framesRoot == null)
			return;
		SyncMazeDirectionsFromSpatial();
		var keys = GatherKeysFromFrames();
		if (GetLayoutMode() == "CORRIDOR_Z")
		{
			RebuildCorridorZLayout(keys);
			_mazeExpandedFramePositions = null;
		}
		else
			RebuildMazeExpandedFramePositions(keys);

		var fc = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
		var walls = _framesRoot.GetNodeOrNull<Node3D>("WallsContainer");
		var floors = _framesRoot.GetNodeOrNull<Node3D>("FloorsContainer");
		var ceilings = _framesRoot.GetNodeOrNull<Node3D>("CeilingsContainer");
		if (fc == null || walls == null)
			return;
		for (var i = 0; i < FrameSlotCount && i < fc.GetChildCount(); i++)
		{
			if (fc.GetChild(i) is Node3D n)
			{
				n.Position = GetLayoutMode() == "MAZE" && _mazeExpandedFramePositions != null
					? _mazeExpandedFramePositions[i]
					: GetPositionFromSeq(i);
				n.RotationDegrees = new Vector3(0f, GetFrameYawDegrees(i), 0f);
			}
		}

		ClearContainerChildren(walls);
		ClearContainerChildren(floors);
		ClearContainerChildren(ceilings);
		if (GetLayoutMode() == "CORRIDOR_Z")
			BuildAllCorridorSegments(keys, walls, floors, ceilings);
		else
			BuildAllMazeSegments(keys, walls, floors, ceilings);
	}

	// [SCOPE:LAYOUT_CORE]
	// seq → posición (CORRIDOR_Z: solo Z acumulativo; MAZE/LINE reservado)
	private Vector3 GetPositionFromSeq(int seq)
	{
		if (GetLayoutMode() == "CORRIDOR_Z")
		{
			if (!_corridorLayoutBuilt)
				RebuildCorridorZLayout(EmptyKeysCorridor());
			var s = Mathf.Clamp(seq, 0, FrameSlotCount - 1);
			return new Vector3(MarcoStartX, MarcoStartY, _frameZPositions[s]);
		}

		float step = 6f;
		float y = 1.6f;
		if (GetLayoutMode() == "LINE")
			return new Vector3(0, y, seq * step);
		if (GetLayoutMode() == "MAZE")
		{
			Vector3 pos = Vector3.Zero;
			for (var i = 0; i < seq; i++)
			{
				var t = i < FrameSlotCount ? _spatialTurnBySeq[i] : "";
				if (t == "left" || t == "right")
				{
					var incoming = i > 0
						? GetPersistentDirection(i - 1)
						: new Vector3(0f, 0f, 1f);
					pos += incoming * MazeFrameTurnBufferMeters;
					pos += GetPersistentDirection(i) * MazeOutgoingAfterTurnMeters;
				}
				else
					pos += GetPersistentDirection(i) * MazeStraightEdgeMeters;
			}

			return new Vector3(MarcoStartX + pos.X, MarcoStartY, MarcoStartZ + pos.Z);
		}

		return new Vector3(0, y, seq * step);
	}

	/// <summary>
	/// El marco está en el extremo “entrante” del tramo; sin esto la cámara queda en la misma Z/X que el locus y se siente pegada al muro.
	/// CORRIDOR_Z: −Z hacia el interior del tramo. MAZE: hacia el marco anterior a lo largo del suelo.
	/// </summary>
	private Vector3 ApplyCameraStandoffFromFrame(Vector3 framePos, int seq)
	{
		var mode = GetLayoutMode();
		if (mode == "CORRIDOR_Z")
		{
			return new Vector3(framePos.X, framePos.Y, framePos.Z - CameraStandoffFromFrameMeters);
		}

		if (mode == "MAZE" && _mazeExpandedFramePositions != null && _mazeExpandedFramePositions.Length > seq)
		{
			if (seq > 0)
			{
				var prev = _mazeExpandedFramePositions[seq - 1];
				var towardPrev = new Vector3(prev.X - framePos.X, 0f, prev.Z - framePos.Z);
				if (towardPrev.LengthSquared() > 1e-6f)
					return framePos + towardPrev.Normalized() * CameraStandoffFromFrameMeters;
			}
			else
			{
				var back = GetPersistentDirection(0);
				var hz = new Vector3(-back.X, 0f, -back.Z);
				if (hz.LengthSquared() > 1e-6f)
					return framePos + hz.Normalized() * CameraStandoffFromFrameMeters;
			}
		}

		return framePos;
	}

	/// <summary>
	/// Marco cuyo locus (planta) está más cerca de la cámara — mantiene <c>current_seq.txt</c> al moverse por el parcour.
	/// </summary>
	public int ResolveNearestFrameSeqFromCameraPosition(Vector3 camGlobalPos)
	{
		if (GetLayoutMode() == "MAZE")
		{
			if (_mazeExpandedFramePositions != null && _mazeExpandedFramePositions.Length >= FrameSlotCount)
			{
				var flatC = new Vector2(camGlobalPos.X, camGlobalPos.Z);
				var best = 0;
				var bestD2 = float.MaxValue;
				for (var s = 0; s < FrameSlotCount; s++)
				{
					var p = _mazeExpandedFramePositions[s];
					var d2 = flatC.DistanceSquaredTo(new Vector2(p.X, p.Z));
					if (d2 < bestD2)
					{
						bestD2 = d2;
						best = s;
					}
				}
				return best;
			}

			var bestM = 0;
			var bestD2m = float.MaxValue;
			var flatCm = new Vector2(camGlobalPos.X, camGlobalPos.Z);
			for (var s = 0; s < FrameSlotCount; s++)
			{
				var p = GetPositionFromSeq(s);
				var d2 = flatCm.DistanceSquaredTo(new Vector2(p.X, p.Z));
				if (d2 < bestD2m)
				{
					bestD2m = d2;
					bestM = s;
				}
			}
			return bestM;
		}

		if (GetLayoutMode() == "CORRIDOR_Z")
		{
			if (!_corridorLayoutBuilt)
				RebuildCorridorZLayout(EmptyKeysCorridor());
			var zMarcoEst = camGlobalPos.Z + CameraStandoffFromFrameMeters;
			var best = 0;
			var bestAbs = float.MaxValue;
			for (var s = 0; s < FrameSlotCount; s++)
			{
				var d = Mathf.Abs(_frameZPositions[s] - zMarcoEst);
				if (d < bestAbs)
				{
					bestAbs = d;
					best = s;
				}
			}
			return best;
		}

		return Mathf.Clamp((int)Mathf.Round(camGlobalPos.Z / 6f), 0, FrameSlotCount - 1);
	}


	// [SCOPE:MAZE_CONTROL]
	public void SetDirection(int seq, Vector3 dir)
	{
		if (seq < 0 || seq >= FrameSlotCount) return;

		// normalizar a direcciones válidas (cardinales)
		if (dir == new Vector3(0, 0, 1) ||
			dir == new Vector3(1, 0, 0) ||
			dir == new Vector3(-1, 0, 0) ||
			dir == new Vector3(0, 0, -1))
		{
			_mazeDirections[seq] = dir;
		}
	}

	// [SCOPE:MAZE_CLEAR]
	public void ClearDirection(int seq)
	{
		if (_mazeDirections.ContainsKey(seq))
		{
			_mazeDirections.Remove(seq);
		}
	}

	// [SCOPE:PATH_DIRECTION][WRAPPER]
	private Vector3 GetDirectionFromSeq(int seq)
	{
		return GetPersistentDirection(seq);
	}




	// [SCOPE:MAZE_PERSISTENT_DIRECTION]
	private Vector3 GetPersistentDirection(int seq)
	{
		Vector3 currentDir = new Vector3(0, 0, 1);

		for (int i = 0; i <= seq; i++)
		{

			if (_mazeDirections.ContainsKey(i))
			{
				Vector3 cmd = _mazeDirections[i];

				// LEFT (giro relativo)
				if (cmd == new Vector3(-1, 0, 0))
					currentDir = new Vector3(-currentDir.Z, 0, currentDir.X);

				// RIGHT (giro relativo)
				else if (cmd == new Vector3(1, 0, 0))
					currentDir = new Vector3(currentDir.Z, 0, -currentDir.X);

				// BACK (180°)
				else if (cmd == new Vector3(0, 0, -1))
					currentDir = -currentDir;

				// FORWARD (sin cambio): no-op
			}

		}

		return currentDir;
	}

	// [SCOPE:SEGMENT_FRAME_FROM_SEQ]
	// [SCOPE:SEGMENT_FRAME_FROM_SEQ]
	private SegmentFrame GetSegmentFrameFromSeq(int seq)
	{
		var s = Mathf.Clamp(seq, 0, FrameSlotCount - 1);
		Vector3 pos = GetLayoutMode() == "MAZE" && _mazeExpandedFramePositions != null
			? _mazeExpandedFramePositions[s]
			: GetPositionFromSeq(s);
		Vector3 dir = GetPersistentDirection(seq);
		Vector3 right = new Vector3(-dir.Z, 0, dir.X);

		return new SegmentFrame
		{
			Position = pos,
			Forward = dir,
			Right = right,
			Up = Vector3.Up
		};
	}

	// [SCOPE:SIDE_FLIP]  <-- AGREGAR AQUÍ
	private int _currentSide = -1;

	private Vector3 GetCurrentSide(int seq)
	{
		Vector3 dir = GetPersistentDirection(seq);
		Vector3 right = new Vector3(-dir.Z, 0, dir.X);
		
		if (seq == 0)
		{
			_currentSide = -1;
			return right * _currentSide;
		}
		
		Vector3 dirPrev = GetPersistentDirection(seq - 1);
		
		if (dirPrev != dir)
		{
			_currentSide *= -1;
			GD.Print($"[SIDE_FLIP] seq={seq} dirPrev={dirPrev} dirNow={dir} newSide={_currentSide}");
		}
		
		return right * _currentSide;
	}



		private void InitMaze()
		{
			_mazeDirections.Clear();
			for (var i = 0; i < FrameSlotCount; i++)
				_spatialTurnBySeq[i] = "";
		}

		/// <summary>Copia <see cref="_spatialTurnBySeq"/> a <see cref="_mazeDirections"/> (giros relativos en <see cref="GetPersistentDirection"/>).</summary>
		private void SyncMazeDirectionsFromSpatial()
		{
			_mazeDirections.Clear();
			for (var i = 0; i < FrameSlotCount; i++)
			{
				// LB left/right ↔ vectores comando (intercambiados respecto al primer intento para izq/der correctos en pantalla).
				if (_spatialTurnBySeq[i] == "left")
					_mazeDirections[i] = new Vector3(1f, 0f, 0f);
				else if (_spatialTurnBySeq[i] == "right")
					_mazeDirections[i] = new Vector3(-1f, 0f, 0f);
			}
		}

		/// <summary>Corredor Z: -90° panel. MAZE: alinea el marco con la dirección de avance hacia este nodo (tramo anterior).</summary>
		private float GetFrameYawDegrees(int seq)
		{
			if (GetLayoutMode() != "MAZE")
				return -90f;
			var forward = seq == 0
				? new Vector3(0f, 0f, 1f)
				: GetPersistentDirection(seq - 1);
			return Mathf.RadToDeg(Mathf.Atan2(forward.X, forward.Z)) - 90f;
		}


	public override void _Ready()
		{
		GD.Print("[SPAWNER][DEBUG] CHILDREN OF ROOT:");

		foreach (Node child in GetTree().Root.GetChildren())
		{
			GD.Print("[ROOT CHILD] " + child.Name);
		}

		foreach (Node child in GetParent().GetChildren())
		{
			GD.Print("[REALM CHILD] " + child.Name);
		}

		_framesRoot = GetNodeOrNull<Node3D>(FramesRootPath);

		if (_framesRoot == null)
		{
			GD.PrintErr("[SPAWNER][ERR] FramesRoot NOT FOUND PATH=" + FramesRootPath);
			return;
		}

		GD.Print("[SPAWNER][FRAMES_ROOT OK]");


		_rc = GetNode<RealmController>("/root/Realm/RealmController");

		GD.Print("[SPAWNER][INIT]");

		// [MAZE] (corredor Z: sin giros)
		InitMaze();

		var initKeys = EmptyKeysCorridor();
		TryReadSnapshotKeysFromDisk(initKeys);
		RebuildCorridorZLayout(initKeys);

		var template = _framesRoot.GetNode<Node3D>("FrameTemplate");
		template.Visible = false;

		var framesContainer = GetOrCreateContainer(_framesRoot, "FramesContainer");
		_ = GetOrCreateContainer(_framesRoot, "WallsContainer");
		_ = GetOrCreateContainer(_framesRoot, "FloorsContainer");
		_ = GetOrCreateContainer(_framesRoot, "CeilingsContainer");

		for (var seq = 0; seq < FrameSlotCount; seq++)
		{
			var basePos = GetPositionFromSeq(seq);
			var frame = (Node3D)template.Duplicate();
			framesContainer.AddChild(frame);
			frame.Name = $"Frame_{seq}";
			frame.Position = basePos;
			frame.RotationDegrees = new Vector3(0f, -90f, 0f);
			frame.Visible = true;

			if (frame is FrameTemplate f)
			{
				var k = seq < initKeys.Length ? initKeys[seq] : "";
				f.SetKey(k);
				f.SetSeq(seq);
				f.FrameSelected += _rc.OnFrameSelected;
			}

			GD.Print($"[SPAWNER][CORRIDOR_Z] seq={seq} pos={basePos}");
		}

		if (!_snapshotLoaded)
			LoadSnapshotAndAssign();

		ApplyCorridorGeometryAfterSnapshot();
		TryRestoreCameraAfterSnapshot();
		PrimeWallManifestSignatures();
		PrimeFrameDisplaySignatures();
		_snapshotLoaded = true;

		SetProcess(true);

		// [SCOPE:REFRESH_WATCHER]
		GD.Print("[SPAWNER][PROCESS_ENABLED]");
		GD.Print("[SPAWNER][VERSION] A15 Cambio034 refresh polling + 1Hz tick");
		GD.Print("[SPAWNER][REFRESH_PATH] " + Path.Combine(AlexandriaDataRoot.RealmDataRoot, "bridge", "refresh_now.txt"));
	}
	

	/// <summary>
	/// [A14→A15] Lee snapshot únicamente; asigna KEY por índice de slot (seq). Sin DB.
	/// Frames viven en FramesContainer; seq es índice directo (0..N-1).
	/// Devuelve <c>false</c> si el JSON no corresponde al bridge (p. ej. <c>current.json</c> aún del hijo).
	/// </summary>
	private bool LoadSnapshotAndAssign()
	{
		var bridgeCtx = BridgeSpatial.ReadContextKey()?.Trim() ?? "";
		if (!ResolveSnapshotPath(bridgeCtx, out var path, out var usedFb))
		{
			GD.PrintErr($"[SNAPSHOT][MISS] context={bridgeCtx}");
			return false;
		}

		if (_framesRoot == null)
			return false;

		var framesContainer = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
		if (framesContainer == null)
		{
			GD.PrintErr("[SNAPSHOT] FramesContainer not found");
			return false;
		}

		string jsonText;
		try
		{
			jsonText = System.IO.File.ReadAllText(path);
		}
		catch (Exception e)
		{
			GD.PrintErr("[SNAPSHOT][READ_FAIL] " + e.Message);
			return false;
		}

		var jsonNode = new Json();
		if (jsonNode.Parse(jsonText) != Error.Ok)
		{
			GD.PrintErr("[SNAPSHOT][PARSE_FAIL]");
			return false;
		}

		var data = jsonNode.Data.AsGodotDictionary();
		if (!data.ContainsKey("frames"))
		{
			GD.PrintErr("[SNAPSHOT][NO_FRAMES]");
			return false;
		}

		if (!SnapshotDataMatchesBridge(data, bridgeCtx, path, usedFb))
		{
			GD.PrintErr($"[SNAPSHOT][SKIP] snapshot no coincide con bridge (context={bridgeCtx} file={path} fallback={usedFb})");
			return false;
		}

		if (usedFb)
			GD.Print($"[SNAPSHOT][FALLBACK] usando current.json validado contextKey={bridgeCtx}");

		var frames = data["frames"].AsGodotArray();

		for (var i = 0; i < FrameSlotCount; i++)
			_spatialTurnBySeq[i] = "";

		foreach (Variant f in frames)
		{
			var d = f.AsGodotDictionary();
			int seq = d["seq"].AsInt32();
			string key = d["key"].AsString();

			if (seq >= 0 && seq < FrameSlotCount && d.ContainsKey("spatialTurn"))
			{
				var st = d["spatialTurn"].AsString().Trim().ToLowerInvariant();
				if (st == "left" || st == "right")
					_spatialTurnBySeq[seq] = st;
			}

			if (seq < 0 || seq >= framesContainer.GetChildCount())
			{
				GD.PrintErr($"[SNAPSHOT] seq={seq} out of range (children={framesContainer.GetChildCount()})");
				continue;
			}

			var frame = framesContainer.GetChild(seq) as FrameTemplate;
			if (frame != null)
			{
				frame.SetKey(key);
				frame.SetSeq(seq);
				GD.Print($"[SNAPSHOT][ASSIGN] frame={seq} key={key}");
			}
			else
			{
				GD.PrintErr($"[SNAPSHOT][SKIP] seq={seq} not a FrameTemplate");
			}
		}

		return true;
	}

	/// <summary>
	/// Object (hoja *_O##): siempre marco 0.
	/// Parcour: último marco en <see cref="SessionRealmSpatial"/> para el realm activo (memoria de sesión GK, no disco).
	/// </summary>
	private void TryRestoreCameraAfterSnapshot()
	{
		var cam = GetNodeOrNull<CameraRig>("/root/Realm/CameraRig");
		if (cam == null)
		{
			GD.PrintErr("[SPAWNER][CAMERA_NULL] no CameraRig");
			return;
		}

		var contextKey = BridgeSpatial.ReadContextKey();
		if (string.IsNullOrEmpty(contextKey))
			return;

		int seq;
		if (BridgeSpatial.IsObjectLocusKey(contextKey))
		{
			seq = 0;
		}
		else
		{
			var realmId = AlexandriaDataRoot.ReadActiveRealmId();
			seq = SessionRealmSpatial.GetParcourSeqForRealmOrDefault(realmId, 0);
		}
		if (seq < 0)
			seq = 0;
		if (seq >= FrameSlotCount)
			seq = FrameSlotCount - 1;

		PositionCameraAtParcourSeq(cam, seq);

		var layout = GetLayoutMode();
		GD.Print($"[SPAWNER][CAMERA_RESTORE] context_key={contextKey} seq={seq} pos={cam.GlobalPosition} layout={layout}");
	}

	/// <summary>Coloca la cámara frente al marco <paramref name="seq"/> (0..<see cref="FrameSlotCount"/>-1), coherente con restore tras snapshot.</summary>
	private void PositionCameraAtParcourSeq(CameraRig cam, int seq)
	{
		if (seq < 0)
			seq = 0;
		if (seq >= FrameSlotCount)
			seq = FrameSlotCount - 1;

		Vector3 pos = GetLayoutMode() == "MAZE" && _mazeExpandedFramePositions != null
			? _mazeExpandedFramePositions[seq]
			: GetPositionFromSeq(seq);
		pos = ApplyCameraStandoffFromFrame(pos, seq);
		if (GetLayoutMode() == "MAZE" && _mazeExpandedFramePositions != null)
		{
			var walk = seq == 0
				? new Vector3(0f, 0f, 1f)
				: GetPersistentDirection(Mathf.Max(0, seq - 1));
			var flat = new Vector3(walk.X, 0f, walk.Z);
			if (flat.LengthSquared() > 1e-6f)
			{
				flat = flat.Normalized();
				var right = Vector3.Up.Cross(flat).Normalized();
				pos += -right * CameraMazeLateralAwayFromWallMeters;
			}
		}

		var camX = GetLayoutMode() == "CORRIDOR_Z"
			? CorridorCameraRigX + CorridorCameraLateralAwayFromWallX
			: pos.X;
		cam.GlobalPosition = new Vector3(camX, 0f, pos.Z);

		var layout = GetLayoutMode();
		if (layout == "MAZE" && _mazeExpandedFramePositions != null)
		{
			var walk = seq == 0
				? new Vector3(0f, 0f, 1f)
				: GetPersistentDirection(Mathf.Max(0, seq - 1)).Normalized();
			if (walk.LengthSquared() > 1e-6f)
			{
				var yDeg = Mathf.RadToDeg(Mathf.Atan2(walk.X, walk.Z));
				cam.RotationDegrees = new Vector3(0f, yDeg, 0f);
			}
		}
		else if (layout == "CORRIDOR_Z")
			cam.RotationDegrees = new Vector3(0f, 0f, 0f);
	}

	/// <summary>Locus asignado al marco (vacío = slot libre).</summary>
	public string GetLocusKeyAtFrameSeq(int seq)
	{
		if (_framesRoot == null)
			return "";
		var fc = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
		if (fc == null)
			return "";
		var s = Mathf.Clamp(seq, 0, FrameSlotCount - 1);
		if (s >= fc.GetChildCount())
			return "";
		var ft = fc.GetChild(s) as FrameTemplate;
		return ft?.GetLocusKey() ?? "";
	}

	/// <summary>Desatasco: salta al marco del parcour; actualiza sesión, <c>current_seq.txt</c> y <c>focus_key</c> si hay locus.</summary>
	public void MoveCameraToParcourSeq(int seq)
	{
		seq = Mathf.Clamp(seq, 0, FrameSlotCount - 1);
		var cam = GetNodeOrNull<CameraRig>("/root/Realm/CameraRig");
		if (cam == null)
		{
			GD.PrintErr("[SPAWNER][MOVE_SEQ] no CameraRig");
			return;
		}

		PositionCameraAtParcourSeq(cam, seq);
		var realmId = AlexandriaDataRoot.ReadActiveRealmId();
		SessionRealmSpatial.SetParcourSeqForRealm(realmId, seq);
		BridgeSpatial.WriteCurrentSeq(seq);
		var key = GetLocusKeyAtFrameSeq(seq);
		if (!string.IsNullOrEmpty(key))
			BridgeSpatial.WriteFocusKey(key);
		GD.Print($"[SPAWNER][MOVE_SEQ] seq={seq} focus={(string.IsNullOrEmpty(key) ? "(empty)" : key)}");
	}



	public override void _Process(double delta)
	{
		var refreshPath = Path.Combine(AlexandriaDataRoot.RealmDataRoot, "bridge", "refresh_now.txt");

		_snapshotRefreshCheckTimer += delta;
		if (_snapshotRefreshCheckTimer >= 1.0)
			_snapshotRefreshCheckTimer = 0;

		_snapshotReloadBackoffSec -= delta;

		if (System.IO.File.Exists(refreshPath))
		{
			if (_snapshotReloadBackoffSec <= 0)
			{
				GD.Print("[SNAPSHOT][REFRESH_DETECTED]");

				if (LoadSnapshotAndAssign())
				{
					try
					{
						System.IO.File.Delete(refreshPath);
					}
					catch (Exception e)
					{
						GD.PrintErr("[SNAPSHOT][REFRESH_DEL] " + e.Message);
					}

					_snapshotLoaded = false;
					ApplyCorridorGeometryAfterSnapshot();
					RefreshAllFrameHeroMaterials();
					TryRestoreCameraAfterSnapshot();
					PrimeWallManifestSignatures();
					PrimeFrameDisplaySignatures();
					_snapshotLoaded = true;
					_snapshotReloadBackoffSec = 0;
				}
				else
				{
					_snapshotReloadBackoffSec = 0.2;
					GD.PrintErr("[SNAPSHOT][RETRY] snapshot aún no alineado con bridge — esperando LibraryBuild (refresh permanece)");
				}
			}
		}
		else if (_snapshotLoaded)
		{
			var wallCh = DidWallManifestChange();
			var frameCh = DidFrameDisplayChange();
			if (wallCh || frameCh)
			{
				GD.Print("[SPAWNER][VISUAL_ASSET_CHANGED] rebuild corridor geometry + frame textures");
				ApplyCorridorGeometryAfterSnapshot();
				RefreshAllFrameHeroMaterials();
				TryRestoreCameraAfterSnapshot();
				PrimeWallManifestSignatures();
				PrimeFrameDisplaySignatures();
			}
		}

		// [SCOPE:MAZE_TEST_INPUT]

		// usar número como seq actual (ejemplo fijo temporal)
		int testSeq = 5;

		// teclas para probar direcciones
		if (Input.IsKeyPressed(Key.Left))
		{
			SetDirection(testSeq, new Vector3(-1, 0, 0));
		}

		if (Input.IsKeyPressed(Key.Right))
		{
			SetDirection(testSeq, new Vector3(1, 0, 0));
		}

		if (Input.IsKeyPressed(Key.Up))
		{
			SetDirection(testSeq, new Vector3(0, 0, 1));
		}

		if (Input.IsKeyPressed(Key.Down))
		{
			SetDirection(testSeq, new Vector3(0, 0, -1));
		}

		// limpiar
		if (Input.IsKeyPressed(Key.C))
		{
			ClearDirection(testSeq);
		}

	}

	public void SpawnFrame(string key, int seq, Vector3 position)

	{

	// [TRACE][SPAWNER][TEMPLATE_FETCH] intentando obtener FrameTemplate

	var template = _framesRoot.GetNode<Node3D>("FrameTemplate");

	if (template == null)
	{
		GD.PrintErr("[SPAWNER][ERR] FrameTemplate NOT FOUND IN SCENE");
		GD.PrintErr("[SPAWNER][STATE] SYSTEM NOT RENDERING");
		return;
	}

	// [TRACE][SPAWNER][TEMPLATE_OK] template encontrado correctamente
	GD.Print("[SPAWNER][TEMPLATE_OK]");

	// ocultar template base (no debe renderizarse)
	template.Visible = false;

	var frame = (Node3D)template.Duplicate();
	var framesHolder = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
	(framesHolder ?? _framesRoot).AddChild(frame);

	frame.Position = position;
	frame.RotationDegrees = new Vector3(0, -90, 0);
	frame.Visible = true;

	// opcional si usas script propio:
	var f = frame as FrameTemplate;
	if (f != null)
	{
		f.SetKey(key);
		f.FrameSelected += _rc.OnFrameSelected;
	}


	GD.Print($"[SPAWNER][MAP] key={key} seq={seq}");
	GD.Print($"[SPAWNER][SPAWN] key={key} pos={position}");


	}
}
