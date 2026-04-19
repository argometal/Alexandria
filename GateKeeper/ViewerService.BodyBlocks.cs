using Godot;
using System;
using System.Collections.Generic;
using System.IO;

public partial class ViewerService
{
	private void AddSectionTitle(string title)
	{
		var l = new Label();
		l.Text = title;
		l.AddThemeFontSizeOverride("font_size", FontBodyPx + 1);
		l.AddThemeColorOverride("font_color", new Color(0.92f, 0.8f, 0.45f));
		_stack.AddChild(l);
	}

	private static void PartitionBodyForObject(
		Godot.Collections.Array body,
		out Godot.Collections.Array lore,
		out Godot.Collections.Array rest,
		out string placeHintForQuiz)
	{
		var hints = new Godot.Collections.Array();
		var places = new Godot.Collections.Array();
		var stories = new Godot.Collections.Array();
		rest = new Godot.Collections.Array();
		placeHintForQuiz = "";

		foreach (Variant item in body)
		{
			if (item.VariantType != Variant.Type.Dictionary)
			{
				rest.Add(item);
				continue;
			}

			var d = item.AsGodotDictionary();
			var type = d.ContainsKey("type") ? d["type"].AsString() : "p";
			if (type != "p")
			{
				rest.Add(item);
				continue;
			}

			var tk = d.ContainsKey("textKind") ? d["textKind"].AsString().ToLowerInvariant() : "text";
			if (string.IsNullOrEmpty(tk))
				tk = "text";

			if (tk == "hint")
				hints.Add(item);
			else if (tk == "place")
			{
				places.Add(item);
				if (string.IsNullOrEmpty(placeHintForQuiz))
					placeHintForQuiz = d.ContainsKey("text") ? d["text"].AsString().Trim() : "";
			}
			else if (tk == "ridiculous_story")
				stories.Add(item);
			else
				rest.Add(item);
		}

		lore = new Godot.Collections.Array();
		foreach (Variant v in hints)
			lore.Add(v);
		foreach (Variant v in places)
			lore.Add(v);
		foreach (Variant v in stories)
			lore.Add(v);
	}

	private void ProcessBodyDictionary(Godot.Collections.Dictionary d, string key)
	{
		var type = d.ContainsKey("type") ? d["type"].AsString() : "p";

		if (type == "img")
		{
			var role = d.ContainsKey("role") ? d["role"].AsString().ToLowerInvariant() : "";
			if (role == "collage" || role == "recall_crop")
				return;

			var src = d.ContainsKey("src") ? d["src"].AsString() : "";
			var path = ResolveImagePath(key, src);
			if (string.IsNullOrEmpty(path) || !File.Exists(path))
				return;

			var image = new Image();
			if (image.Load(path) != Error.Ok)
				return;

			var tex = ImageTexture.CreateFromImage(image);
			var tr = new TextureRect();
			tr.Texture = tex;
			tr.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
			tr.ExpandMode = TextureRect.ExpandModeEnum.FitWidthProportional;
			tr.CustomMinimumSize = new Vector2(0, 200);
			tr.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
			_stack.AddChild(tr);
			return;
		}

		if (type == "link")
		{
			var destKey = d.ContainsKey("key") ? d["key"].AsString().Trim() : "";
			var linkText = d.ContainsKey("text") ? d["text"].AsString() : destKey;
			if (string.IsNullOrEmpty(destKey))
				return;

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
			return;
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
			return;
		}

		if (type == "warp")
		{
			var wKey = d.ContainsKey("key") ? d["key"].AsString().Trim() : "";
			var wText = d.ContainsKey("text") ? d["text"].AsString() : "";
			if (string.IsNullOrEmpty(wKey))
				return;
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
			return;
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
			return;
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

			var relatedKeys = new List<string>();
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
			return;
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
