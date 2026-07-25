using Godot;
using System;
using System.Collections.Generic;
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
	/// Altura mínima de imágenes en el panel viewer (×3 respecto al diseño original 200 / 220).
	private const int ViewerImgBlockMinHeightPx = 600;
	private const int ViewerCardImageMinHeightPx = 660;

	/// <summary>Etiquetas alineadas con <c>_kTextKinds</c> en LibraryBuild <c>locus_editor.dart</c>.</summary>
	private static string ViewerLabelForTextKind(string raw)
	{
		var k = (raw ?? "").Trim().ToLowerInvariant();
		if (string.IsNullOrEmpty(k) || k == "text")
			return "";
		return k switch
		{
			"hint" => GkUiLocale.LabelHint(),
			"place" => GkUiLocale.LabelPlace(),
			"ridiculous_story" => GkUiLocale.LabelRidiculousStory(),
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
	/// Una sola línea TRACE con DataRoot/bridge al abrir el panel (evita spam cada 120 ms).
	private bool _loggedViewerCheckContext;
	private PanelContainer _panel = null!;
	private VBoxContainer _stack = null!;
	/// Fuera del scroll: siempre visible aunque el body sea largo (frames 1..19).
	private Control _enterButtonHost = null!;
	private Label _titleLabel = null!;
	private AudioStreamPlayer _audioPlayer = null!;
	private PlaceRecallStrip _placeRecallStrip = null!;

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
		closeBtn.TooltipText = GkUiLocale.CloseTooltip();
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

		var strip = GetParent()?.GetNodeOrNull<PlaceRecallStrip>("PlaceRecallStrip");
		_placeRecallStrip = strip!;
		if (strip == null)
			GD.PrintErr("[VIEWER] PlaceRecallStrip node missing under Realm — place recall gate UI disabled.");
	}

	/// <summary>Abre panel y fuerza lectura de viewer/current.json (bridge dual: foco vía LB).</summary>
	public void NotifyFrameOpened(string key)
	{
		_viewerOpenByUser = true;
		_loggedViewerCheckContext = false;
		_lastKeyShown = "";
		_lastVersionShown = -1;
		_lastHasChildrenShown = false;
		_burstRemainSec = 3.0;
		_burstAccumSec = 0;
		_panel.Visible = true;
		_titleLabel.Text = string.IsNullOrEmpty(key) ? GkUiLocale.NoFocusKeyTitle() : key;
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
			hint.Text = GkUiLocale.EmptySlotNoKey();
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
			sync.Text = GkUiLocale.SyncingLibraryBuild();
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
		if (!_viewerOpenByUser)
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

	/// <summary>Place recall: acierto en sesión (sin persistir en DB).</summary>
	public event Action<string> PlaceRecallUnlockedInSession;

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
		_placeRecallStrip?.ClearStrip();
	}

	private void CheckForContent()
	{
		if (!_viewerOpenByUser)
			return;

		AppDiagnosticsLog.InitIfNeeded();
		var focusKey = BridgeSpatial.ReadFocusKey();
		var focusKeyPath = Path.Combine(BridgeSpatial.BridgeDir, "focus_key.txt");
		var viewerPath = string.IsNullOrEmpty(focusKey)
			? ViewerCurrentPath
			: Path.Combine(DataRoot, "viewer", focusKey + ".json");
		if (!_loggedViewerCheckContext)
		{
			_loggedViewerCheckContext = true;
			AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
				$"CONTEXT_ONCE DataRoot={DataRoot} focusKey=\"{focusKey}\" focus_key.txt exists={File.Exists(focusKeyPath)} path={focusKeyPath} viewerTarget={viewerPath} currentJson={ViewerCurrentPath} existsCurrent={File.Exists(ViewerCurrentPath)}");
		}
		var usedCurrentJsonFallback = false;
		if (!File.Exists(viewerPath))
		{
			if (viewerPath != ViewerCurrentPath && File.Exists(ViewerCurrentPath))
			{
				GD.Print($"[VIEWER][FALLBACK] missing={viewerPath} using=current.json");
				AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
					$"FALLBACK keyed file missing -> use current.json missingWas={viewerPath}");
				viewerPath = ViewerCurrentPath;
				usedCurrentJsonFallback = true;
			}
			else
			{
				GD.Print($"[VIEWER][MISS] {viewerPath}");
				AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
					$"MISS no viewer JSON at path={viewerPath} (and no usable current.json)");
				return;
			}
		}

		string text;
		try
		{
			text = File.ReadAllText(viewerPath);
		}
		catch (Exception ex)
		{
			AppDiagnosticsLog.E("ViewerService.CheckForContent", $"read fail path={viewerPath}", ex);
			return;
		}

		var json = new Json();
		var parseErr = json.Parse(text);
		if (parseErr != Error.Ok)
		{
			AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
				$"JSON_PARSE_FAIL path={viewerPath} err={parseErr}");
			return;
		}

		if (json.Data.VariantType != Variant.Type.Dictionary)
		{
			AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
				$"JSON_NOT_OBJECT path={viewerPath} type={json.Data.VariantType}");
			return;
		}

		var data = json.Data.AsGodotDictionary();
		if (!data.ContainsKey("key"))
		{
			AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
				$"JSON_NO_KEY_FIELD path={viewerPath}");
			return;
		}

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
		var placeRecallGloballyEnabled = BridgeSpatial.ReadPlaceRecallGloballyEnabled();

		var recallCropQuizPreset = new Godot.Collections.Array();
		if (data.ContainsKey("recallCropQuiz") && data["recallCropQuiz"].VariantType == Variant.Type.Array)
			recallCropQuizPreset = data["recallCropQuiz"].AsGodotArray();

		var recallCropSrcResolved = ReadViewerString(data, "recallCropSrc");
		if (string.IsNullOrEmpty(recallCropSrcResolved))
			recallCropSrcResolved = ReadViewerString(data, "recall_crop");
		if (string.IsNullOrEmpty(recallCropSrcResolved))
			recallCropSrcResolved = ViewerRecallCropGk.TryReadRecallCropSrc(DataRoot, key);

		var recallAssetPath = "";
		if (!string.IsNullOrEmpty(recallCropSrcResolved))
		{
			var under = Path.Combine(DataRoot, "assets", key, recallCropSrcResolved);
			if (File.Exists(under))
				recallAssetPath = under;
			else
			{
				var flat = Path.Combine(DataRoot, recallCropSrcResolved.TrimStart('/', '\\'));
				if (File.Exists(flat))
					recallAssetPath = flat;
			}
		}

		var isObjectRole = string.Equals(cognitiveRole, "object", StringComparison.OrdinalIgnoreCase);
		var placeRecallLocked = placeRecallGloballyEnabled && isObjectRole &&
			!string.IsNullOrEmpty(recallAssetPath) &&
			!PlaceRecallSessionState.IsUnlocked(key);

		GD.Print(
			$"[VIEWER][PLACE_RECALL] key={key} global={placeRecallGloballyEnabled} recallSrc={(string.IsNullOrEmpty(recallCropSrcResolved) ? "(none)" : recallCropSrcResolved)} assetOk={!string.IsNullOrEmpty(recallAssetPath)} unlocked={PlaceRecallSessionState.IsUnlocked(key)} locked={placeRecallLocked} presetOpts={recallCropQuizPreset.Count}");

		// Si caemos en current.json pero el foco pide otra KEY, el parentKey sería el de otra fila
		// (p. ej. ROOT) y ← Back saltaría a realm sin pasar por parcour. No pintar hasta alinear LB.
		if (usedCurrentJsonFallback && !string.IsNullOrEmpty(focusKey) &&
		    !string.Equals(key.Trim(), focusKey.Trim(), StringComparison.Ordinal))
		{
			GD.Print($"[VIEWER][STALE] focusKey={focusKey} jsonKey={key} — esperando viewer keyed");
			AppDiagnosticsLog.Trace("ViewerService.CheckForContent",
				$"STALE wait for LB: focusKey={focusKey} jsonKey={key} path={viewerPath}");
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
			ShowContent("", bodyEmpty, false, "", 0, 0, 0, 0, "", "", false, new Godot.Collections.Array());
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
			cognitiveRole, nextReviewAtIso, placeRecallLocked, recallCropQuizPreset);

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

	private static bool ReadViewerBool(Godot.Collections.Dictionary data, string key, bool defaultValue = false)
	{
		if (!data.ContainsKey(key))
			return defaultValue;
		var v = data[key];
		return v.VariantType switch
		{
			Variant.Type.Bool => v.AsBool(),
			Variant.Type.Int => v.AsInt32() != 0,
			Variant.Type.Float => Math.Abs(v.AsDouble()) > 1e-9,
			Variant.Type.String =>
				string.Equals(v.AsString().Trim(), "true", StringComparison.OrdinalIgnoreCase)
				|| v.AsString().Trim() == "1",
			_ => defaultValue,
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
			return GkUiLocale.NextReviewPrefix() + ": " + dt.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);
		return GkUiLocale.NextReviewPrefix() + ": " + t;
	}

	private void ClearEnterButtonHost()
	{
		foreach (Node child in _enterButtonHost.GetChildren())
			child.QueueFree();
		_enterButtonHost.Visible = false;
	}

	private void OnPlaceRecallAnsweredCorrect(string key)
	{
		if (string.IsNullOrEmpty(key))
			return;
		PlaceRecallSessionState.Unlock(key.Trim());
		PlaceRecallUnlockedInSession?.Invoke(key.Trim());
		_lastVersionShown = -1;
		CheckForContent();
	}

	private void ShowContent(string key, Godot.Collections.Array body, bool hasChildren, string parentKey, double recallScore, double stabilityDays, double memoryStrength, int reviewCount, string cognitiveRole, string nextReviewAtIso, bool placeRecallLocked, Godot.Collections.Array recallCropQuizPreset)
	{
		foreach (Node child in _stack.GetChildren())
			child.QueueFree();
		ClearEnterButtonHost();

		var isObject = string.Equals(cognitiveRole, "object", StringComparison.OrdinalIgnoreCase);
		if (placeRecallLocked && isObject)
		{
			_panel.Visible = false;
			PartitionBodyForObject(body, out _, out _, out var placeHintForQuiz);
			var navBackTarget = ResolveBackTargetForNavigation(key, parentKey);
			var showBack = !string.IsNullOrEmpty(navBackTarget);
			var showEnter = hasChildren && !string.IsNullOrEmpty(key);
			_placeRecallStrip?.PresentGate(key, DataRoot, placeHintForQuiz, recallCropQuizPreset,
				() => OnPlaceRecallAnsweredCorrect(key),
				showBack, showEnter, navBackTarget,
				t => BackLevelRequested?.Invoke(t),
				k => EnterLevelRequested?.Invoke(k));
			return;
		}

		_placeRecallStrip?.ClearStrip();
		_titleLabel.Text = string.IsNullOrEmpty(key) ? GkUiLocale.NoFocusKey() : key;
		_panel.Visible = true;

		if (!string.IsNullOrEmpty(cognitiveRole) || !string.IsNullOrEmpty(nextReviewAtIso))
		{
			var parts = new List<string>();
			if (!string.IsNullOrEmpty(cognitiveRole))
				parts.Add(GkUiLocale.RolePrefix() + ": " + cognitiveRole);
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
			stats.Text = GkUiLocale.RecallStatsLine(recallScore, stabilityDays, memoryStrength, reviewCount);
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
			emptyHint.Text = GkUiLocale.NoBodyYet();
			emptyHint.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(emptyHint);
		}
		else if (isObject)
		{
			PartitionBodyForObject(body, out var lore, out var rest, out _);
			if (lore.Count > 0)
			{
				AddSectionTitle(GkUiLocale.SectionObjectLore());
				foreach (Variant item in lore)
				{
					if (item.VariantType != Variant.Type.Dictionary)
						continue;
					ProcessBodyDictionary(item.AsGodotDictionary(), key);
				}
			}

			if (rest.Count > 0)
			{
				if (lore.Count > 0)
					AddSectionTitle(GkUiLocale.SectionOtherContent());
				foreach (Variant item in rest)
				{
					if (item.VariantType != Variant.Type.Dictionary)
						continue;
					ProcessBodyDictionary(item.AsGodotDictionary(), key);
				}
			}
		}
		else
		{
			foreach (Variant item in body)
			{
				if (item.VariantType != Variant.Type.Dictionary)
					continue;
				ProcessBodyDictionary(item.AsGodotDictionary(), key);
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
				? GkUiLocale.BackParcour()
				: GkUiLocale.Back();
			backBtn.Pressed += () => BackLevelRequested?.Invoke(backTarget);
			backBtn.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			row.AddChild(backBtn);
		}

		if (hasEnter)
		{
			var enterBtn = new Button();
			enterBtn.Text = GkUiLocale.EnterChild();
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
