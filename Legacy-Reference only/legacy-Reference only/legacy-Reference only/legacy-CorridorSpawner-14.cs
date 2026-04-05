using Godot;
using System;

public partial class CorridorSpawner : Node3D
{
	[Export] public NodePath FramesRootPath { get; set; } = new NodePath("../Frames");
	
	[Export] public NodePath FrameTemplatePath { get; set; } = new NodePath("../Frames/Frame01");
	
	[Export] public NodePath WallTemplatePath { get; set; }
	
	
	[Export] public int TotalFrames { get; set; } = 20;
	[Export] public float StartX { get; set; } = 2.8f;
	[Export] public float StartY { get; set; } = 1.6f;
	[Export] public float StartZ { get; set; } = 10.0f;
	[Export] public float ZSpacing { get; set; } = 10.0f;

	public string CurrentParentKey { get; private set; } = "PARCOUR_MAIN";
	private readonly System.Collections.Generic.Dictionary<int, float> _frameGapBySeq = new();
	private readonly System.Collections.Generic.Dictionary<int, float> _frameZBySeq = new();
		
	public override void _Ready()
	{
		EnsureRaz12Running();
		RefreshFromDb();
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent &&
			keyEvent.Pressed &&
			!keyEvent.Echo &&
			keyEvent.Keycode == Key.F5)
		{
			RefreshFromDb();
			GD.Print("SPAWNER_MANUAL_REFRESH: " + CurrentParentKey);
		}
	}


	public void RefreshFromDb(string parentKey = null)
	{
		if (!string.IsNullOrWhiteSpace(parentKey))
			CurrentParentKey = parentKey.Trim();

		_frameGapBySeq.Clear();
		_frameZBySeq.Clear();

		for (int seq = 1; seq <= TotalFrames; seq++)
		{
			_frameGapBySeq[seq] = ComputeFrameGap(seq);
		}

		_frameZBySeq[1] = StartZ;
		for (int seq = 2; seq <= TotalFrames; seq++)
		{
			_frameZBySeq[seq] = _frameZBySeq[seq - 1] + _frameGapBySeq[seq];
		}

		var framesRoot = GetNodeOrNull<Node3D>(FramesRootPath);
		var template = GetNodeOrNull<Node3D>(FrameTemplatePath);

		var wallTemplate = GetNodeOrNull<MeshInstance3D>(WallTemplatePath ?? "../Corridor/WallPath");

		if (framesRoot == null)
		{
			GD.PrintErr("SPAWNER_ERR: Frames root not found");
			return;
		}

		if (template == null)
		{
			GD.PrintErr("SPAWNER_ERR: Frame01 template not found");
			return;
		}

		if (wallTemplate == null)
		{
			GD.PrintErr("SPAWNER_ERR: WallPath template not found");
			return;
		}

		foreach (Node child in framesRoot.GetChildren())
		{
			if (child == template)
				continue;

			child.QueueFree();
		}

		template.Name = "Frame01";
		template.Position = new Vector3(StartX, StartY, StartZ);
		template.RotationDegrees = new Vector3(0, -90, 0);

		AssignSlotKey(template, 1);

		for (int i = 2; i <= TotalFrames; i++)
		{
			var clone = (Node3D)template.Duplicate();
			clone.Name = $"Frame{i:00}";
			clone.Position = new Vector3(StartX, StartY, StartZ + GetAccumulatedSpacing(i));
			clone.RotationDegrees = new Vector3(0, -90, 0);

			AssignSlotKey(clone, i);
			framesRoot.AddChild(clone);
			clone.Owner = GetTree().EditedSceneRoot;
		}

		BuildWalls(wallTemplate);
		GD.Print($"SPAWNER_REFRESH_OK: {CurrentParentKey} / {TotalFrames} frames");
		
	}

	public void EnterLocus(string locusKey)
	{
		if (string.IsNullOrWhiteSpace(locusKey))
			return;

		RefreshFromDb(locusKey);
		GD.Print("ENTER_LOCUS_OK: " + locusKey);
	}

	public void GoToParcourMain()
	{
		RefreshFromDb("PARCOUR_MAIN");
		GD.Print("GO_PARCOUR_OK");
	}
		
	// [CHANGE 107] Corridor seed slots must have unique pseudo-keys.
	// Prevents empty slots from sharing parent identity and opening ViewerMin.
	// [CHANGE A14.05] Persistent seed rows must behave like placeholders.

	private void AssignSlotKey(Node3D frame, int slotIndex)
	{
		var (key, isSeed) = LoadKeyFromDb(slotIndex);

		bool isMissingRow = string.IsNullOrWhiteSpace(key);
		bool isPlaceholder = isMissingRow || isSeed;

		// [SCOPE:CORRIDOR_CLEANED_KEY_PRESERVE]
		// Persisted cleaned loci must preserve their real KEY in corridor.
		// Only truly missing rows use PARCOUR_MAIN__SLOT_## compatibility keys.
		string slotKey = isMissingRow
			? $"{CurrentParentKey}__SLOT_{slotIndex:00}"
			: key;

		frame.Set("locus_key", slotKey);
		frame.SetMeta("is_placeholder_slot", isPlaceholder);

		// [SCOPE:CORRIDOR_CLEAR_STALE_COVER]
		// Always reload visual cover after rebinding slot key/state.
		// Cleaned/seed corridor slots must clear any stale hero from prior active content.
		if (frame.HasMethod("_load_cover"))
			frame.Call("_load_cover");
	}
	
	private void EnsureRaz12Running()
	{
		try
		{
			var processes = System.Diagnostics.Process.GetProcessesByName("alexandria");
			if (processes != null && processes.Length > 0)
				return;


			// [CHANGE 130] Unified launcher path for current workspace.
			var scriptPath = @"C:\Alexandria\tools\launch_raz12.ps1";

			if (!System.IO.File.Exists(scriptPath))
			{
				GD.PrintErr("RAZ12_LAUNCHER_NOT_FOUND: " + scriptPath);
				return;
			}

			var psi = new System.Diagnostics.ProcessStartInfo
			{
				FileName = "powershell",
				Arguments = $"-ExecutionPolicy Bypass -File \"{scriptPath}\"",
				UseShellExecute = true,
				CreateNoWindow = false
			};

			System.Diagnostics.Process.Start(psi);
			GD.Print("RAZ12_LAUNCH_OK_AT_STARTUP");
		}
		catch (System.Exception ex)
		{
			GD.PrintErr("RAZ12_LAUNCH_ERR_AT_STARTUP: " + ex.Message);
		}
	}

	private float GetAccumulatedSpacing(int slotIndex)
	{
		if (slotIndex <= 1) return 0.0f;

		if (_frameZBySeq.TryGetValue(slotIndex, out var frameZ))
			return frameZ - StartZ;

		return 0.0f;
	}
	

	private float ComputeFrameGap(int seq)
	{
		int parcourCount = CountParcourAssets(seq);

		if (parcourCount <= 0)
			return ZSpacing;

		float panelLength = 3.0f; // space between frames
		float panelGap = 0.3f;
		float safetyTail = 1.25f;

		float collageLength =
			(parcourCount * panelLength) +
			(Mathf.Max(0, parcourCount - 1) * panelGap);

		return Mathf.Max(ZSpacing, collageLength + 2f * safetyTail);
	}

	private int CountParcourAssets(int seq)
	{
		try
		{
			// [CHANGE A14.05] Seed rows do not contribute parcour assets.
			var (entryKey, isSeed) = LoadKeyFromDb(seq);
			if (string.IsNullOrWhiteSpace(entryKey) || isSeed)
				return 0;

		
			// [CHANGE 125] DB path debug removed after validation.
			var dbPath = AlexandriaPaths.GetDbPath();
			if (!System.IO.File.Exists(dbPath))
			{
				GD.PrintErr($"DB_MISSING: {dbPath}");
				return 0;
				
			}

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			using var cmd = conn.CreateCommand();
			cmd.CommandText =
			@"SELECT COUNT(*)
			  FROM assets
			  WHERE entryKey=$entryKey
			  AND role='parcour'";

			cmd.Parameters.AddWithValue("$entryKey", entryKey);

			return System.Convert.ToInt32(cmd.ExecuteScalar());
		}
		catch (System.Exception e)
		{
			GD.PrintErr($"PARCOUR_COUNT_ERR: {e.Message}");
			return 0;
		}
	}
	
	
	private void BuildWalls(MeshInstance3D wallTemplate)
	{
		var wallParent = wallTemplate.GetParent();
		if (wallParent == null)
			return;

		foreach (Node child in wallParent.GetChildren())
		{
			if (child == wallTemplate)
				continue;

			var childName = child.Name.ToString();
			if (childName.StartsWith("WallPath") || childName.StartsWith("ParcourPanel_"))
				child.QueueFree();
		}

		float wallX = wallTemplate.Position.X;
		float wallY = wallTemplate.Position.Y;

		float wallWidth = 3.2f;
		if (wallTemplate.Mesh is PlaneMesh templatePlane)
			wallWidth = templatePlane.Size.X;

		wallTemplate.Name = "WallPath";
		wallTemplate.Visible = false;

		for (int seq = 1; seq <= TotalFrames; seq++)
		{
			var wall = (MeshInstance3D)wallTemplate.Duplicate();
			wallParent.AddChild(wall);
			wall.Owner = GetTree().EditedSceneRoot;
			wall.Name = $"WallPath{seq:00}";

			float frameZ = _frameZBySeq.TryGetValue(seq, out var zVal) ? zVal : StartZ;
			float zA;
			float zB;

			if (seq == 1)
			{
				zB = frameZ;
				zA = frameZ - _frameGapBySeq[1];
			}
			else
			{
				zA = _frameZBySeq[seq - 1];
				zB = frameZ;
			}

			float segmentLength = Mathf.Max(1.0f, zB - zA);
			float midZ = (zA + zB) * 0.5f;

			var quad = new QuadMesh();
			quad.Size = new Vector2(wallWidth, segmentLength);
			wall.Mesh = quad;
			wall.Position = new Vector3(wallX, wallY, midZ);
			wall.RotationDegrees = new Vector3(0, -90, 0);
			wall.Visible = false;

			BuildParcourPanels(wallParent, wall, seq, wallX, wallY, zA, zB);
		}
	}


	private void ApplyParcourTexture(MeshInstance3D wall, int seq)
	{
		// [CHANGE A14.05] Seed rows must not resolve parcour texture.
		var (key, isSeed) = LoadKeyFromDb(seq);
		string imgPath = isSeed ? "" : ResolveParcourPath(key);

		if (string.IsNullOrWhiteSpace(imgPath) || !System.IO.File.Exists(imgPath))
		{
			wall.MaterialOverride = null;
			return;
		}

		var image = new Image();
		if (image.Load(imgPath) != Error.Ok)
		{
			wall.MaterialOverride = null;
			return;
		}

		var tex = ImageTexture.CreateFromImage(image);

		var mat = new StandardMaterial3D();
		mat.AlbedoTexture = tex;
		mat.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
		mat.CullMode = BaseMaterial3D.CullModeEnum.Disabled;

		wall.MaterialOverride = mat;
	}

	private string ResolveParcourPath(string entryKey)
	{
		if (string.IsNullOrWhiteSpace(entryKey))
			return "";

		try
		{
			var dbPath = AlexandriaPaths.GetDbPath();

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			using var cmd = conn.CreateCommand();
			cmd.CommandText =
			@"SELECT fileName
			  FROM assets
			  WHERE entryKey=$entryKey
			  AND role='parcour'
			  ORDER BY createdAt DESC
			  LIMIT 1";

			cmd.Parameters.AddWithValue("$entryKey", entryKey);

			var fileName = cmd.ExecuteScalar() as string;
			if (string.IsNullOrWhiteSpace(fileName))
				return "";

			return System.IO.Path.Combine(AlexandriaPaths.GetAssetsRoot(), entryKey, fileName);
		}
		catch (System.Exception e)
		{
			GD.PrintErr($"PARCOUR_PATH_ERR: {e.Message}");
			return "";
		}
	}
	
	private void BuildParcourPanels(Node wallParent, MeshInstance3D wallTemplate, int seq, float wallX, float wallY, float zA, float zB)
	{
	// [CHANGE A14.05] Seed rows must not build parcour panels.
	var (key, isSeed) = LoadKeyFromDb(seq);
	var paths = isSeed ? new System.Collections.Generic.List<string>() : ResolveParcourPaths(key);

		if (paths.Count == 0)
			return;

		float panelGap = 0.7f; //Spaces between floating collages, 
		float parcourOffset = 1.25f;
		float panelLength = 2.0f;

		float totalNeeded =
			(paths.Count * panelLength) +
			(Mathf.Max(0, paths.Count - 1) * panelGap);

		float endPanelZ = zB - parcourOffset - 1.35f; // this space add lenght space to the frames
		float startPanelZ = endPanelZ - totalNeeded;

		if (startPanelZ < zA)
		{
			GD.PrintErr($"PARCOUR_PANEL_OVERFLOW seq={seq} needed={totalNeeded} available={(zB - zA)}");
			return;
		}

		float cursorZ = startPanelZ + panelLength * 0.5f;

		for (int i = 0; i < paths.Count; i++)
		{
			var panel = (MeshInstance3D)wallTemplate.Duplicate();
			panel.Name = $"ParcourPanel_{seq:00}_{i + 1:00}";
			wallParent.AddChild(panel);
			panel.Owner = GetTree().EditedSceneRoot;
			panel.Visible = true;

			var quad = new QuadMesh();
			quad.Size = new Vector2(3.2f, panelLength);
			panel.Mesh = quad;
			panel.Position = new Vector3(wallX, wallY, cursorZ);
			panel.RotationDegrees = new Vector3(0, -90, 0);

			ApplyParcourTexture(panel, paths[i]);

			cursorZ += panelLength + panelGap + 0.5f;
		}
	}

	private void ApplyParcourTexture(MeshInstance3D panel, string imgPath)
	{
		if (string.IsNullOrWhiteSpace(imgPath) || !System.IO.File.Exists(imgPath))
		{
			panel.MaterialOverride = null;
			return;
		}

		var image = new Image();
		if (image.Load(imgPath) != Error.Ok)
		{
			panel.MaterialOverride = null;
			return;
		}

		var tex = ImageTexture.CreateFromImage(image);

		var mat = new StandardMaterial3D();
		mat.AlbedoTexture = tex;
		mat.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
		mat.CullMode = BaseMaterial3D.CullModeEnum.Disabled;

		panel.MaterialOverride = mat;
	}

	private System.Collections.Generic.List<string> ResolveParcourPaths(string entryKey)
	{
		var list = new System.Collections.Generic.List<string>();

		if (string.IsNullOrWhiteSpace(entryKey))
			return list;

		try
		{
			var dbPath = AlexandriaPaths.GetDbPath();

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			using var cmd = conn.CreateCommand();
			cmd.CommandText =
			@"SELECT fileName
			  FROM assets
			  WHERE entryKey=$entryKey
			  AND role='parcour'
			  ORDER BY createdAt ASC";

			cmd.Parameters.AddWithValue("$entryKey", entryKey);

			using var reader = cmd.ExecuteReader();
			while (reader.Read())
			{
				var fileName = reader.GetString(0);
				if (!string.IsNullOrWhiteSpace(fileName))
					list.Add(System.IO.Path.Combine(AlexandriaPaths.GetAssetsRoot(), entryKey, fileName));
					
			}

			return list;
		}
		catch (System.Exception e)
		{
			GD.PrintErr($"PARCOUR_PATH_ERR: {e.Message}");
			return list;
		}
	}

	// [SCOPE:CORRIDOR_SLOT_STATE_READ]
	// Godot only reads DB. Seed rows must render as placeholders.
	private (string key, bool isSeed) LoadKeyFromDb(int seq)
	{
		try
		{
			var dbPath = AlexandriaPaths.GetDbPath();

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			using var cmd = conn.CreateCommand();
			cmd.CommandText =
			@"SELECT key, entryState, entryType, layer
			  FROM entries
			  WHERE parentKey=$parentKey
			  AND seq=$seq
			  LIMIT 1";

			cmd.Parameters.AddWithValue("$parentKey", CurrentParentKey);
			cmd.Parameters.AddWithValue("$seq", seq);

			using var reader = cmd.ExecuteReader();

			if (reader.Read())
			{
				string key = reader.IsDBNull(0) ? "" : reader.GetString(0);
				string entryState = reader.IsDBNull(1) ? "" : reader.GetString(1);
				string entryType = reader.IsDBNull(2) ? "" : reader.GetString(2);
				string layer = reader.IsDBNull(3) ? "" : reader.GetString(3);

				bool isSeed =
					string.Equals(entryState, "seed", StringComparison.OrdinalIgnoreCase) ||
					string.Equals(entryType, "seed", StringComparison.OrdinalIgnoreCase) ||
					string.Equals(layer, "seed", StringComparison.OrdinalIgnoreCase);

				return (key, isSeed);
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"DB_READ_ERR: {e.Message}");
		}

		return ("", true);
	}
}
