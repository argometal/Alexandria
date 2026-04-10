using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

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

	/// <summary>Tras rechazar snapshot (bridge ≠ JSON): backoff antes de reintentar con refresh_now.</summary>
	private double _snapshotReloadBackoffSec;

	private static string RealmSnapshotDir => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "snapshot");
	private static string SnapshotCurrentJsonPath => Path.Combine(RealmSnapshotDir, "current.json");

	/// <summary>Hoja de objeto bajo parcour (p. ej. L1_O01). Siempre cámara en el primer marco.</summary>
	private static readonly Regex ObjectLocusKeySuffix = new Regex(@"_O\d{2}$", RegexOptions.Compiled);

	private static bool IsObjectLocusKey(string key) =>
		!string.IsNullOrEmpty(key) && ObjectLocusKeySuffix.IsMatch(key);

	// --- Corredor recto Z: QuadMesh Size=(PanelHeight,PanelWidth); con rot -90°Y la extensión en +Z es PanelHeight. ---
	private const int FrameSlotCount = 20;
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
	private const float WallWidthConst = 3.2f;
	private const float FloorCeilingExtraLengthMeters = 3.5f;
	/// <summary>Plano de pared en X (coincide con ancho de panel en eje X tras rotación -90°).</summary>
	private const float WallPlaneX = 3.2f;
	private const float MarcoStartX = 2.8f;
	private const float MarcoStartY = 1.6f;
	private const float MarcoStartZ = 10.0f;

	private readonly float[] _frameZPositions = new float[FrameSlotCount];
	private bool _corridorLayoutBuilt;

	// [SCOPE:MAZE_OVERRIDE]
	private Dictionary<int, Vector3> _mazeDirections = new Dictionary<int, Vector3>();

	// [SCOPE:SEGMENT_FRAME_BASE]
	private struct SegmentFrame
	{
		public Vector3 Position;
		public Vector3 Forward;
		public Vector3 Right;
		public Vector3 Up;
	}

	// [SCOPE:LAYOUT_MODE]
	private string GetLayoutMode()
	{
		return "CORRIDOR_Z";
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

	private void ApplyCorridorGeometryAfterSnapshot()
	{
		if (_framesRoot == null)
			return;
		var keys = GatherKeysFromFrames();
		RebuildCorridorZLayout(keys);
		var fc = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
		var walls = _framesRoot.GetNodeOrNull<Node3D>("WallsContainer");
		var floors = _framesRoot.GetNodeOrNull<Node3D>("FloorsContainer");
		var ceilings = _framesRoot.GetNodeOrNull<Node3D>("CeilingsContainer");
		if (fc == null || walls == null)
			return;
		for (var i = 0; i < FrameSlotCount && i < fc.GetChildCount(); i++)
		{
			if (fc.GetChild(i) is Node3D n)
				n.Position = new Vector3(MarcoStartX, MarcoStartY, _frameZPositions[i]);
		}

		ClearContainerChildren(walls);
		ClearContainerChildren(floors);
		ClearContainerChildren(ceilings);
		BuildAllCorridorSegments(keys, walls, floors, ceilings);
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
			for (int i = 0; i < seq; i++)
				pos += GetPersistentDirection(i) * step;
			return new Vector3(pos.X, y, pos.Z);
		}

		return new Vector3(0, y, seq * step);
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

				// FORWARD (sin cambio)
				else if (cmd == new Vector3(0, 0, 1))
					currentDir = currentDir;
			}

		}

		return currentDir;
	}

	// [SCOPE:SEGMENT_FRAME_FROM_SEQ]
	// [SCOPE:SEGMENT_FRAME_FROM_SEQ]
	private SegmentFrame GetSegmentFrameFromSeq(int seq)
	{
		Vector3 pos = GetPositionFromSeq(seq);
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
			// No hay giros - corredor completamente recto
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

		foreach (Variant f in frames)
		{
			var d = f.AsGodotDictionary();
			int seq = d["seq"].AsInt32();
			string key = d["key"].AsString();

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
	/// Parcour / realm (clave que no es hoja *_O##): primera vez en el nivel → marco 0;
	/// al volver tras salir → seq guardado en last_position.byKey[context_key] (escribe LB al cambiar contexto).
	/// Object (hoja *_O##): siempre primer marco (seq 0). No usar current_seq.txt como sustituto.
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
		if (IsObjectLocusKey(contextKey))
		{
			seq = 0;
		}
		else
		{
			var saved = BridgeSpatial.ReadSavedSeqForOpenKey(contextKey);
			seq = saved ?? 0;
		}
		if (seq < 0)
			seq = 0;
		if (seq >= FrameSlotCount)
			seq = FrameSlotCount - 1;

		Vector3 pos = GetPositionFromSeq(seq);
		// Rig en Y=0: la altura de ojos viene del Camera3D hijo en la escena (no duplicar con pos.Y).
		var camX = GetLayoutMode() == "CORRIDOR_Z" ? CorridorCameraRigX : pos.X;
		cam.GlobalPosition = new Vector3(camX, 0f, pos.Z);
		GD.Print($"[SPAWNER][CAMERA_RESTORE] context_key={contextKey} seq={seq} pos={cam.GlobalPosition}");
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
					TryRestoreCameraAfterSnapshot();
					PrimeWallManifestSignatures();
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
		else if (_snapshotLoaded && DidWallManifestChange())
		{
			GD.Print("[SPAWNER][WALL_MANIFEST_CHANGED] rebuild corridor geometry");
			ApplyCorridorGeometryAfterSnapshot();
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
