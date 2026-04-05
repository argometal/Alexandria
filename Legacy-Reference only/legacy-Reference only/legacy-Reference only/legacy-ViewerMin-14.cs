using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Microsoft.Data.Sqlite;

public partial class ViewerMin : CanvasLayer
{
	private PanelContainer _panel = null!;
	private Label _title = null!;
	private ScrollContainer _scroll = null!;
	private VBoxContainer _stack = null!;
	private string _currentKey = "";
	//private Button _enterLocusButton = null!;
	//private Button _closeButton = null!;

	private MenuButton _actionsMenu = null!;
	
	private const int MENU_CLOSE_VIEWER = 1;
	private const int MENU_ENTER_LOCUS = 2;
	private const int MENU_BACK_TO_PARCOUR = 3;
	private const int MENU_GO_PARENT = 4;
	private const int MENU_SHOW_CHILDREN = 5;
	private const int MENU_REFRESH_VIEWER = 6;
	
	public override void _Ready()
	{
		Layer = 10;

		_panel = new PanelContainer();
		_panel.Name = "Panel";
		_panel.Visible = false;
		_panel.SetAnchorsPreset(Control.LayoutPreset.FullRect);

		_panel.OffsetLeft = 40; 
		_panel.OffsetTop = 40; 
		_panel.OffsetRight = -40; 
		_panel.OffsetBottom = -40;
		AddChild(_panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 16);
		margin.AddThemeConstantOverride("margin_top", 16);
		margin.AddThemeConstantOverride("margin_right", 16);
		margin.AddThemeConstantOverride("margin_bottom", 16);
		_panel.AddChild(margin);

		var root = new VBoxContainer();
		root.AddThemeConstantOverride("separation", 10);
		margin.AddChild(root);

		var header = new HBoxContainer();
		header.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		root.AddChild(header);

		_title = new Label();
		_title.Text = "ENTRY";
		_title.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		_title.HorizontalAlignment = HorizontalAlignment.Center;
		header.AddChild(_title);

		_actionsMenu = new MenuButton();
		_actionsMenu.Text = "⋮";
		_actionsMenu.Visible = false;
		header.AddChild(_actionsMenu);

		var popup = _actionsMenu.GetPopup();
		popup.IdPressed += OnActionsMenuIdPressed;

		_scroll = new ScrollContainer();
		
							
		_scroll.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
		_scroll.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		root.AddChild(_scroll);

		_stack = new VBoxContainer();
		_stack.Name = "Stack";
		_stack.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		_stack.AddThemeConstantOverride("separation", 12);
		_scroll.AddChild(_stack);
	}

	public void ShowKey(string key)
	{

		_currentKey = key;
		SaveActiveKey(key);
		_title.Text = key;
		RebuildBlocks(key);

		

		var popup = _actionsMenu.GetPopup();
		popup.Clear();
		popup.AddItem("Close Viewer", MENU_CLOSE_VIEWER);
		popup.AddItem("Enter Locus", MENU_ENTER_LOCUS);
		popup.AddItem("Back to Parcour", MENU_BACK_TO_PARCOUR);
		popup.AddItem("Go Parent", MENU_GO_PARENT);
		popup.AddItem("Show Children", MENU_SHOW_CHILDREN);
		popup.AddItem("Refresh", MENU_REFRESH_VIEWER);

		_actionsMenu.Visible = !string.IsNullOrWhiteSpace(_currentKey);
		_panel.Visible = true;
		GD.Print("VIEWER_KEY: " + key);
	}
	

	public void HideViewer()
	{
		_panel.Visible = false;
		_currentKey = "";
		_actionsMenu.Visible = false;
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (!_panel.Visible)
			return;

		if (@event is InputEventKey key &&
			key.Pressed &&
			!key.Echo &&
			key.Keycode == Key.Escape)
		{
			HideViewer();
			GetViewport().SetInputAsHandled();
		}
	}
	
	private void SaveActiveKey(string key)
	{
		try
		{
			AlexandriaPaths.EnsureBridge();
			string bridge = AlexandriaPaths.GetBridgeRoot();

			string file = Path.Combine(bridge, "active_key.txt");
			File.WriteAllText(file, key);
		}
		catch {}
	}


	private void OnActionsMenuIdPressed(long id)
	{
		if (id == MENU_CLOSE_VIEWER)
		{
			HideViewer();
			return;
		}

		if (id == MENU_ENTER_LOCUS)
		{
			var entryType = GetEntryType(_currentKey);
			if (entryType == "object")
			{
				GD.Print("OBJECT_HAS_NO_ROOM: " + _currentKey);
				return;
			}

			if (string.IsNullOrWhiteSpace(_currentKey))
			{
				GD.PrintErr("ENTER_LOCUS_ERR: empty key");
				return;
			}

			// [CHANGE A14.05]
			// Godot must not bootstrap room seeds here.
			// ViewerMin only navigates to an existing locus and writes bridge files.

			AlexandriaPaths.EnsureBridge();
			string bridge = AlexandriaPaths.GetBridgeRoot();

			string file = Path.Combine(bridge, "open_key.txt");
			File.WriteAllText(file, _currentKey);

			string returnFile = Path.Combine(bridge, "return_frame_key.txt");
			File.WriteAllText(returnFile, _currentKey);

			const string locusRoomPath = "res://locus/LocusRoom.tscn";
			if (!ResourceLoader.Exists(locusRoomPath))
			{
				GD.PrintErr("ENTER_LOCUS_ERR: scene not found " + locusRoomPath);
				return;
			}

			HideViewer();

			var err = GetTree().ChangeSceneToFile(locusRoomPath);
			if (err != Error.Ok)
				GD.PrintErr("ENTER_LOCUS_ERR: " + err);

			return;
		}

		
		if (id == MENU_GO_PARENT)
		{

			string parentKey = LoadParentKey(_currentKey);
			if (string.IsNullOrWhiteSpace(parentKey))
			{
				GD.Print("GO_PARENT_EMPTY: " + _currentKey);
				return;
			}

			ShowKey(parentKey);
			return;
		}

		if (id == MENU_SHOW_CHILDREN)
		{
			ShowChildrenList(_currentKey);
			return;
		}

		if (id == MENU_REFRESH_VIEWER)
		{
			if (string.IsNullOrWhiteSpace(_currentKey))
				return;

			// volver a leer DB y reconstruir UI
			ShowKey(_currentKey);

			GD.Print("VIEWER_REFRESH_DB: " + _currentKey);
			return;
		}

		if (id == MENU_BACK_TO_PARCOUR)
		{
			const string worldPath = "res://World.tscn";

			if (!ResourceLoader.Exists(worldPath))
			{
				GD.PrintErr("BACK_PARCOUR_ERR: scene not found " + worldPath);
				return;
			}

			HideViewer();

			var err = GetTree().ChangeSceneToFile(worldPath);
			if (err != Error.Ok)
				GD.PrintErr("BACK_PARCOUR_ERR: " + err);

			return;
		}
		
	}



	private void OnEnterLocusPressed()
	{
		GD.Print("ENTER_LOCUS: " + _currentKey);
	}



	private void RebuildBlocks(string key)
	{
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();

		var blocks = LoadBlocks(key);
		foreach (var block in blocks)
		{
			var t = block.TryGetValue("t", out var tv) ? tv : "p";

			if (t == "img")
			{
				var assetKey = block.TryGetValue("assetKey", out var av) ? av : "";
				var imgPath = ResolveAssetPath(key, assetKey);
				if (!string.IsNullOrEmpty(imgPath) && File.Exists(imgPath))
				{
					var image = new Image();
					if (image.Load(imgPath) == Error.Ok)
					{
						var tex = ImageTexture.CreateFromImage(image);

						var tr = new TextureRect();
						tr.Texture = tex;
						tr.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
						tr.ExpandMode = TextureRect.ExpandModeEnum.FitWidthProportional;
						tr.CustomMinimumSize = new Vector2(0, 220);
						tr.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
						_stack.AddChild(tr);
					}
				}
				continue;
			}

			var text = block.TryGetValue("text", out var xv) ? xv : "";
			var lbl = new RichTextLabel();
			lbl.BbcodeEnabled = false;
			lbl.FitContent = true;
			lbl.ScrollActive = false;
			lbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			lbl.Text = text;
			_stack.AddChild(lbl);
		}
	}

	private List<Dictionary<string, string>> LoadBlocks(string key)
	{
		var list = new List<Dictionary<string, string>>();

		var dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return list;

		using var conn = new SqliteConnection($"Data Source={dbPath}");
		conn.Open();

		var cmd = conn.CreateCommand();
		cmd.CommandText = "SELECT body_text FROM entries WHERE key = $key LIMIT 1";
		cmd.Parameters.AddWithValue("$key", key);

		using var reader = cmd.ExecuteReader();
		if (!reader.Read() || reader.IsDBNull(0))
			return list;

		var raw = reader.GetString(0);
		if (string.IsNullOrWhiteSpace(raw))
			return list;

		try
		{
			using var doc = JsonDocument.Parse(raw);
			if (doc.RootElement.ValueKind != JsonValueKind.Array)
				return list;

			foreach (var el in doc.RootElement.EnumerateArray())
			{
				if (el.ValueKind != JsonValueKind.Object)
					continue;

				var item = new Dictionary<string, string>();

				if (el.TryGetProperty("t", out var tProp))
					item["t"] = tProp.GetString() ?? "p";

				if (el.TryGetProperty("text", out var textProp))
					item["text"] = textProp.GetString() ?? "";

				if (el.TryGetProperty("assetKey", out var assetProp))
					item["assetKey"] = assetProp.GetString() ?? "";

				list.Add(item);
			}
		}
		catch (Exception ex)
		{
			GD.PrintErr("VIEWER_PARSE_ERR: " + ex.Message);
		}

		return list;
	}

	private string GetEntryType(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";

		var dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return "";

		using var conn = new SqliteConnection($"Data Source={dbPath}");
		conn.Open();

		var cmd = conn.CreateCommand();
		cmd.CommandText = "SELECT entryType FROM entries WHERE key = $key LIMIT 1";
		cmd.Parameters.AddWithValue("$key", key);

		var value = cmd.ExecuteScalar();
		return value?.ToString()?.Trim().ToLowerInvariant() ?? "";
	}
	
	private string LoadParentKey(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";

		var dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return "";

		using var conn = new SqliteConnection($"Data Source={dbPath}");
		conn.Open();

		var cmd = conn.CreateCommand();
		cmd.CommandText = "SELECT parentKey FROM entries WHERE key = $key LIMIT 1";
		cmd.Parameters.AddWithValue("$key", key);

		var value = cmd.ExecuteScalar();
		return value?.ToString()?.Trim() ?? "";
	}

	private void ShowChildrenList(string key)
	{
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();

		var title = new Label();
		title.Text = "Children";
		_stack.AddChild(title);

		var children = LoadChildrenKeys(key);
		GD.Print("SHOW_CHILDREN_KEY: " + key);
		GD.Print("SHOW_CHILDREN_COUNT: " + children.Count);

		if (children.Count == 0)
		{
			var empty = new Label();
			empty.Text = "No children yet for this locus";

			_stack.AddChild(empty);
			return;
		}

		foreach (var item in children)
		{
			var btn = new Button();
			btn.Text = item.title;
			btn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			btn.Pressed += () => ShowKey(item.key);
			_stack.AddChild(btn);
		}
	}

	private List<(string key, string title)> LoadChildrenKeys(string parentKey)
	{
		var list = new List<(string key, string title)>();

		if (string.IsNullOrWhiteSpace(parentKey))
			return list;

		var dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return list;

		using var conn = new SqliteConnection($"Data Source={dbPath}");
		conn.Open();

		var cmd = conn.CreateCommand();
		cmd.CommandText = @"
	        SELECT key, title
	        FROM entries
	        WHERE parentKey = $parentKey
			ORDER BY seq";
		cmd.Parameters.AddWithValue("$parentKey", parentKey);

		using var reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			var childKey = reader.IsDBNull(0) ? "" : reader.GetString(0);
			var childTitle = reader.IsDBNull(1) ? childKey : reader.GetString(1);

			GD.Print("CHILD_ROW: " + childKey + " / " + childTitle);

			if (!string.IsNullOrWhiteSpace(childKey))
				list.Add((childKey, childTitle));
		}

		return list;
	}

	private string ResolveAssetPath(string entryKey, string assetKey)
	
	{
		if (string.IsNullOrWhiteSpace(assetKey))
			return "";

		var dbPath = AlexandriaPaths.GetDbPath();
		if (!File.Exists(dbPath))
			return "";

		using var conn = new SqliteConnection($"Data Source={dbPath}");
		conn.Open();

		var cmd = conn.CreateCommand();
		cmd.CommandText = @"
            SELECT fileName
            FROM assets
            WHERE entryKey = $entryKey AND assetKey = $assetKey
			LIMIT 1";
		cmd.Parameters.AddWithValue("$entryKey", entryKey);
		cmd.Parameters.AddWithValue("$assetKey", assetKey);

		var fileName = cmd.ExecuteScalar() as string;
		if (string.IsNullOrWhiteSpace(fileName))
			return "";


		return Path.Combine(AlexandriaPaths.GetAssetsRoot(), entryKey, fileName);
	}
}
