using Godot;
using System;
using System.Collections.Generic;

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
		return "MAZE"; // activar giros
	}



	// [SCOPE:LAYOUT_CORE]
	// seq → posición acumulativa (path)
	private Vector3 GetPositionFromSeq(int seq)
	{
		float step = 6f;
		float y = 1.6f;

		var mode = GetLayoutMode();

		if (mode == "LINE")
		{
			return new Vector3(0, y, seq * step);
		}

		if (mode == "MAZE")
		{
			Vector3 pos = Vector3.Zero;

			for (int i = 0; i < seq; i++)
			{
				Vector3 dir;

			dir = GetPersistentDirection(i);

				pos += dir * step;
			}

			return new Vector3(pos.X, y, pos.Z);
		}

		return new Vector3(0, y, seq * step);
	}


	// [SCOPE:MAZE_CONTROL]
	public void SetDirection(int seq, Vector3 dir)
	{
		if (seq < 0 || seq >= 20) return;

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

		// [MAZE]
		InitMaze();

		// [A15][INIT_FIXED_LOCI]
	
		int N = 20;
		float spacing = 6f;
		float startY = 1.6f;

		var template = _framesRoot.GetNode<Node3D>("FrameTemplate");
		template.Visible = false;

		var framesContainer = GetOrCreateContainer(_framesRoot, "FramesContainer");
		var wallsContainer = GetOrCreateContainer(_framesRoot, "WallsContainer");
		var floorsContainer = GetOrCreateContainer(_framesRoot, "FloorsContainer");
		var ceilingsContainer = GetOrCreateContainer(_framesRoot, "CeilingsContainer");

		for (int seq = 0; seq < N; seq++)
		{
			Vector3 basePos = GetPositionFromSeq(seq);

			// WALL

			var sf = GetSegmentFrameFromSeq(seq);

			GD.Print($"[SIDE_DEBUG_BEFORE] seq={seq} _currentSide={_currentSide}");
			Vector3 debugSide = GetCurrentSide(seq);
			GD.Print($"[SIDE_DEBUG_AFTER] seq={seq} debugSide={debugSide} _currentSide={_currentSide}");

			var wall = WallScene.Instantiate<Node3D>();
			wallsContainer.AddChild(wall);

			// detectar esquina (cuando cambia dirección respecto al anterior)
			Vector3 dirNow = GetDirectionFromSeq(seq);
			Vector3 dirPrev = seq > 0 ? GetDirectionFromSeq(seq - 1) : dirNow;

			bool isCorner = dirNow != dirPrev;

	
			float cornerOffset = 0f;

			Vector3 side = GetCurrentSide(seq);
			GD.Print($"[SIDE_DEBUG] seq={seq} side={side} currentSide={_currentSide}");
			wall.Position = sf.Position + side * 3.5f;

			// OFFSET EN GIROS - desplazar wall en nueva dirección
			if (seq > 0 && GetPersistentDirection(seq) != GetPersistentDirection(seq - 1))
			{
				wall.Position += GetPersistentDirection(seq) * 3f;
			}

			float angleWall = 0f;
			if (sf.Forward == new Vector3(0, 0, 1)) angleWall = -90f;
			if (sf.Forward == new Vector3(1, 0, 0)) angleWall = 0f;
			if (sf.Forward == new Vector3(-1, 0, 0)) angleWall = 180f;
			if (sf.Forward == new Vector3(0, 0, -1)) angleWall = 90f;

			// Detectar giro izquierda (cross > 0)
			bool isLeftTurn = false;
			if (seq > 0)
			{
				Vector3 prevDir = GetPersistentDirection(seq - 1);
				Vector3 nowDir = GetPersistentDirection(seq);
				float cross = prevDir.X * nowDir.Z - prevDir.Z * nowDir.X;
				isLeftTurn = cross > 0;
			}

			float wallRotation = angleWall + 90f;
			if (isLeftTurn)
			{
				wallRotation += 180f;
			}
			wall.RotationDegrees = new Vector3(0, wallRotation, 0);

			// FLOOR
			SpawnPiece(FloorScene, new Vector3(basePos.X, 0f, basePos.Z), floorsContainer);

			// CEILING
			SpawnPiece(CeilingScene, new Vector3(basePos.X, 3.2f, basePos.Z), ceilingsContainer);

			// FRAME
			var frame = (Node3D)template.Duplicate();
			framesContainer.AddChild(frame);
			frame.Name = $"Frame_{seq}";

			float frameOffsetX = side.X * 2.8f;
			frame.Position = basePos + new Vector3(frameOffsetX, 0f, 2.5f);

			// OFFSET EN GIROS - desplazar frame en nueva dirección
			if (seq > 0 && GetPersistentDirection(seq) != GetPersistentDirection(seq - 1))
			{
				frame.Position += GetPersistentDirection(seq) * 3f;
			}

			Vector3 dir = GetPersistentDirection(seq);

			float angle = 0f;
			if (dir == new Vector3(0, 0, 1)) angle = -90f;
			if (dir == new Vector3(1, 0, 0)) angle = 0f;
			if (dir == new Vector3(-1, 0, 0)) angle = 180f;
			if (dir == new Vector3(0, 0, -1)) angle = 90f;

			float frameRotation = angle;
			if (isLeftTurn)
			{
				frameRotation += 180f;
			}
			frame.RotationDegrees = new Vector3(0, frameRotation, 0);
			frame.Visible = true;


			var f = frame as FrameTemplate;
			if (f != null)
			{
				f.SetKey("");
				f.FrameSelected += _rc.OnFrameSelected;
			}


			GD.Print($"[SF] seq={seq} pos={sf.Position} fwd={sf.Forward} right={sf.Right}");

/* 
			// [SCOPE:CORNER_PIECE]
			Vector3 dirNowCorner = GetDirectionFromSeq(seq);
			Vector3 dirPrevCorner = seq > 0 ? GetDirectionFromSeq(seq - 1) : dirNowCorner;

			bool isCornerCorner = seq > 0 && dirNowCorner != dirPrevCorner;

		if (isCornerCorner)
		{
			var tempCorner = new MeshInstance3D();
			tempCorner.Mesh = new BoxMesh();

			// tamaño aproximado de wall (ajústalo si tu mesh real difiere)
			tempCorner.Scale = new Vector3(0.5f, 3.2f, 5.0f);

			var mat = new StandardMaterial3D();
			mat.AlbedoColor = Colors.Gray;
			tempCorner.MaterialOverride = mat;

			_framesRoot.AddChild(tempCorner);

			Vector3 prevPos = GetPositionFromSeq(seq - 1);
			Vector3 dirPrevCornerPos = GetDirectionFromSeq(seq - 1);
			Vector3 rightPrev = new Vector3(-dirPrevCornerPos.Z, 0, dirPrevCornerPos.X);

			float step = 6f;

			// posición base (centro de la esquina)
						
			Vector3 currPos = GetPositionFromSeq(seq);

			// Cubo Separacion y alineacion de wall, a justar el F 
			Vector3 cornerBase = currPos + dirPrevCornerPos * (step * 0.625f);



			// corner -plicar mismo offset lateral que walls (3.5 original )
			tempCorner.Position = cornerBase - rightPrev * 6.0f;

			// rotación consistente con wall
			float angleCorner = 0f;
			if (dirPrevCornerPos == new Vector3(0, 0, 1)) angleCorner = -90f;
			if (dirPrevCornerPos == new Vector3(1, 0, 0)) angleCorner = 0f;
			if (dirPrevCornerPos == new Vector3(-1, 0, 0)) angleCorner = 180f;
			if (dirPrevCornerPos == new Vector3(0, 0, -1)) angleCorner = 90f;

			tempCorner.RotationDegrees = new Vector3(0, angleCorner + 180f, 0);




			GD.Print($"[CORNER_DEBUG] seq={seq}");
		}

 */
			GD.Print($"[SPAWNER][INIT_LOCUS] seq={seq}");


		}

		if (!_snapshotLoaded)
		{
			LoadSnapshotAndAssign();
			_snapshotLoaded = true;
		}

		SetProcess(true);

		// [SCOPE:REFRESH_WATCHER]
		GD.Print("[SPAWNER][PROCESS_ENABLED]");
		GD.Print("[SPAWNER][VERSION] A15 Cambio034 refresh polling + 1Hz tick");
		GD.Print("[SPAWNER][REFRESH_PATH] " + @"C:\Alexandria\data\bridge\refresh_now.txt");
	}
	

	/// <summary>
	/// [A14→A15] Lee snapshot únicamente; asigna KEY por índice de slot (seq). Sin DB.
	/// Frames viven en FramesContainer; seq es índice directo (0..N-1).
	/// </summary>
	private void LoadSnapshotAndAssign()
	{
		var path = @"C:\Alexandria\snapshot\current.json";

		if (!System.IO.File.Exists(path))
		{
			GD.Print("[SNAPSHOT][MISS]");
			return;
		}

		if (_framesRoot == null)
			return;

		var framesContainer = _framesRoot.GetNodeOrNull<Node3D>("FramesContainer");
		if (framesContainer == null)
		{
			GD.PrintErr("[SNAPSHOT] FramesContainer not found");
			return;
		}

		var jsonText = System.IO.File.ReadAllText(path);
		var jsonNode = new Json();
		Error parseErr = jsonNode.Parse(jsonText);
		if (parseErr != Error.Ok)
		{
			GD.PrintErr("[SNAPSHOT][PARSE_FAIL]");
			return;
		}

		var data = jsonNode.Data.AsGodotDictionary();
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
				GD.Print($"[SNAPSHOT][ASSIGN] frame={seq} key={key}");
			}
			else
			{
				GD.PrintErr($"[SNAPSHOT][SKIP] seq={seq} not a FrameTemplate");
			}
		}
	}



	public override void _Process(double delta)
	{
		var refreshPath = @"C:\Alexandria\data\bridge\refresh_now.txt";

		_snapshotRefreshCheckTimer += delta;
		if (_snapshotRefreshCheckTimer >= 1.0)
		{
			_snapshotRefreshCheckTimer = 0;
			GD.Print("[SPAWNER][PROCESS_TICK] Cambio034 1Hz — _Process ejecutándose");
			GD.Print("[SNAPSHOT][CHECK] looking for refresh...");
			GD.Print($"[SNAPSHOT][CHECK] path={refreshPath} exists={System.IO.File.Exists(refreshPath)}");
		}

		if (System.IO.File.Exists(refreshPath))
		{
			GD.Print("[SNAPSHOT][REFRESH_DETECTED]");

			System.IO.File.Delete(refreshPath);

			_snapshotLoaded = false;
			LoadSnapshotAndAssign();
			_snapshotLoaded = true;


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
