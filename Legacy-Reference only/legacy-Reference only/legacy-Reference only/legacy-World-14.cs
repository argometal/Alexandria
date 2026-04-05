using Godot;
using System;
using System.IO;
using Microsoft.Data.Sqlite;


public partial class World : Node3D
{
	public override void _Ready()
	{
		EnsureRaz12Running();
		CallDeferred(nameof(ApplyReturnFrameRespawn));

		var menu = GetNodeOrNull<MenuButton>("CanvasLayer/GlobalMenu");
		if (menu != null)
		{
			menu.Text = "≡";

			var popup = menu.GetPopup();
			popup.Clear();
			popup.AddItem("Refresh", 2);
			popup.AddItem("Open Viewer", 3);

			popup.IdPressed += (long id) =>
			{
				if (id == 2)
				{
					var spawner = GetNodeOrNull<CorridorSpawner>("CorridorSpawner");
					if (spawner != null)
					{
						spawner.RefreshFromDb("PARCOUR_MAIN");
						GD.Print("WORLD_MENU_REFRESH_OK");
					}
					else
					{
						GD.PrintErr("WORLD_MENU_REFRESH_ERR: CorridorSpawner not found");
					}
				}
			};

		}

		
		StartRefreshWatcher();
			GD.Print("WORLD READY");
	}
	

	private void StartRefreshWatcher()
	{
		var timer = new Timer();
		timer.WaitTime = 0.4;
		timer.Autostart = true;
		timer.Timeout += OnRefreshWatcherTimeout;
		AddChild(timer);
	}

	private void OnRefreshWatcherTimeout()
	{
		try
		{
			string bridge = AlexandriaPaths.GetBridgeRoot();
			string file = Path.Combine(bridge, "refresh_now.txt");
			if (!File.Exists(file))
				return;

			var spawner = GetNodeOrNull<CorridorSpawner>("CorridorSpawner");
			if (spawner != null)
			{
				spawner.RefreshFromDb("PARCOUR_MAIN");
				GD.Print("WORLD_AUTO_REFRESH_OK");
			}
			else
			{
				GD.PrintErr("WORLD_AUTO_REFRESH_ERR: CorridorSpawner not found");
			}

			File.Delete(file);
		}
		catch (System.Exception e)
		{
			GD.PrintErr("WORLD_AUTO_REFRESH_ERR: " + e.Message);
		}
	}

/* 		private void InitializeParcourIfNeeded()
	{
		try
		{
			// [CHANGE 0418] Godot bootstraps the base corridor only once.
			// This is temporary pragmatic initialization to avoid empty-runtime corruption.
			// Seed rows use __SLOT_ keys so Frame01 keeps blocking navigation.

			string dbPath = AlexandriaPaths.GetDbPath();
			if (!File.Exists(dbPath))
			{
				GD.PrintErr("WORLD_INIT_ERR: DB not found " + dbPath);
				return;
			}

			using var conn = new Microsoft.Data.Sqlite.SqliteConnection($"Data Source={dbPath}");
			conn.Open();

			string now = DateTime.Now.ToString("o");

			using (var cmd = conn.CreateCommand())
			{
				cmd.CommandText = @"
INSERT INTO entries (key, title, layer, parentKey, seq, body_text, entryType, capacity, createdAt, updatedAt)
SELECT $key, $title, $layer, NULL, 0, $body, $entryType, $capacity, $createdAt, $updatedAt
WHERE NOT EXISTS (
	SELECT 1 FROM entries WHERE key = $key
);";
				cmd.Parameters.AddWithValue("$key", "PARCOUR_MAIN");
				cmd.Parameters.AddWithValue("$title", "PARCOUR_MAIN");
				cmd.Parameters.AddWithValue("$layer", "parcour");
				cmd.Parameters.AddWithValue("$body", "[{\"t\":\"p\",\"text\":\"\"}]");
				cmd.Parameters.AddWithValue("$entryType", "parcour");
				cmd.Parameters.AddWithValue("$capacity", 20);
				cmd.Parameters.AddWithValue("$createdAt", now);
				cmd.Parameters.AddWithValue("$updatedAt", now);
				cmd.ExecuteNonQuery();
			}

			for (int i = 1; i <= 20; i++)
			{
				using var seedCmd = conn.CreateCommand();
				seedCmd.CommandText = @"
INSERT INTO entries (key, title, layer, parentKey, seq, body_text, entryType, capacity, createdAt, updatedAt)
SELECT $key, $title, $layer, $parentKey, $seq, $body, $entryType, $capacity, $createdAt, $updatedAt
WHERE NOT EXISTS (
	SELECT 1 FROM entries WHERE parentKey = $parentKey AND seq = $seq
);";
				seedCmd.Parameters.AddWithValue("$key", $"PARCOUR_MAIN__SLOT_{i:00}");
				seedCmd.Parameters.AddWithValue("$title", $"Seed {i:00}");
				seedCmd.Parameters.AddWithValue("$layer", "seed");
				seedCmd.Parameters.AddWithValue("$parentKey", "PARCOUR_MAIN");
				seedCmd.Parameters.AddWithValue("$seq", i);
				seedCmd.Parameters.AddWithValue("$body", "[{\"t\":\"p\",\"text\":\"\"}]");
				seedCmd.Parameters.AddWithValue("$entryType", "seed");
				seedCmd.Parameters.AddWithValue("$capacity", 0);
				seedCmd.Parameters.AddWithValue("$createdAt", now);
				seedCmd.Parameters.AddWithValue("$updatedAt", now);
				seedCmd.ExecuteNonQuery();
			}

			var spawner = GetNodeOrNull<CorridorSpawner>("CorridorSpawner");
			if (spawner != null)
			{
				spawner.RefreshFromDb("PARCOUR_MAIN");
			}

			GD.Print("WORLD_INIT_PARCOUR_OK");
		}
		catch (Exception e)
		{
			GD.PrintErr("WORLD_INIT_PARCOUR_ERR: " + e.Message);
		}
	} */


	
	private void ApplyReturnFrameRespawn()
	{
		string key = LoadReturnFrameKey();
		if (string.IsNullOrWhiteSpace(key))
			return;

		var framesRoot = GetNodeOrNull<Node3D>("Frames");
		var cameraRig = GetNodeOrNull<Node3D>("CameraRig");

		if (framesRoot == null || cameraRig == null)
		{
			GD.PrintErr("RESPAWN_ERR: nodes missing");
			return;
		}

		foreach (Node child in framesRoot.GetChildren())
		{
			if (child is not Node3D frame)
				continue;

		
			Variant value = frame.Get("locus_key");
			string frameKey = value.ToString();
			if (frameKey != key)
				continue;

			Vector3 p = frame.GlobalPosition;

			cameraRig.GlobalPosition = new Vector3(
				p.X - 2.8f,
				cameraRig.GlobalPosition.Y,
				p.Z - 4.0f
			);

			ClearReturnFrameKey();
			GD.Print("RESPAWN_OK: " + key);
			return;
		}

		GD.PrintErr("RESPAWN_ERR: frame not found " + key);
	}
	
	private string LoadReturnFrameKey()
	{
		try
		{

			string bridge = AlexandriaPaths.GetBridgeRoot();
			string file = Path.Combine(bridge, "return_frame_key.txt");
			if (!File.Exists(file))
				return "";

			return File.ReadAllText(file).Trim();
		}
		catch
		{
			return "";
		}
	}

	private void ClearReturnFrameKey()
	{
		try
		{

			string bridge = AlexandriaPaths.GetBridgeRoot();
			string file = Path.Combine(bridge, "return_frame_key.txt");
			if (File.Exists(file))
				File.Delete(file);
		}
		catch {}
	}



	private void EnsureRaz12Running()
	{
		try
		{
			var processes = System.Diagnostics.Process.GetProcessesByName("alexandria");
			if (processes.Length > 0)
				return;

			var scriptPath = @"C:\Alexandria\tools\launch_raz12.ps1";


			var psi = new System.Diagnostics.ProcessStartInfo
			{
				FileName = "powershell",
				Arguments = $"-ExecutionPolicy Bypass -File \"{scriptPath}\"",
				UseShellExecute = true
			};

			System.Diagnostics.Process.Start(psi);
			GD.Print("RAZ12 launched from world start");
		}
		catch (System.Exception e)
		{
			GD.PrintErr("RAZ12 launch error: " + e.Message);
		}
	}
}
