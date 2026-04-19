using System;
using Godot;

/// <summary>
/// UI separada del Viewer Min: gate place recall en barra inferior compacta (navegación mínima + quiz).
/// </summary>
public partial class PlaceRecallStrip : CanvasLayer
{
	private PanelContainer _panel = null!;
	private VBoxContainer _rootVBox = null!;

	public bool IsGateVisible => Visible;

	public override void _Ready()
	{
		Layer = 102;
		Visible = false;

		_panel = new PanelContainer();
		_panel.Name = "PlaceRecallBar";
		_panel.SetAnchorsPreset(Control.LayoutPreset.BottomWide);
		_panel.OffsetTop = -248f;
		var ps = new StyleBoxFlat();
		ps.BgColor = new Color(0.07f, 0.055f, 0.048f, 0.97f);
		ps.BorderColor = new Color(0.92f, 0.72f, 0.35f, 0.45f);
		ps.SetBorderWidthAll(1);
		ps.SetCornerRadiusAll(8);
		ps.SetContentMarginAll(4);
		_panel.AddThemeStyleboxOverride("panel", ps);
		AddChild(_panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 6);
		margin.AddThemeConstantOverride("margin_right", 6);
		margin.AddThemeConstantOverride("margin_top", 4);
		margin.AddThemeConstantOverride("margin_bottom", 4);
		_panel.AddChild(margin);

		_rootVBox = new VBoxContainer();
		_rootVBox.AddThemeConstantOverride("separation", 4);
		margin.AddChild(_rootVBox);
	}

	public void ClearStrip()
	{
		foreach (Node c in _rootVBox.GetChildren())
			c.QueueFree();
		Visible = false;
	}

	/// <summary>Muestra solo el gate (sin abrir el panel Viewer Min).</summary>
	public void PresentGate(
		string entryKey,
		string realmDataRoot,
		string placeHint,
		Godot.Collections.Array quizPreset,
		Action onAnsweredCorrect,
		bool showBack,
		bool showEnter,
		string backTarget,
		Action<string> invokeBack,
		Action<string> invokeEnter)
	{
		foreach (Node c in _rootVBox.GetChildren())
			c.QueueFree();

		Visible = true;
		_panel.Visible = true;

		const string parcourKey = "PARCOUR_MAIN";
		var nav = new HBoxContainer();
		nav.AddThemeConstantOverride("separation", 6);
		nav.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;

		if (showBack && !string.IsNullOrEmpty(backTarget))
		{
			var b = new Button();
			b.Text = string.Equals(backTarget, parcourKey, StringComparison.OrdinalIgnoreCase)
				? GkUiLocale.BackParcour()
				: GkUiLocale.Back();
			b.AddThemeFontSizeOverride("font_size", 11);
			var t = backTarget;
			b.Pressed += () => invokeBack?.Invoke(t);
			nav.AddChild(b);
		}

		if (showEnter && !string.IsNullOrEmpty(entryKey))
		{
			var eBtn = new Button();
			eBtn.Text = GkUiLocale.EnterChild();
			eBtn.AddThemeFontSizeOverride("font_size", 11);
			var k = entryKey;
			eBtn.Pressed += () => invokeEnter?.Invoke(k);
			nav.AddChild(eBtn);
		}

		var title = new Label();
		title.Text = GkUiLocale.PlaceRecallSection() + " · " + entryKey;
		title.AddThemeFontSizeOverride("font_size", 11);
		title.AddThemeColorOverride("font_color", new Color(1f, 0.85f, 0.48f));
		title.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		title.HorizontalAlignment = HorizontalAlignment.Right;
		nav.AddChild(title);

		_rootVBox.AddChild(nav);

		var quiz = PlaceRecallQuizGk.TryCreateHorizontalStrip(realmDataRoot, entryKey, placeHint, 13, quizPreset,
			onAnsweredCorrect);
		if (quiz != null)
			_rootVBox.AddChild(quiz);
	}
}
