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
	private const string BridgeDir = @"C:\Alexandria\data\bridge";

	// Viewer Min — lectura (solo UI, sin lógica nueva)
	private const int FontTitlePx = 20;
	private const int FontBodyPx = 16;
	private const int FontLinkPx = 16;
	private const int BlockSeparationPx = 16;
	private const int PanelMarginPx = 20;
	private const int SectionSeparationPx = 12;

	private string _lastKeyShown = "";
	private long _lastVersionShown = 0;
	private double _checkTimer;
	/// Tras clic en frame: polls rápidos hasta que LB escribe viewer para la nueva key.
	private double _burstRemainSec;
	private double _burstAccumSec;
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
		margin.AddThemeConstantOverride("margin_left", PanelMarginPx);
		margin.AddThemeConstantOverride("margin_top", PanelMarginPx);
		margin.AddThemeConstantOverride("margin_right", PanelMarginPx);
		margin.AddThemeConstantOverride("margin_bottom", PanelMarginPx);
		_panel.AddChild(margin);

		var root = new VBoxContainer();
		root.AddThemeConstantOverride("separation", SectionSeparationPx);
		margin.AddChild(root);

		var header = new HBoxContainer();
		header.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		root.AddChild(header);

		_titleLabel = new Label();
		_titleLabel.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		_titleLabel.AddThemeFontSizeOverride("font_size", FontTitlePx);
		_titleLabel.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		header.AddChild(_titleLabel);

		var closeBtn = new Button();
		closeBtn.Text = "×";
		closeBtn.CustomMinimumSize = new Vector2(40, 40);
		closeBtn.FocusMode = Control.FocusModeEnum.None;
		closeBtn.TooltipText = "Cerrar";
		closeBtn.Pressed += () => { _panel.Visible = false; };
		header.AddChild(closeBtn);

		var scroll = new ScrollContainer();
		scroll.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
		scroll.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		scroll.HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled;
		scroll.VerticalScrollMode = ScrollContainer.ScrollMode.Auto;
		scroll.ScrollDeadzone = 12;
		root.AddChild(scroll);

		_stack = new VBoxContainer();
		_stack.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		_stack.AddThemeConstantOverride("separation", BlockSeparationPx);
		scroll.AddChild(_stack);
	}

	/// <summary>Abre panel y fuerza lectura de viewer/current.json (bridge dual: foco vía LB).</summary>
	public void NotifyFrameOpened(string key)
	{
		_lastKeyShown = "";
		_lastVersionShown = -1;
		_burstRemainSec = 3.0;
		_burstAccumSec = 0;
		_panel.Visible = true;
		_titleLabel.Text = string.IsNullOrEmpty(key) ? "Hueco (sin KEY)" : key;
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();

		if (string.IsNullOrEmpty(key))
		{
			var hint = new RichTextLabel();
			hint.BbcodeEnabled = false;
			hint.FitContent = true;
			hint.ScrollActive = false;
			hint.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			hint.AddThemeFontSizeOverride("font_size", FontBodyPx);
			hint.Text = "Este slot no tiene KEY en el snapshot. Revisa seq en data/bridge/current_seq.txt.";
			hint.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(hint);
			GD.Print("[VIEWER][OPEN] empty slot (no LB sync)");
			return;
		}

		var sync = new RichTextLabel();
		sync.BbcodeEnabled = false;
		sync.FitContent = true;
		sync.ScrollActive = false;
		sync.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		sync.AddThemeFontSizeOverride("font_size", FontBodyPx);
		sync.Text = "Sincronizando con LibraryBuild…";
		sync.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		_stack.AddChild(sync);
		GD.Print($"[VIEWER][OPEN] frame click key={key}");
		CheckForContent();
	}

	public override void _Process(double delta)
	{
		if (_burstRemainSec > 0)
		{
			_burstRemainSec -= delta;
			_burstAccumSec += delta;
			if (_burstAccumSec >= 0.12)
			{
				_burstAccumSec = 0;
				CheckForContent();
			}
			return;
		}

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
		long version = ReadViewerVersion(data);

		if (string.IsNullOrEmpty(key))
		{
			if (version == _lastVersionShown && string.IsNullOrEmpty(_lastKeyShown))
				return;
			Godot.Collections.Array bodyEmpty;
			if (!data.ContainsKey("body"))
				bodyEmpty = new Godot.Collections.Array();
			else
				bodyEmpty = data["body"].AsGodotArray();
			ShowContent("", bodyEmpty);
			_lastKeyShown = "";
			_lastVersionShown = version;
			GD.Print($"[VIEWER][REFRESH] key=(empty) version={version}");
			return;
		}

		if (key == _lastKeyShown && version == _lastVersionShown)
			return;

		Godot.Collections.Array body;
		if (!data.ContainsKey("body"))
			body = new Godot.Collections.Array();
		else
			body = data["body"].AsGodotArray();
		ShowContent(key, body);

		_lastKeyShown = key;
		_lastVersionShown = version;
		GD.Print($"[VIEWER][REFRESH] key={key} version={version}");
	}

	private static long ReadViewerVersion(Godot.Collections.Dictionary data)
	{
		if (!data.ContainsKey("version"))
			return 0;
		var v = data["version"];
		return v.VariantType switch
		{
			Variant.Type.Int => v.AsInt64(),
			Variant.Type.Float => (long)v.AsDouble(),
			_ => 0L,
		};
	}

	private void ShowContent(string key, Godot.Collections.Array body)
	{
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();

		_titleLabel.Text = string.IsNullOrEmpty(key) ? "Sin KEY de foco" : key;
		_panel.Visible = true;

		if (body.Count == 0)
		{
			var emptyHint = new RichTextLabel();
			emptyHint.BbcodeEnabled = false;
			emptyHint.FitContent = true;
			emptyHint.ScrollActive = false;
			emptyHint.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			emptyHint.AddThemeFontSizeOverride("font_size", FontBodyPx);
			emptyHint.Text = "Sin contenido aún";
			emptyHint.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(emptyHint);
			return;
		}

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

			if (type == "link")
			{
				var destKey = d.ContainsKey("key") ? d["key"].AsString().Trim() : "";
				var linkText = d.ContainsKey("text") ? d["text"].AsString() : destKey;
				if (string.IsNullOrEmpty(destKey))
					continue;

				var btn = new Button();
				btn.Text = string.IsNullOrEmpty(linkText) ? destKey : linkText;
				btn.Flat = true;
				btn.Alignment = HorizontalAlignment.Left;
				btn.AddThemeFontSizeOverride("font_size", FontLinkPx);
				btn.AddThemeColorOverride("font_color", new Color(0.35f, 0.55f, 0.95f));
				btn.AddThemeColorOverride("font_hover_color", new Color(0.55f, 0.72f, 1f));
				btn.AddThemeColorOverride("font_pressed_color", new Color(0.25f, 0.4f, 0.85f));
				var kNavigate = destKey;
				btn.Pressed += () => NavigateToOpenKey(kNavigate);
				btn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(btn);
				continue;
			}

			var txt = d.ContainsKey("text") ? d["text"].AsString() : "";
			var lbl = new RichTextLabel();
			lbl.BbcodeEnabled = false;
			lbl.FitContent = true;
			lbl.ScrollActive = false;
			lbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			lbl.AddThemeFontSizeOverride("font_size", FontBodyPx);
			lbl.Text = txt;
			lbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(lbl);
		}
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

	/// <summary>
	/// Navegación estructurada (bloque link): mismo contrato que selección de frame → bridge.
	/// </summary>
	private void NavigateToOpenKey(string destKey)
	{
		if (string.IsNullOrWhiteSpace(destKey))
			return;
		try
		{
			Directory.CreateDirectory(BridgeDir);
			// ORM-15V3 Fase 1: foco explícito + compat legacy (GK Fase 2 escribirá solo dual)
			File.WriteAllText(Path.Combine(BridgeDir, "focus_key.txt"), destKey);
			File.WriteAllText(Path.Combine(BridgeDir, "open_key.txt"), destKey);
			File.WriteAllText(Path.Combine(BridgeDir, "active_key.txt"), destKey);
			GD.Print($"[VIEWER][LINK] focus_key+open_key={destKey}");
		}
		catch (Exception e)
		{
			GD.PrintErr("[VIEWER][LINK_ERR] " + e.Message);
			return;
		}

		NotifyFrameOpened(destKey.Trim());
	}
}
