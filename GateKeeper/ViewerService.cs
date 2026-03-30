using Godot;
using System;
using System.IO;

/// <summary>
/// [A15][VIEWER] Lee solo C:\Alexandria\data\viewer\current.json (sin SQLite en GK).
/// </summary>
public partial class ViewerService : CanvasLayer
{
	private const string ViewerPath = @"C:\Alexandria\data\viewer\current.json";
	private const string DataRoot = @"C:\Alexandria\data";

	private string _lastKeyShown = "";
	private double _checkTimer;
	private PanelContainer _panel = null!;
	private VBoxContainer _stack = null!;
	private Label _titleLabel = null!;

	public override void _Ready()
	{
		Layer = 100;

		_panel = new PanelContainer();
		_panel.Name = "ViewerPanel";
		_panel.Visible = false;
		_panel.SetAnchorsPreset(Control.LayoutPreset.FullRect);
		_panel.OffsetLeft = 48;
		_panel.OffsetTop = 48;
		_panel.OffsetRight = -48;
		_panel.OffsetBottom = -48;
		AddChild(_panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 12);
		margin.AddThemeConstantOverride("margin_top", 12);
		margin.AddThemeConstantOverride("margin_right", 12);
		margin.AddThemeConstantOverride("margin_bottom", 12);
		_panel.AddChild(margin);

		var root = new VBoxContainer();
		root.AddThemeConstantOverride("separation", 8);
		margin.AddChild(root);

		var header = new HBoxContainer();
		header.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		root.AddChild(header);

		_titleLabel = new Label();
		_titleLabel.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		header.AddChild(_titleLabel);

		var closeBtn = new Button();
		closeBtn.Text = "Close";
		closeBtn.Pressed += () => { _panel.Visible = false; };
		header.AddChild(closeBtn);

		var scroll = new ScrollContainer();
		scroll.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
		scroll.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		root.AddChild(scroll);

		_stack = new VBoxContainer();
		_stack.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		_stack.AddThemeConstantOverride("separation", 10);
		scroll.AddChild(_stack);
	}

	public override void _Process(double delta)
	{
		_checkTimer += delta;
		if (_checkTimer < 1.0)
			return;
		_checkTimer = 0;
		CheckForContent();
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (!_panel.Visible)
			return;
		if (@event is InputEventKey k && k.Pressed && !k.Echo && k.Keycode == Key.Escape)
		{
			_panel.Visible = false;
			GetViewport().SetInputAsHandled();
		}
	}

	private void CheckForContent()
	{
		if (!File.Exists(ViewerPath))
			return;

		string text;
		try
		{
			text = File.ReadAllText(ViewerPath);
		}
		catch
		{
			return;
		}

		var json = new Json();
		if (json.Parse(text) != Error.Ok)
			return;

		if (json.Data.VariantType != Variant.Type.Dictionary)
			return;

		var data = json.Data.AsGodotDictionary();
		if (!data.ContainsKey("key"))
			return;

		var key = data["key"].AsString();
		if (string.IsNullOrEmpty(key))
			return;

		if (key == _lastKeyShown)
			return;

		if (!data.ContainsKey("body"))
			return;

		_lastKeyShown = key;

		var body = data["body"].AsGodotArray();
		ShowContent(key, body);
	}

	private void ShowContent(string key, Godot.Collections.Array body)
	{
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();

		_titleLabel.Text = key;
		_panel.Visible = true;

		foreach (Variant item in body)
		{
			if (item.VariantType != Variant.Type.Dictionary)
				continue;

			var d = item.AsGodotDictionary();
			var type = d.ContainsKey("type") ? d["type"].AsString() : "p";

			if (type == "img")
			{
				var src = d.ContainsKey("src") ? d["src"].AsString() : "";
				var path = ResolveImagePath(key, src);
				if (string.IsNullOrEmpty(path) || !File.Exists(path))
					continue;

				var image = new Image();
				if (image.Load(path) != Error.Ok)
					continue;

				var tex = ImageTexture.CreateFromImage(image);
				var tr = new TextureRect();
				tr.Texture = tex;
				tr.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
				tr.ExpandMode = TextureRect.ExpandModeEnum.FitWidthProportional;
				tr.CustomMinimumSize = new Vector2(0, 200);
				tr.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(tr);
				continue;
			}

			var txt = d.ContainsKey("text") ? d["text"].AsString() : "";
			var lbl = new RichTextLabel();
			lbl.BbcodeEnabled = false;
			lbl.FitContent = true;
			lbl.ScrollActive = false;
			lbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			lbl.Text = txt;
			lbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(lbl);
		}

		GD.Print($"[VIEWER][SHOW] key={key} blocks={body.Count}");
	}

	private static string ResolveImagePath(string entryKey, string src)
	{
		if (string.IsNullOrWhiteSpace(src))
			return "";

		if (Path.IsPathRooted(src) && File.Exists(src))
			return src;

		var underAssets = Path.Combine(DataRoot, "assets", entryKey, src);
		if (File.Exists(underAssets))
			return underAssets;

		return File.Exists(Path.Combine(DataRoot, src.TrimStart('/', '\\')))
			? Path.Combine(DataRoot, src.TrimStart('/', '\\'))
			: "";
	}
}
