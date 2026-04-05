using Godot;
using System.IO;
using Microsoft.Data.Sqlite;

public partial class Frame01 : Node3D
{
	[Export] public string locus_key = "KEY_FRAME_01";

	// [CHANGE 0027] Prevent repeated PowerShell launches while RAZ12 is still starting.
	private static ulong _lastRaz12LaunchTicks = 0;
	private const ulong Raz12LaunchCooldownMs = 5000;

	private Sprite3D coverSprite;
	private Area3D clickArea;
	private MeshInstance3D meshInstance;
	private CollisionShape3D collisionShape;

	public override void _Ready()
	{
		coverSprite = GetNodeOrNull<Sprite3D>("CoverSprite3D");
		clickArea = GetNodeOrNull<Area3D>("ClickArea");
		meshInstance = GetNodeOrNull<MeshInstance3D>("MeshInstance3D");
		collisionShape = GetNodeOrNull<CollisionShape3D>("ClickArea/CollisionShape3D");

		SyncCollisionToMesh();

		if (clickArea != null)
			clickArea.InputEvent += OnClickAreaInputEvent;

		EnsureViewerMinExists();
	
		_load_cover();
		LoadBodyText();
	}

	private void SyncCollisionToMesh()
	{
		if (meshInstance?.Mesh is BoxMesh boxMesh && collisionShape?.Shape is BoxShape3D boxShape)
			boxShape.Size = boxMesh.Size;
	}

	private void OnClickAreaInputEvent(Node camera, InputEvent @event, Vector3 position, Vector3 normal, long shapeIdx)
	{
		// [CHANGE 0030] Corridor seed slots stay blocked, but room object slots may open Builder.
		// A __SLOT_ under PARCOUR_MAIN is still a corridor placeholder; a __SLOT_ under a locus is an editable object slot.

		if (@event is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
		{
			if (string.IsNullOrWhiteSpace(locus_key))
			{
				GD.Print("[FRAME01:EMPTY_KEY]");
				return;
			}

		// [CHANGE A14.06] Open only when the slot has a real row in DB.
		if (IsSeedSlot())
		{
			GD.Print($"[FRAME01:ROW_MISSING_BLOCK] {locus_key}");
			return;
		}

			EnsureRaz12Running();   // starts RAZ12 if closed
			EmitOpenKey();          // writes bridge/open_key.txt
			ShowViewerDeferred();   // opens ViewerMin for the entry
		}
	}

	


	private void EnsureViewerMinExists()
	{
		var root = GetTree().CurrentScene;
		if (root == null)
			return;

		if (root.GetNodeOrNull<ViewerMin>("ViewerMin") != null)
			return;

		var viewer = new ViewerMin();
		viewer.Name = "ViewerMin";
		root.CallDeferred(Node.MethodName.AddChild, viewer);
	}

	private void ShowViewerDeferred()
	{
		CallDeferred(nameof(_ShowViewerNow));
	}

	private void _ShowViewerNow()
	{
		var root = GetTree().CurrentScene;
		if (root == null)
			return;

		var viewer = root.GetNodeOrNull<ViewerMin>("ViewerMin");
		if (viewer == null)
		{
			EnsureViewerMinExists();
			CallDeferred(nameof(_ShowViewerNow));
			return;
		}

		viewer.ShowKey(locus_key);
	}


	// [SCOPE:FRAME_SEED_STATE]
	// A persisted seed row must behave like a blocked structural slot.
	private bool IsSeedSlot()
	{
		if (string.IsNullOrWhiteSpace(locus_key))
			return true;

		bool isRuntimeSlot = locus_key.Contains("__SLOT_");
		bool isCorridorSlot = locus_key.StartsWith("PARCOUR_MAIN__SLOT_")
			&& locus_key.IndexOf("__SLOT_", "PARCOUR_MAIN__SLOT_".Length) < 0;

		if (isRuntimeSlot && !isCorridorSlot)
			return false;

		string dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return true;

		try
		{
			using var conn = new SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			var cmd = conn.CreateCommand();
			cmd.CommandText = @"
				SELECT 1
				FROM entries
				WHERE key = $key
				LIMIT 1";
			cmd.Parameters.AddWithValue("$key", locus_key);

			var result = cmd.ExecuteScalar();
			return result == null;
		}
		catch
		{
			return true;
		}
	}

	private void EnsureRaz12Running()
	{
		try
		{
		
			ulong nowTicks = Time.GetTicksMsec();
			if (nowTicks - _lastRaz12LaunchTicks < Raz12LaunchCooldownMs)
			{
				GD.Print("RAZ12_LAUNCH_SKIPPED_COOLDOWN");
				return;
			}

			var processes = System.Diagnostics.Process.GetProcessesByName("alexandria");
			if (processes != null && processes.Length > 0)
				return;

	
			// [CHANGE 120] Unified launcher path for current Alexandria workspace.	
			var scriptPath = @"C:\Alexandria\tools\launch_raz12.ps1";
			if (!File.Exists(scriptPath))
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
			_lastRaz12LaunchTicks = nowTicks;
			GD.Print("RAZ12_LAUNCH_OK");

		}
		catch (System.Exception ex)
		{
			GD.PrintErr("RAZ12_LAUNCH_ERR: " + ex.Message);
		}
	}

	private void EmitOpenKey()
	{
		// [CHANGE 90] Write open_key to unified Alexandria runtime root.
		// Avoid APPDATA divergence. Godot and RAZ12 must share:
		// C:\Alexandria\data\bridge

		GD.Print("OPEN_KEY_WRITE: " + locus_key);

		string bridge = AlexandriaPaths.GetBridgeRoot();

		if (!Directory.Exists(bridge))
			Directory.CreateDirectory(bridge);

		string file = Path.Combine(bridge, "open_key.txt");
		File.WriteAllText(file, locus_key);
	}

		// [CHANGE 109] Unified runtime assets root (remove APPDATA usage)
		public void _load_cover()
		{
			if (coverSprite == null)
				return;

			string path = ResolveHeroPath();

			if (string.IsNullOrEmpty(path))
				path = Path.Combine(AlexandriaPaths.GetAssetsRoot(), locus_key, "cover.png");

			if (!File.Exists(path))
			{
				coverSprite.Visible = false;
				return;
			}

			var img = new Image();
			var err = img.Load(path);
			if (err != Error.Ok)
			{
				coverSprite.Visible = false;
				return;
			}

			var tex = ImageTexture.CreateFromImage(img);
			coverSprite.Texture = tex;

			FitCoverToFrame();

			coverSprite.Visible = true;
		}


	// [CHANGE 111] Remove APPDATA dependency
	private string ResolveHeroPath()
	{
		
			
		string dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return "";

		try
		{
			using var conn = new SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			var cmd = conn.CreateCommand();
			cmd.CommandText = @"
				SELECT fileName
				FROM assets
				WHERE entryKey = $entryKey AND role = 'hero'
				ORDER BY createdAt DESC
				LIMIT 1";
			cmd.Parameters.AddWithValue("$entryKey", locus_key);

			var fileName = cmd.ExecuteScalar() as string;
			if (string.IsNullOrWhiteSpace(fileName))
				return "";

			
			return Path.Combine(AlexandriaPaths.GetAssetsRoot(), locus_key, fileName);
		}
		catch (System.Exception ex)
		{
			GD.PrintErr("HERO_LOAD_ERR: " + ex.Message);
			return "";
		}
	}

	private void FitCoverToFrame()
	{
		
		
		
		if (coverSprite == null)
			return;

		float width = 2.0f;
		float height = 2.0f;
		float depth = 0.2f;

		if (meshInstance?.Mesh is BoxMesh boxMesh)
		{
			width = boxMesh.Size.X;
			height = boxMesh.Size.Y;
			depth = boxMesh.Size.Z;
		}

		coverSprite.Position = new Vector3(0, 0, depth * 0.5f + 0.01f);
		coverSprite.PixelSize = 0.0015f;
		coverSprite.Billboard = BaseMaterial3D.BillboardModeEnum.Disabled;

		var tex = coverSprite.Texture;
		if (tex == null)
			return;

		Vector2 size = tex.GetSize();
		if (size.X <= 0 || size.Y <= 0)
			return;

		float texRatio = size.X / size.Y;
		float frameRatio = width / height;

		float targetW;
		float targetH;

		if (texRatio > frameRatio)
		{
			targetW = width * 0.92f;
			targetH = targetW / texRatio;
		}
		else
		{
			targetH = height * 0.92f;
			targetW = targetH * texRatio;
		}

		float baseW = size.X * coverSprite.PixelSize;
		float baseH = size.Y * coverSprite.PixelSize;

		if (baseW > 0 && baseH > 0)
			coverSprite.Scale = new Vector3(targetW / baseW, targetH / baseH, 1);
	}

	private void LoadBodyText()
	{
		// [CHANGE 108] Unified runtime DB path (RAZ12 contract)
		string dbPath = AlexandriaPaths.GetDbPath();

		if (!File.Exists(dbPath))
		{
			GD.Print("DB_NOT_FOUND_RUNTIME");
			return;
		}

		using var conn = new SqliteConnection($"Data Source={dbPath}");
		conn.Open();

		var cmd = conn.CreateCommand();
		cmd.CommandText = "SELECT body_text FROM entries WHERE key = $key LIMIT 1";
		cmd.Parameters.AddWithValue("$key", locus_key);

		using var reader = cmd.ExecuteReader();

		if (reader.Read())
		{
			string text = reader.IsDBNull(0) ? "" : reader.GetString(0);
			GD.Print("BODY_TEXT: " + text);
		}
	}
}
