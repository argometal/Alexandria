using Godot;
using System;
using System.IO;
using System.Globalization;

/// <summary>
/// [A15][VIEWER] Lee <c>viewer/current.json</c> del realm activo (sin SQLite en GK).
/// </summary>
public partial class ViewerService : CanvasLayer
{
	private static string ViewerCurrentPath => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "viewer", "current.json");
	private static string DataRoot => AlexandriaDataRoot.RealmDataRoot;
	private static string BridgeDir => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "bridge");
	private const string RealmKey = "ROOT";
	private const string ParcourKey = "PARCOUR_MAIN";

	// Viewer Min — lectura (solo UI, sin lógica nueva)
	private const int FontTitlePx = 20;
	private const int FontBodyPx = 16;
	private const int FontLinkPx = 16;
	private const int BlockSeparationPx = 16;
	private const int PanelMarginPx = 20;
	private const int SectionSeparationPx = 12;

	/// <summary>Etiquetas alineadas con <c>_kTextKinds</c> en LibraryBuild <c>locus_editor.dart</c>.</summary>
	private static string ViewerLabelForTextKind(string raw)
	{
		var k = (raw ?? "").Trim().ToLowerInvariant();
		if (string.IsNullOrEmpty(k) || k == "text")
			return "";
		return k switch
		{
			"hint" => "Hint",
			"place" => "Place",
			"ridiculous_story" => "Ridiculous story",
			_ => "",
		};
	}

	private string _lastKeyShown = "";
	private long _lastVersionShown = 0;
	private bool _lastHasChildrenShown;
	private double _checkTimer;
	/// Tras clic en frame: polls rápidos hasta que LB escribe viewer para la nueva key.
	private double _burstRemainSec;
	private double _burstAccumSec;
	private PanelContainer _panel = null!;
	private VBoxContainer _stack = null!;
	/// Fuera del scroll: siempre visible aunque el body sea largo (frames 1..19).
	private Control _enterButtonHost = null!;
	private Label _titleLabel = null!;
	private AudioStreamPlayer _audioPlayer = null!;

	/// <summary>
	/// El panel solo debe actualizarse / mostrarse tras un clic en marco o enlace (NotifyFrameOpened).
	/// Sin esto, el poll 1 Hz llama a ShowContent y vuelve a abrir el panel con current.json viejo (p. ej. ROOT)
	/// aunque el usuario lo hubiera cerrado — el síntoma: viewer Realm al entrar en parcour sin clic.
	/// </summary>
	private bool _viewerOpenByUser;

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
		var panelStyle = new StyleBoxFlat();
		panelStyle.BgColor = new Color(0.102f, 0.082f, 0.071f, 0.94f);
		panelStyle.BorderColor = new Color(0.95f, 0.78f, 0.42f, 0.45f);
		panelStyle.SetBorderWidthAll(1);
		panelStyle.SetCornerRadiusAll(8);
		_panel.AddThemeStyleboxOverride("panel", panelStyle);
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
		_titleLabel.AddThemeColorOverride("font_color", new Color(1f, 0.85f, 0.45f));
		_titleLabel.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		header.AddChild(_titleLabel);

		var closeBtn = new Button();
		closeBtn.Text = "×";
		closeBtn.CustomMinimumSize = new Vector2(40, 40);
		closeBtn.FocusMode = Control.FocusModeEnum.None;
		closeBtn.TooltipText = "Cerrar";
		closeBtn.Pressed += DismissPanel;
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

		_enterButtonHost = new HBoxContainer();
		_enterButtonHost.Name = "EnterButtonHost";
		_enterButtonHost.Visible = false;
		_enterButtonHost.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		root.AddChild(_enterButtonHost);

		_audioPlayer = new AudioStreamPlayer();
		_audioPlayer.Name = "ViewerAudio";
		_audioPlayer.Bus = "Master";
		AddChild(_audioPlayer);
	}

	/// <summary>Abre panel y fuerza lectura de viewer/current.json (bridge dual: foco vía LB).</summary>
	public void NotifyFrameOpened(string key)
	{
		_viewerOpenByUser = true;
		_lastKeyShown = "";
		_lastVersionShown = -1;
		_lastHasChildrenShown = false;
		_burstRemainSec = 3.0;
		_burstAccumSec = 0;
		_panel.Visible = true;
		_titleLabel.Text = string.IsNullOrEmpty(key) ? "Hueco (sin KEY)" : key;
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();
		ClearEnterButtonHost();

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
		if (!_viewerOpenByUser)
			return;

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
			DismissPanel();
			GetViewport().SetInputAsHandled();
		}
	}

	/// <summary>Fase 2 GK: warp de nivel — solo RealmController escribe bridge.</summary>
	public event Action<string> EnterLevelRequested;

	/// <summary>Fase BACK: subir nivel al parent de la entry enfocada.</summary>
	public event Action<string> BackLevelRequested;

	/// <summary>Fase 2 GK: navegación tipo “link” / foco — mismo contrato que clic en frame (sin warp).</summary>
	public event Action<string> FocusKeyNavigationRequested;

	public void ClosePanel()
	{
		DismissPanel();
	}

	private void DismissPanel()
	{
		_viewerOpenByUser = false;
		_burstRemainSec = 0;
		_burstAccumSec = 0;
		_checkTimer = 0;
		_panel.Visible = false;
	}

	private void CheckForContent()
	{
		if (!_viewerOpenByUser)
			return;

		var focusKey = BridgeSpatial.ReadFocusKey();
		var viewerPath = string.IsNullOrEmpty(focusKey)
			? ViewerCurrentPath
			: Path.Combine(DataRoot, "viewer", focusKey + ".json");
		var usedCurrentJsonFallback = false;
		if (!File.Exists(viewerPath))
		{
			if (viewerPath != ViewerCurrentPath && File.Exists(ViewerCurrentPath))
			{
				GD.Print($"[VIEWER][FALLBACK] missing={viewerPath} using=current.json");
				viewerPath = ViewerCurrentPath;
				usedCurrentJsonFallback = true;
			}
			else
			{
				GD.Print($"[VIEWER][MISS] {viewerPath}");
				return;
			}
		}

		string text;
		try
		{
			text = File.ReadAllText(viewerPath);
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
		var hasChildren = ReadViewerHasChildren(data);
		var parentKey = ReadViewerParentKey(data);
		var recallScore = ReadViewerNumber(data, "recallScore");
		var stabilityDays = ReadViewerNumber(data, "stabilityDays");
		var memoryStrength = ReadViewerNumber(data, "memoryStrength");
		var reviewCount = ReadViewerInt(data, "reviewCount");
		var cognitiveRole = ReadViewerString(data, "cognitiveRole");
		var nextReviewAtIso = ReadViewerString(data, "nextReviewAt");

		// Si caemos en current.json pero el foco pide otra KEY, el parentKey sería el de otra fila
		// (p. ej. ROOT) y ← Back saltaría a realm sin pasar por parcour. No pintar hasta alinear LB.
		if (usedCurrentJsonFallback && !string.IsNullOrEmpty(focusKey) &&
		    !string.Equals(key.Trim(), focusKey.Trim(), StringComparison.Ordinal))
		{
			GD.Print($"[VIEWER][STALE] focusKey={focusKey} jsonKey={key} — esperando viewer keyed");
			return;
		}

		if (string.IsNullOrEmpty(key))
		{
			if (version == _lastVersionShown &&
			    string.IsNullOrEmpty(_lastKeyShown) &&
			    !_lastHasChildrenShown)
				return;
			Godot.Collections.Array bodyEmpty;
			if (!data.ContainsKey("body"))
				bodyEmpty = new Godot.Collections.Array();
			else
				bodyEmpty = data["body"].AsGodotArray();
			ShowContent("", bodyEmpty, false, "", 0, 0, 0, 0, "", "");
			_lastKeyShown = "";
			_lastVersionShown = version;
			_lastHasChildrenShown = false;
			GD.Print($"[VIEWER][REFRESH] key=(empty) version={version}");
			return;
		}

		if (key == _lastKeyShown && version == _lastVersionShown && hasChildren == _lastHasChildrenShown)
			return;

		Godot.Collections.Array body;
		if (!data.ContainsKey("body"))
			body = new Godot.Collections.Array();
		else
			body = data["body"].AsGodotArray();
		ShowContent(key, body, hasChildren, parentKey, recallScore, stabilityDays, memoryStrength, reviewCount,
			cognitiveRole, nextReviewAtIso);

		_lastKeyShown = key;
		_lastVersionShown = version;
		_lastHasChildrenShown = hasChildren;
		GD.Print($"[VIEWER][REFRESH] key={key} version={version} hasChildren={hasChildren}");
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

	private static bool ReadViewerHasChildren(Godot.Collections.Dictionary data)
	{
		if (!data.ContainsKey("hasChildren"))
			return false;
		var h = data["hasChildren"];
		return h.VariantType switch
		{
			Variant.Type.Bool => h.AsBool(),
			Variant.Type.Int => h.AsInt32() != 0,
			Variant.Type.Float => Math.Abs(h.AsDouble()) > 1e-9,
			Variant.Type.String =>
				string.Equals(h.AsString(), "true", StringComparison.OrdinalIgnoreCase)
				|| h.AsString().Trim() == "1",
			_ => false,
		};
	}

	private static string ReadViewerParentKey(Godot.Collections.Dictionary data)
	{
		if (!data.ContainsKey("parentKey"))
			return "";
		var p = data["parentKey"];
		return p.VariantType == Variant.Type.String ? p.AsString().Trim() : "";
	}

	private static double ReadViewerNumber(Godot.Collections.Dictionary data, string key)
	{
		if (!data.ContainsKey(key))
			return 0;
		var v = data[key];
		return v.VariantType switch
		{
			Variant.Type.Int => v.AsInt64(),
			Variant.Type.Float => v.AsDouble(),
			Variant.Type.String => double.TryParse(v.AsString(), out var d) ? d : 0d,
			_ => 0d,
		};
	}

	private static int ReadViewerInt(Godot.Collections.Dictionary data, string key)
	{
		if (!data.ContainsKey(key))
			return 0;
		var v = data[key];
		return v.VariantType switch
		{
			Variant.Type.Int => v.AsInt32(),
			Variant.Type.Float => (int)v.AsDouble(),
			Variant.Type.String => int.TryParse(v.AsString(), out var i) ? i : 0,
			_ => 0,
		};
	}

	private static string ReadViewerString(Godot.Collections.Dictionary data, string key)
	{
		if (!data.ContainsKey(key))
			return "";
		var v = data[key];
		return v.VariantType switch
		{
			Variant.Type.String => v.AsString().Trim(),
			_ => "",
		};
	}

	private static string StripDangerousBbcode(string raw)
	{
		if (string.IsNullOrEmpty(raw))
			return "";
		var s = raw;
		string[] bad = { "[url", "[/url]", "[img", "[/img]", "[table", "[/table]", "[code", "[/code]" };
		foreach (var b in bad)
			s = s.Replace(b, "", StringComparison.OrdinalIgnoreCase);
		return s;
	}

	private static string FormatNextReviewBadge(string iso)
	{
		if (string.IsNullOrWhiteSpace(iso))
			return "";
		var t = iso.Trim();
		if (DateTime.TryParse(t, null, DateTimeStyles.RoundtripKind, out var dt))
			return "Next review: " + dt.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);
		return "Next review: " + t;
	}

	private void ClearEnterButtonHost()
	{
		foreach (Node child in _enterButtonHost.GetChildren())
			child.QueueFree();
		_enterButtonHost.Visible = false;
	}

	private void ShowContent(string key, Godot.Collections.Array body, bool hasChildren, string parentKey, double recallScore, double stabilityDays, double memoryStrength, int reviewCount, string cognitiveRole, string nextReviewAtIso)
	{
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();
		ClearEnterButtonHost();

		_titleLabel.Text = string.IsNullOrEmpty(key) ? "Sin KEY de foco" : key;
		_panel.Visible = true;

		if (!string.IsNullOrEmpty(cognitiveRole) || !string.IsNullOrEmpty(nextReviewAtIso))
		{
			var parts = new System.Collections.Generic.List<string>();
			if (!string.IsNullOrEmpty(cognitiveRole))
				parts.Add("Role: " + cognitiveRole);
			var dueLine = FormatNextReviewBadge(nextReviewAtIso);
			if (!string.IsNullOrEmpty(dueLine))
				parts.Add(dueLine);
			var badge = new RichTextLabel();
			badge.BbcodeEnabled = false;
			badge.FitContent = true;
			badge.ScrollActive = false;
			badge.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			badge.AddThemeFontSizeOverride("font_size", FontBodyPx);
			badge.Text = string.Join("  ·  ", parts);
			badge.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(badge);
		}

		if (!string.IsNullOrEmpty(key) && reviewCount > 0)
		{
			var stats = new RichTextLabel();
			stats.BbcodeEnabled = false;
			stats.FitContent = true;
			stats.ScrollActive = false;
			stats.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			stats.AddThemeFontSizeOverride("font_size", FontBodyPx - 1);
			stats.Text = $"Recall score {recallScore:0.00} · Stability {stabilityDays:0.0}d · Strength {memoryStrength:0.00} · Reviews {reviewCount}";
			stats.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(stats);
		}

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
		}
		else
		{
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
				btn.AddThemeColorOverride("font_color", new Color(0.627f, 0.769f, 1f));
				btn.AddThemeColorOverride("font_hover_color", new Color(0.78f, 0.86f, 1f));
				btn.AddThemeColorOverride("font_pressed_color", new Color(0.48f, 0.62f, 0.95f));
				var kNavigate = destKey;
				btn.Pressed += () => RequestFocusNavigation(kNavigate);
				btn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(btn);
				continue;
			}

			if (type == "audio")
			{
				var src = d.ContainsKey("src") ? d["src"].AsString() : "";
				var path = ResolveImagePath(key, src);
				var audioLbl = new RichTextLabel();
				audioLbl.BbcodeEnabled = false;
				audioLbl.FitContent = true;
				audioLbl.ScrollActive = false;
				audioLbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
				audioLbl.AddThemeFontSizeOverride("font_size", FontBodyPx);
				audioLbl.Text = string.IsNullOrEmpty(src)
					? "Audio: (missing src)"
					: (File.Exists(path) ? "Audio: " + src : "Audio (file missing): " + src);
				audioLbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(audioLbl);
				continue;
			}

			if (type == "warp")
			{
				var wKey = d.ContainsKey("key") ? d["key"].AsString().Trim() : "";
				var wText = d.ContainsKey("text") ? d["text"].AsString() : "";
				if (string.IsNullOrEmpty(wKey))
					continue;
				var wBtn = new Button();
				wBtn.Text = string.IsNullOrEmpty(wText) ? "Warp → " + wKey : wText + " → " + wKey;
				wBtn.Flat = true;
				wBtn.Alignment = HorizontalAlignment.Left;
				wBtn.AddThemeFontSizeOverride("font_size", FontLinkPx);
				wBtn.AddThemeColorOverride("font_color", new Color(0.95f, 0.72f, 0.35f));
				wBtn.AddThemeColorOverride("font_hover_color", new Color(1f, 0.84f, 0.52f));
				wBtn.AddThemeColorOverride("font_pressed_color", new Color(0.82f, 0.58f, 0.22f));
				var wNav = wKey;
				wBtn.Pressed += () => RequestFocusNavigation(wNav);
				wBtn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(wBtn);
				continue;
			}

			if (type == "tag")
			{
				var tagText = d.ContainsKey("text") ? d["text"].AsString() : "";
				var tagLbl = new RichTextLabel();
				tagLbl.BbcodeEnabled = false;
				tagLbl.FitContent = true;
				tagLbl.ScrollActive = false;
				tagLbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
				tagLbl.AddThemeFontSizeOverride("font_size", FontBodyPx);
				tagLbl.Text = "# " + tagText;
				tagLbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(tagLbl);
				continue;
			}

			if (type == "card")
			{
				var word = d.ContainsKey("word") ? d["word"].AsString().Trim() : "";
				var imageSrc = "";
				if (d.ContainsKey("image"))
					imageSrc = d["image"].AsString().Trim();
				else if (d.ContainsKey("src"))
					imageSrc = d["src"].AsString().Trim();
				var phoneticSrc = d.ContainsKey("phonetic") ? d["phonetic"].AsString().Trim() : "";
				var audioSrc = d.ContainsKey("audio") ? d["audio"].AsString().Trim() : "";

				var cardVBox = new VBoxContainer();
				cardVBox.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				cardVBox.AddThemeConstantOverride("separation", 10);

				var frame = new PanelContainer();
				var frameStyle = new StyleBoxFlat();
				frameStyle.BgColor = new Color(0.14f, 0.11f, 0.09f, 0.95f);
				frameStyle.BorderColor = new Color(0.95f, 0.75f, 0.35f, 0.45f);
				frameStyle.SetBorderWidthAll(1);
				frameStyle.SetCornerRadiusAll(10);
				frame.AddThemeStyleboxOverride("panel", frameStyle);
				frame.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;

				var inner = new VBoxContainer();
				inner.AddThemeConstantOverride("separation", 8);
				inner.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				frame.AddChild(inner);

				if (!string.IsNullOrEmpty(word))
				{
					var wl = new Label();
					wl.Text = word;
					wl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
					wl.HorizontalAlignment = HorizontalAlignment.Center;
					wl.AddThemeFontSizeOverride("font_size", FontTitlePx + 8);
					wl.AddThemeColorOverride("font_color", new Color(1f, 0.92f, 0.58f));
					wl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
					inner.AddChild(wl);
				}

				if (!string.IsNullOrEmpty(imageSrc))
				{
					var imgPath = ResolveImagePath(key, imageSrc);
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
							inner.AddChild(tr);
						}
					}
				}

				if (!string.IsNullOrEmpty(phoneticSrc))
				{
					var pPath = ResolveImagePath(key, phoneticSrc);
					if (!string.IsNullOrEmpty(pPath) && File.Exists(pPath))
					{
						var ext = Path.GetExtension(pPath).ToLowerInvariant();
						if (ext == ".txt")
						{
							try
							{
								var pt = File.ReadAllText(pPath).Trim();
								if (!string.IsNullOrEmpty(pt))
								{
									var pl = new Label();
									pl.Text = pt;
									pl.HorizontalAlignment = HorizontalAlignment.Center;
									pl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
									pl.AddThemeFontSizeOverride("font_size", FontBodyPx - 1);
									pl.AddThemeColorOverride("font_color", new Color(0.82f, 0.88f, 0.95f));
									pl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
									inner.AddChild(pl);
								}
							}
							catch
							{
								// ignore phonetic read errors
							}
						}
					}
				}

				if (!string.IsNullOrEmpty(audioSrc))
				{
					var ap = ResolveImagePath(key, audioSrc);
					var playBtn = new Button();
					playBtn.Flat = true;
					playBtn.Text = File.Exists(ap) ? "▶  " + audioSrc : "▶  (missing) " + audioSrc;
					playBtn.Alignment = HorizontalAlignment.Center;
					playBtn.AddThemeFontSizeOverride("font_size", FontLinkPx);
					var captured = ap;
					playBtn.Pressed += () => TryPlayAudioFile(captured);
					playBtn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
					inner.AddChild(playBtn);
				}

				var relatedKeys = new System.Collections.Generic.List<string>();
				if (d.ContainsKey("related_to") && d["related_to"].VariantType == Variant.Type.Array)
				{
					foreach (Variant rv in d["related_to"].AsGodotArray())
					{
						if (rv.VariantType != Variant.Type.String)
							continue;
						var rk = rv.AsString().Trim();
						if (!string.IsNullOrEmpty(rk))
							relatedKeys.Add(rk);
					}
				}

				if (relatedKeys.Count > 0)
				{
					var relLbl = new Label();
					relLbl.Text = "Related";
					relLbl.AddThemeFontSizeOverride("font_size", FontBodyPx - 2);
					relLbl.AddThemeColorOverride("font_color", new Color(0.7f, 0.65f, 0.58f));
					inner.AddChild(relLbl);

					var flow = new VBoxContainer();
					flow.AddThemeConstantOverride("separation", 4);
					foreach (var rk in relatedKeys)
					{
						var rb = new Button();
						rb.Text = rk;
						rb.Flat = true;
						rb.Alignment = HorizontalAlignment.Left;
						rb.AddThemeFontSizeOverride("font_size", FontLinkPx);
						rb.AddThemeColorOverride("font_color", new Color(0.627f, 0.769f, 1f));
						rb.AddThemeColorOverride("font_hover_color", new Color(0.78f, 0.86f, 1f));
						rb.AddThemeColorOverride("font_pressed_color", new Color(0.48f, 0.62f, 0.95f));
						var navK = rk;
						rb.Pressed += () => RequestFocusNavigation(navK);
						rb.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
						flow.AddChild(rb);
					}
					inner.AddChild(flow);
				}

				cardVBox.AddChild(frame);
				_stack.AddChild(cardVBox);
				continue;
			}

			var txt = d.ContainsKey("text") ? d["text"].AsString() : "";
			var textKindRaw = d.ContainsKey("textKind") ? d["textKind"].AsString() : "text";
			var kindCaption = ViewerLabelForTextKind(textKindRaw);
			if (!string.IsNullOrEmpty(kindCaption))
			{
				var kindLbl = new RichTextLabel();
				kindLbl.BbcodeEnabled = false;
				kindLbl.FitContent = true;
				kindLbl.ScrollActive = false;
				kindLbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
				kindLbl.AddThemeFontSizeOverride("font_size", FontBodyPx);
				kindLbl.Text = kindCaption;
				kindLbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
				_stack.AddChild(kindLbl);
			}

			var lbl = new RichTextLabel();
			lbl.BbcodeEnabled = true;
			lbl.FitContent = true;
			lbl.ScrollActive = false;
			lbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
			lbl.AddThemeFontSizeOverride("font_size", FontBodyPx);
			lbl.Text = StripDangerousBbcode(txt);
			lbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(lbl);
		}
		}

		var backTarget = ResolveBackTargetForNavigation(key, parentKey);
		var hasBack = !string.IsNullOrEmpty(backTarget);
		var hasEnter = hasChildren && !string.IsNullOrEmpty(key);
		// Sin botón "Realm": subir a ROOT solo en LibraryBuild, no en GK.
		if (!hasBack && !hasEnter)
			return;

		var row = new HBoxContainer();
		row.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		row.AddThemeConstantOverride("separation", 8);

		if (hasBack)
		{
			var backBtn = new Button();
			backBtn.Text = string.Equals(backTarget, ParcourKey, StringComparison.OrdinalIgnoreCase)
				? "← Parcour"
				: "← Back";
			backBtn.Pressed += () => BackLevelRequested?.Invoke(backTarget);
			backBtn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			row.AddChild(backBtn);
		}

		if (hasEnter)
		{
			var enterBtn = new Button();
			enterBtn.Text = "→ Entrar";
			var warpKey = key;
			enterBtn.Pressed += () => EnterLevelRequested?.Invoke(warpKey);
			enterBtn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			row.AddChild(enterBtn);
		}

		_enterButtonHost.AddChild(row);
		_enterButtonHost.Visible = true;
	}

	private static string ResolveBackTargetForNavigation(string key, string parentKey)
	{
		var k = (key ?? "").Trim();
		var p = (parentKey ?? "").Trim();
		if (string.IsNullOrEmpty(k))
			return "";
		if (string.Equals(k, RealmKey, StringComparison.OrdinalIgnoreCase))
			return "";
		if (string.Equals(k, ParcourKey, StringComparison.OrdinalIgnoreCase))
			return string.IsNullOrEmpty(p) ? RealmKey : p;
		return ParcourKey;
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

	/// <summary>Bloque link: solo evento — RealmController escribe foco (sin warp de contexto).</summary>
	private void RequestFocusNavigation(string destKey)
	{
		if (string.IsNullOrWhiteSpace(destKey))
			return;
		GD.Print($"[VIEWER][LINK] request focus navigation key={destKey}");
		FocusKeyNavigationRequested?.Invoke(destKey.Trim());
	}

	private void TryPlayAudioFile(string absolutePath)
	{
		if (string.IsNullOrEmpty(absolutePath) || !File.Exists(absolutePath))
			return;

		try
		{
			AudioStream stream;
			var ext = Path.GetExtension(absolutePath).ToLowerInvariant();
			if (ext == ".ogg")
				stream = AudioStreamOggVorbis.LoadFromFile(absolutePath);
			else if (ext == ".mp3")
				stream = AudioStreamMP3.LoadFromFile(absolutePath);
			else if (ext == ".wav")
				stream = AudioStreamWav.LoadFromFile(absolutePath);
			else
				return;

			_audioPlayer.Stop();
			_audioPlayer.Stream = stream;
			_audioPlayer.Play();
		}
		catch (Exception e)
		{
			GD.PrintErr("[VIEWER][AUDIO] " + e.Message);
		}
	}
}
