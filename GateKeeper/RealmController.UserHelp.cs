using Godot;

/// <summary>Panel de ayuda de usuario (F1): realms, parcours, objetos, LB, métricas, bridge.</summary>
public partial class RealmController
{
	private CanvasLayer _gkHelpLayer;
	private Control _gkHelpRoot;
	private bool _gkHelpOpen;
	private Label _gkHelpTitle;
	private Label _gkHelpBody;
	private Button _gkHelpCloseBtn;

	private void SetupGkUserHelp()
	{
		_gkHelpLayer = new CanvasLayer { Layer = 42 };
		AddChild(_gkHelpLayer);

		var dim = new ColorRect
		{
			Color = new Color(0f, 0f, 0f, 0.58f),
			MouseFilter = Control.MouseFilterEnum.Stop,
		};
		dim.SetAnchorsPreset(Control.LayoutPreset.FullRect);
		dim.GuiInput += OnGkHelpDimGuiInput;

		var center = new CenterContainer();
		center.SetAnchorsPreset(Control.LayoutPreset.FullRect);
		dim.AddChild(center);

		var panel = new PanelContainer { CustomMinimumSize = new Vector2(560, 400) };
		center.AddChild(panel);

		var outer = new MarginContainer();
		outer.AddThemeConstantOverride("margin_left", 16);
		outer.AddThemeConstantOverride("margin_right", 16);
		outer.AddThemeConstantOverride("margin_top", 14);
		outer.AddThemeConstantOverride("margin_bottom", 14);
		panel.AddChild(outer);

		var vbox = new VBoxContainer { SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
		outer.AddChild(vbox);

		var title = new Label
		{
			Text = GkHelpTitleText(),
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		title.AddThemeFontSizeOverride("font_size", 18);
		vbox.AddChild(title);
		_gkHelpTitle = title;

		var scroll = new ScrollContainer
		{
			CustomMinimumSize = new Vector2(0, 300),
			SizeFlagsVertical = Control.SizeFlags.ExpandFill,
		};
		vbox.AddChild(scroll);

		var body = new Label
		{
			Text = AlexandriaGkUserHelpCopy.GetBody(),
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
		};
		scroll.AddChild(body);
		_gkHelpBody = body;

		var closeRow = new HBoxContainer { Alignment = BoxContainer.AlignmentMode.End };
		vbox.AddChild(closeRow);
		var closeBtn = new Button { Text = GkUiLocale.CloseTooltip() };
		closeBtn.Pressed += () => SetGkUserHelpVisible(false);
		closeRow.AddChild(closeBtn);
		_gkHelpCloseBtn = closeBtn;

		_gkHelpRoot = dim;
		_gkHelpLayer.AddChild(dim);
		dim.Visible = false;
	}

	private void OnGkHelpDimGuiInput(InputEvent @event)
	{
		if (@event is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
			SetGkUserHelpVisible(false);
	}

	private static string GkHelpTitleText() =>
		"Alexandria — " + (GkUiLocale.ReadGkUiLanguageCode() == "es" ? "Ayuda" : "Help");

	private void RefreshGkUserHelpTexts()
	{
		if (_gkHelpTitle == null || _gkHelpBody == null || _gkHelpCloseBtn == null)
			return;
		_gkHelpTitle.Text = GkHelpTitleText();
		_gkHelpBody.Text = AlexandriaGkUserHelpCopy.GetBody();
		_gkHelpCloseBtn.Text = GkUiLocale.CloseTooltip();
	}

	private void SetGkUserHelpVisible(bool open)
	{
		if (_gkHelpRoot == null)
			return;
		_gkHelpOpen = open;
		_gkHelpRoot.Visible = open;
		if (open)
		{
			RefreshGkUserHelpTexts();
			if (_gkMenuOpen)
				SetGkMenuVisible(false);
			Input.MouseMode = Input.MouseModeEnum.Visible;
		}
	}

	private void ToggleGkUserHelp()
	{
		if (_gkHelpRoot == null)
			return;
		SetGkUserHelpVisible(!_gkHelpOpen);
	}
}
