using Godot;
using System;

public partial class LocusSpawner : Node3D
{

	[Export] public NodePath FramesRootPath { get; set; } = new NodePath("Frames");
	[Export] public NodePath FrameTemplatePath { get; set; } = new NodePath("Frames/Frame01");
	
	[Export] public NodePath WallTemplatePath { get; set; } = new NodePath("Corridor/WallPath");
	
	
	[Export] public int TotalFrames { get; set; } = 20;

	[Export] public float StartX { get; set; } = 2.8f;
	[Export] public float StartY { get; set; } = 1.6f;
	[Export] public float StartZ { get; set; } = 10.0f;
	[Export] public float ZSpacing { get; set; } = 10.0f;


	public string CurrentParentKey { get; private set; } = "";
	private readonly System.Collections.Generic.Dictionary<int, float> _frameGapBySeq = new();
	private readonly System.Collections.Generic.Dictionary<int, float> _frameZBySeq = new();
		
	public override void _Ready()
	{
		var menu = GetNodeOrNull<MenuButton>("CanvasLayer/GlobalMenu");
		if (menu != null)
		{
			var popup = menu.GetPopup();
			popup.Clear();
			popup.AddItem("Back to Parcour", 1);
			popup.IdPressed += OnGlobalMenuPressed;
		}
		
		EnsureRaz12Running();
		CurrentParentKey = LoadOpenKeyFromBridge();
		RefreshFromDb(CurrentParentKey);		
		
	}

	public void RefreshCurrentRoom()
	{
		if (string.IsNullOrWhiteSpace(CurrentParentKey))
			return;

		RefreshFromDb(CurrentParentKey);
		GD.Print("ROOM_REFRESH: " + CurrentParentKey);
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		base._UnhandledInput(@event);

		if (@event is InputEventKey key &&
			key.Pressed &&
			key.Keycode == Key.F5)
		{
			RefreshCurrentRoom();

			// [CHANGE 0424] LocusRoom persistent menu for desktop + iPhone.
			// This gives the user a safe exit path even when all visible slots are seeds.
			var menu = GetNodeOrNull<MenuButton>("CanvasLayer/GlobalMenu");
			if (menu != null)
			{
				// [CHANGE 0425] Force a visible popup for LocusRoom menu.
				// Needed because on this scene the MenuButton icon renders,
				// but the popup is not opening reliably by default.
				menu.Text = "≡";
				menu.Flat = true;
				menu.CustomMinimumSize = new Vector2(164, 164);
					
				var popup = menu.GetPopup();
				popup.Clear();
				popup.AddItem("Return to Parcour", 1);
				popup.AddItem("Refresh", 2);
				popup.ResetSize();

				menu.Pressed += () =>
				{
					// [CHANGE 0427] Force popup size and position.
					// The menu logic works, but the popup is rendering too small to show labels.
					
					popup.Position = new Vector2I(4, 28);
					popup.Size = new Vector2I(220, 90);
					popup.ResetSize();
					popup.Show();
				};


				popup.IdPressed += (long id) =>
				{
					if (id == 1)
					{
						GoToParcourMain();
						return;
					}

					if (id == 2)
					{
						RefreshCurrentRoom();
						GD.Print("LOCUS_MENU_REFRESH_OK");
					}
				};
			}

			



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

		var wallTemplate = GetNodeOrNull<MeshInstance3D>(WallTemplatePath);

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
			GD.PrintErr("LOCUS_WALL_ERR: WallPath template not found");
			return;
		}

		foreach (Node child in framesRoot.GetChildren())
		{
			if (child == template)
				continue;

			child.QueueFree();
		}

		template.Visible = false;

		for (int i = 1; i <= TotalFrames; i++)
		{
			var clone = (Node3D)template.Duplicate();
			clone.Name = $"Frame{i:00}";
			clone.Position = new Vector3(StartX, StartY, StartZ + GetAccumulatedSpacing(i));
			clone.RotationDegrees = new Vector3(0, -90, 0);
			clone.Visible = true;

			AssignSlotKey(clone, i);
			framesRoot.AddChild(clone);
			clone.Owner = GetTree().EditedSceneRoot;
		}


		BuildWalls(wallTemplate);
		GD.Print($"LOCUS_SPAWNER_OK: {CurrentParentKey} / {TotalFrames} objects");
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
		const string worldPath = "res://World.tscn";

		if (!ResourceLoader.Exists(worldPath))
		{
			GD.PrintErr("GO_PARCOUR_ERR: scene not found " + worldPath);
			return;
		}

		var err = GetTree().ChangeSceneToFile(worldPath);
		if (err != Error.Ok)
		{
			GD.PrintErr("GO_PARCOUR_ERR: " + err);
			return;
		}

		GD.Print("GO_PARCOUR_OK");
	}

	private void OnGlobalMenuPressed(long id)
	{
		// [CHANGE 0435] Handle the dropdown menu inside LocusRoom.
		// This is the iPhone-safe exit path because LocusRoom cannot depend on Escape.
		if (id == 1)
		{
			GoToParcourMain();
			return;
		}
	}
	
	private void AssignSlotKey(Node3D frame, int slotIndex)
	{
		var key = LoadKeyFromDb(slotIndex);
		bool isPlaceholder = string.IsNullOrWhiteSpace(key);

		string slotKey = isPlaceholder
			? $"{CurrentParentKey}__SLOT_{slotIndex:00}"
			: key;

		frame.Set("locus_key", slotKey);
		frame.SetMeta("is_placeholder_slot", isPlaceholder);

		var coverSprite = frame.GetNodeOrNull<Sprite3D>("CoverSprite3D");
		if (coverSprite != null)
		{
			coverSprite.Texture = null;
			coverSprite.Visible = false;
		}

		if (!isPlaceholder && frame.HasMethod("_load_cover"))
			frame.Call("_load_cover");
	}
		
	
	private void EnsureRaz12Running()
	{
		try
		{
			var processes = System.Diagnostics.Process.GetProcessesByName("alexandria");
			if (processes != null && processes.Length > 0)
				return;

			// [CHANGE 0026] Use unified Alexandria launcher path
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
			var entryKey = LoadKeyFromDb(seq);
			if (string.IsNullOrWhiteSpace(entryKey))
				return 0;


			var dbPath = AlexandriaPaths.GetDbPath();

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			using var cmd = conn.CreateCommand();
			cmd.CommandText =
				@"SELECT COUNT(*)
				FROM assets
				WHERE entryKey=$entryKey";

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
		string key = LoadKeyFromDb(seq);
		string imgPath = ResolveParcourPath(key);

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
				ORDER BY createdAt ASC
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
		var key = LoadKeyFromDb(seq);
		var paths = ResolveParcourPaths(key);

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

	private string LoadKeyFromDb(int seq)
	{
		try
		{
			var dbPath = AlexandriaPaths.GetDbPath();

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			using var cmd = conn.CreateCommand();
			cmd.CommandText =
			@"SELECT key
			  FROM entries
			  WHERE parentKey=$parentKey
			  AND seq=$seq
			  LIMIT 1";

			cmd.Parameters.AddWithValue("$parentKey", CurrentParentKey);
			cmd.Parameters.AddWithValue("$seq", seq);

			using var reader = cmd.ExecuteReader();

			if (reader.Read())
				return reader.GetString(0);
		}
		catch (Exception e)
		{
			GD.PrintErr($"DB_READ_ERR: {e.Message}");
		}

		return "";
	}
	private string LoadOpenKeyFromBridge()
	{
		try
		{
			var appdata = System.Environment.GetEnvironmentVariable("APPDATA");			
			var file = System.IO.Path.Combine(AlexandriaPaths.GetBridgeRoot(), "open_key.txt");

			if (!System.IO.File.Exists(file))
				return "";

			return System.IO.File.ReadAllText(file).Trim();
		}
		catch
		{
			return "";
		}
	}
		
}
