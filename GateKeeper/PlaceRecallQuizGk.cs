using System;
using System.Collections.Generic;
using System.IO;
using Godot;

/// <summary>
/// Place recall drill: pick the <c>recall_crop</c> that belongs to the current frame. Options may come from
/// Library Build (<c>recallCropQuiz</c> in viewer JSON) or are assembled at runtime by scanning <c>viewer/*.json</c>.
/// </summary>
public static class PlaceRecallQuizGk
{
	private static readonly Random Rng = new Random();

	public static Control TryCreate(
		string realmDataRoot,
		string currentObjectKey,
		string questionHint,
		int fontBodyPx,
		Godot.Collections.Array recallCropQuizPreset,
		Action onAnsweredCorrect,
		bool startExpanded)
	{
		if (string.IsNullOrWhiteSpace(currentObjectKey))
			return BuildMessage(GkUiLocale.PlaceRecallInvalidContext(), fontBodyPx);

		var options = BuildOptions(realmDataRoot, currentObjectKey, recallCropQuizPreset);
		if (options == null || options.Count < 4)
			return BuildMessage(GkUiLocale.PlaceRecallNeedThreeOtherObjects(), fontBodyPx);

		return BuildCollapsibleQuiz(realmDataRoot, options, currentObjectKey, questionHint, fontBodyPx,
			onAnsweredCorrect, startExpanded);
	}

	/// <summary>Barra inferior compacta: pista desplegable + 4 crops en fila (fuera del Viewer Min).</summary>
	public static Control TryCreateHorizontalStrip(
		string realmDataRoot,
		string currentObjectKey,
		string questionHint,
		int fontBodyPx,
		Godot.Collections.Array recallCropQuizPreset,
		Action onAnsweredCorrect)
	{
		if (string.IsNullOrWhiteSpace(currentObjectKey))
			return BuildMessage(GkUiLocale.PlaceRecallInvalidContext(), fontBodyPx);

		var options = BuildOptions(realmDataRoot, currentObjectKey, recallCropQuizPreset);
		if (options == null || options.Count < 4)
			return BuildMessage(GkUiLocale.PlaceRecallNeedThreeOtherObjects(), fontBodyPx);

		return BuildHorizontalStrip(realmDataRoot, options, currentObjectKey, questionHint, fontBodyPx,
			onAnsweredCorrect);
	}

	private static List<(string Key, string Src, bool IsCorrect)> BuildOptions(
		string realmDataRoot,
		string currentObjectKey,
		Godot.Collections.Array preset)
	{
		if (preset != null && preset.Count >= 4)
		{
			var list = new List<(string Key, string Src, bool IsCorrect)>();
			foreach (Variant v in preset)
			{
				if (v.VariantType != Variant.Type.Dictionary)
					continue;
				var d = v.AsGodotDictionary();
				if (!d.ContainsKey("entryKey") || !d.ContainsKey("src"))
					continue;
				var ek = d["entryKey"].AsString().Trim();
				var src = d["src"].AsString().Trim();
				var isCorrect = d.ContainsKey("correct") && d["correct"].VariantType == Variant.Type.Bool &&
					d["correct"].AsBool();
				if (string.IsNullOrEmpty(ek) || string.IsNullOrEmpty(src))
					continue;
				var full = ResolveImagePath(realmDataRoot, ek, src);
				if (string.IsNullOrEmpty(full) || !File.Exists(full))
					continue;
				list.Add((ek, src, isCorrect));
			}

			if (list.Count >= 4)
				return list;
		}

		var correctSrc = ViewerRecallCropGk.TryReadRecallCropSrc(realmDataRoot, currentObjectKey);
		if (string.IsNullOrEmpty(correctSrc))
			return null;
		var correctPath = ResolveImagePath(realmDataRoot, currentObjectKey, correctSrc);
		if (string.IsNullOrEmpty(correctPath) || !File.Exists(correctPath))
			return null;

		var wrongPool = LoadWrongRecallCropOptions(realmDataRoot, currentObjectKey);
		if (wrongPool.Count < 3)
			return null;

		ShuffleList(wrongPool, Rng);
		var outList = new List<(string Key, string Src, bool IsCorrect)>
		{
			(currentObjectKey, correctSrc, true)
		};
		for (var i = 0; i < 3; i++)
			outList.Add((wrongPool[i].Key, wrongPool[i].Src, false));
		ShuffleList(outList, Rng);
		return outList;
	}

	private static List<(string Key, string Src)> LoadWrongRecallCropOptions(string realmDataRoot, string excludeKey)
	{
		var list = new List<(string Key, string Src)>();
		var viewerDir = Path.Combine(realmDataRoot, "viewer");
		if (!Directory.Exists(viewerDir))
			return list;

		foreach (var path in Directory.GetFiles(viewerDir, "*.json"))
		{
			var name = Path.GetFileNameWithoutExtension(path);
			if (string.Equals(name, "current", StringComparison.OrdinalIgnoreCase))
				continue;
			if (string.Equals(name, excludeKey, StringComparison.OrdinalIgnoreCase))
				continue;

			var src = ViewerRecallCropGk.TryReadRecallCropSrc(realmDataRoot, name);
			if (string.IsNullOrEmpty(src))
				continue;
			var full = ResolveImagePath(realmDataRoot, name, src);
			if (string.IsNullOrEmpty(full) || !File.Exists(full))
				continue;
			list.Add((name, src));
		}

		return list;
	}

	private static void ShuffleList<T>(IList<T> list, Random rng)
	{
		for (var i = list.Count - 1; i > 0; i--)
		{
			var j = rng.Next(i + 1);
			(list[i], list[j]) = (list[j], list[i]);
		}
	}

	private static Control BuildMessage(string text, int fontBodyPx)
	{
		var p = new PanelContainer();
		var st = new StyleBoxFlat();
		st.BgColor = new Color(0.12f, 0.1f, 0.09f, 0.95f);
		st.BorderColor = new Color(0.85f, 0.55f, 0.2f, 0.35f);
		st.SetBorderWidthAll(1);
		st.SetCornerRadiusAll(8);
		p.AddThemeStyleboxOverride("panel", st);
		var pad = new MarginContainer();
		pad.AddThemeConstantOverride("margin_left", 12);
		pad.AddThemeConstantOverride("margin_right", 12);
		pad.AddThemeConstantOverride("margin_top", 10);
		pad.AddThemeConstantOverride("margin_bottom", 10);
		p.AddChild(pad);
		var lbl = new Label();
		lbl.Text = text;
		lbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		lbl.AddThemeFontSizeOverride("font_size", fontBodyPx);
		pad.AddChild(lbl);
		return p;
	}

	private static Control BuildCollapsibleQuiz(
		string realmDataRoot,
		List<(string Key, string Src, bool IsCorrect)> options,
		string currentObjectKey,
		string questionHint,
		int fontBodyPx,
		Action onAnsweredCorrect,
		bool startExpanded)
	{
		var outer = new VBoxContainer();
		outer.AddThemeConstantOverride("separation", 8);

		var toggle = new Button();
		toggle.Flat = false;
		toggle.Alignment = HorizontalAlignment.Left;
		toggle.Text = startExpanded ? GkUiLocale.PlaceRecallTapToClose() : GkUiLocale.PlaceRecallTapToOpen();
		toggle.AddThemeFontSizeOverride("font_size", fontBodyPx);
		outer.AddChild(toggle);

		var body = new VBoxContainer();
		body.Visible = startExpanded;
		body.AddThemeConstantOverride("separation", 10);
		outer.AddChild(body);

		toggle.Pressed += () =>
		{
			body.Visible = !body.Visible;
			toggle.Text = body.Visible ? GkUiLocale.PlaceRecallTapToClose() : GkUiLocale.PlaceRecallTapToOpen();
		};

		var qCard = new PanelContainer();
		var qStyle = new StyleBoxFlat();
		qStyle.BgColor = new Color(0.14f, 0.11f, 0.09f, 0.96f);
		qStyle.BorderColor = new Color(0.95f, 0.78f, 0.42f, 0.4f);
		qStyle.SetBorderWidthAll(1);
		qStyle.SetCornerRadiusAll(8);
		qCard.AddThemeStyleboxOverride("panel", qStyle);
		var qPad = new MarginContainer();
		qPad.AddThemeConstantOverride("margin_left", 12);
		qPad.AddThemeConstantOverride("margin_right", 12);
		qPad.AddThemeConstantOverride("margin_top", 10);
		qPad.AddThemeConstantOverride("margin_bottom", 10);
		qCard.AddChild(qPad);
		var qVBox = new VBoxContainer();
		qVBox.AddThemeConstantOverride("separation", 6);
		qPad.AddChild(qVBox);

		var title = new Label();
		title.Text = GkUiLocale.PlaceRecallSection();
		title.AddThemeFontSizeOverride("font_size", fontBodyPx + 2);
		title.AddThemeColorOverride("font_color", new Color(1f, 0.88f, 0.45f));
		qVBox.AddChild(title);

		var hintLbl = new RichTextLabel();
		hintLbl.BbcodeEnabled = false;
		hintLbl.FitContent = true;
		hintLbl.ScrollActive = false;
		hintLbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		hintLbl.AddThemeFontSizeOverride("font_size", fontBodyPx);
		hintLbl.Text = string.IsNullOrWhiteSpace(questionHint) ? "—" : questionHint.Trim();
		hintLbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		qVBox.AddChild(hintLbl);

		var pick = new Label();
		pick.Text = GkUiLocale.PlaceRecallPickCrop();
		pick.AddThemeFontSizeOverride("font_size", fontBodyPx - 1);
		pick.AddThemeColorOverride("font_color", new Color(0.78f, 0.76f, 0.82f));
		qVBox.AddChild(pick);

		body.AddChild(qCard);

		var feedback = new Label();
		feedback.Text = "";
		feedback.AddThemeFontSizeOverride("font_size", fontBodyPx);

		var grid = new GridContainer();
		grid.Columns = 2;
		grid.AddThemeConstantOverride("h_separation", 8);
		grid.AddThemeConstantOverride("v_separation", 8);
		grid.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;

		var answered = false;
		foreach (var opt in options)
		{
			var path = ResolveImagePath(realmDataRoot, opt.Key, opt.Src);
			var tile = MakeTile(path, fontBodyPx);
			var kCapture = opt.Key;
			var correctFlag = opt.IsCorrect;
			tile.GuiInput += (InputEvent e) =>
			{
				if (answered)
					return;
				if (e is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
				{
					answered = true;
					// Solo la bandera `correct` (LB preset o opción runtime con un único true).
					var ok = correctFlag;
					feedback.Text = ok ? GkUiLocale.PlaceRecallCorrect() : GkUiLocale.PlaceRecallWrong();
					feedback.AddThemeColorOverride("font_color",
						ok ? new Color(0.35f, 0.85f, 0.45f) : new Color(0.95f, 0.35f, 0.35f));
					if (ok)
						onAnsweredCorrect?.Invoke();
				}
			};
			grid.AddChild(tile);
		}

		body.AddChild(grid);
		body.AddChild(feedback);

		return outer;
	}

	private static Control BuildHorizontalStrip(
		string realmDataRoot,
		List<(string Key, string Src, bool IsCorrect)> options,
		string _,
		string questionHint,
		int fontBodyPx,
		Action onAnsweredCorrect)
	{
		var root = new VBoxContainer();
		root.AddThemeConstantOverride("separation", 2);

		var row = new HBoxContainer();
		row.AddThemeConstantOverride("separation", 6);
		row.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;

		var hintToggle = new Button();
		hintToggle.Flat = false;
		hintToggle.Alignment = HorizontalAlignment.Center;
		hintToggle.Text = "▼ " + GkUiLocale.LabelHint();
		hintToggle.CustomMinimumSize = new Vector2(72, 28);
		hintToggle.AddThemeFontSizeOverride("font_size", Mathf.Max(11, fontBodyPx - 5));
		row.AddChild(hintToggle);

		var sep = new VSeparator();
		sep.CustomMinimumSize = new Vector2(4, 4);
		row.AddChild(sep);

		var crops = new HBoxContainer();
		crops.AddThemeConstantOverride("separation", 8);
		crops.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		crops.Alignment = BoxContainer.AlignmentMode.Center;

		var feedback = new Label();
		feedback.Text = "";
		feedback.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		feedback.CustomMinimumSize = new Vector2(72, 0);
		feedback.AddThemeFontSizeOverride("font_size", Mathf.Max(11, fontBodyPx - 4));

		var answered = false;
		foreach (var opt in options)
		{
			var path = ResolveImagePath(realmDataRoot, opt.Key, opt.Src);
			var tile = MakeTileCompact(path, fontBodyPx);
			var correctFlag = opt.IsCorrect;
			tile.GuiInput += (InputEvent e) =>
			{
				if (answered)
					return;
				if (e is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
				{
					answered = true;
					var ok = correctFlag;
					feedback.Text = ok ? GkUiLocale.PlaceRecallCorrect() : GkUiLocale.PlaceRecallWrong();
					feedback.AddThemeColorOverride("font_color",
						ok ? new Color(0.35f, 0.85f, 0.45f) : new Color(0.95f, 0.35f, 0.35f));
					if (ok)
						onAnsweredCorrect?.Invoke();
				}
			};
			crops.AddChild(tile);
		}

		row.AddChild(crops);
		row.AddChild(feedback);

		var hintScroll = new ScrollContainer();
		hintScroll.Visible = false;
		hintScroll.CustomMinimumSize = new Vector2(0, 36);
		hintScroll.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		hintScroll.HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled;
		var hintLbl = new RichTextLabel();
		hintLbl.BbcodeEnabled = false;
		hintLbl.FitContent = true;
		hintLbl.ScrollActive = false;
		hintLbl.AutowrapMode = TextServer.AutowrapMode.WordSmart;
		hintLbl.AddThemeFontSizeOverride("font_size", Mathf.Max(10, fontBodyPx - 6));
		hintLbl.Text = string.IsNullOrWhiteSpace(questionHint) ? "—" : questionHint.Trim();
		hintLbl.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		hintScroll.AddChild(hintLbl);

		hintToggle.Pressed += () =>
		{
			hintScroll.Visible = !hintScroll.Visible;
			hintToggle.Text = hintScroll.Visible ? "▲ " + GkUiLocale.LabelHint() : "▼ " + GkUiLocale.LabelHint();
		};

		root.AddChild(row);
		root.AddChild(hintScroll);

		return root;
	}

	private static Control MakeTileCompact(string absolutePath, int fontBodyPx)
	{
		var mat = new PanelContainer();
		mat.MouseFilter = Control.MouseFilterEnum.Stop;
		var st = new StyleBoxFlat();
		st.BgColor = new Color(0.1f, 0.09f, 0.08f, 1f);
		st.BorderColor = new Color(0.55f, 0.52f, 0.48f, 0.75f);
		st.SetBorderWidthAll(1);
		st.SetCornerRadiusAll(6);
		mat.AddThemeStyleboxOverride("panel", st);
		mat.CustomMinimumSize = new Vector2(128, 128);
		mat.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;

		if (string.IsNullOrEmpty(absolutePath) || !File.Exists(absolutePath))
		{
			var lbl = new Label();
			lbl.Text = GkUiLocale.MissingImage();
			lbl.AddThemeFontSizeOverride("font_size", fontBodyPx - 4);
			mat.AddChild(lbl);
			return mat;
		}

		var img = new Image();
		if (img.Load(absolutePath) != Error.Ok)
		{
			var lbl = new Label();
			lbl.Text = GkUiLocale.LoadError();
			lbl.AddThemeFontSizeOverride("font_size", fontBodyPx - 4);
			mat.AddChild(lbl);
			return mat;
		}

		var tex = ImageTexture.CreateFromImage(img);
		var tr = new TextureRect();
		tr.Texture = tex;
		tr.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
		tr.ExpandMode = TextureRect.ExpandModeEnum.FitWidthProportional;
		tr.CustomMinimumSize = new Vector2(0, 144);
		tr.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		mat.AddChild(tr);
		return mat;
	}

	private static Control MakeTile(string absolutePath, int fontBodyPx)
	{
		var mat = new PanelContainer();
		mat.MouseFilter = Control.MouseFilterEnum.Stop;
		var st = new StyleBoxFlat();
		st.BgColor = new Color(0.1f, 0.09f, 0.08f, 1f);
		st.BorderColor = new Color(0.5f, 0.5f, 0.55f, 0.6f);
		st.SetBorderWidthAll(1);
		st.SetCornerRadiusAll(8);
		mat.AddThemeStyleboxOverride("panel", st);
		mat.CustomMinimumSize = new Vector2(120, 120);

		if (string.IsNullOrEmpty(absolutePath) || !File.Exists(absolutePath))
		{
			var lbl = new Label();
			lbl.Text = GkUiLocale.MissingImage();
			lbl.AddThemeFontSizeOverride("font_size", fontBodyPx - 2);
			mat.AddChild(lbl);
			return mat;
		}

		var img = new Image();
		if (img.Load(absolutePath) != Error.Ok)
		{
			var lbl = new Label();
			lbl.Text = GkUiLocale.LoadError();
			lbl.AddThemeFontSizeOverride("font_size", fontBodyPx - 2);
			mat.AddChild(lbl);
			return mat;
		}

		var tex = ImageTexture.CreateFromImage(img);
		var tr = new TextureRect();
		tr.Texture = tex;
		tr.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
		tr.ExpandMode = TextureRect.ExpandModeEnum.FitWidthProportional;
		tr.CustomMinimumSize = new Vector2(0, 140);
		tr.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		mat.AddChild(tr);
		return mat;
	}

	private static string ResolveImagePath(string realmDataRoot, string entryKey, string src)
	{
		if (string.IsNullOrWhiteSpace(src))
			return "";
		if (Path.IsPathRooted(src) && File.Exists(src))
			return src;
		var under = Path.Combine(realmDataRoot, "assets", entryKey, src);
		if (File.Exists(under))
			return under;
		var flat = Path.Combine(realmDataRoot, src.TrimStart('/', '\\'));
		return File.Exists(flat) ? flat : "";
	}
}
