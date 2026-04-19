using Godot;

/// <summary>Menú ☰ (HUD): ayuda, ir al hub del parcour, y salto entre marcos del pasillo.</summary>
public partial class RealmController
{
	private bool _gkMenuOpen;
	private Control _gkMenuPanel;
	private Button _gkMenuBurger;
	private Button _gkBtnParcourHub;
	private Button _gkBtnParcourPrev;
	private Button _gkBtnParcourNext;
	private Label _gkMenuFrameLabel;
	private Label _gkMenuParcourHint;

	private const string ParcourHubKey = "PARCOUR_MAIN";

	private void SetupGkHudMenu(Control hudRoot)
	{
		var anchor = new MarginContainer
		{
			MouseFilter = Control.MouseFilterEnum.Stop,
		};
		anchor.SetAnchorsPreset(Control.LayoutPreset.TopLeft);
		anchor.OffsetLeft = 8f;
		anchor.OffsetTop = 8f;
		anchor.OffsetRight = 52f;
		anchor.OffsetBottom = 52f;
		hudRoot.AddChild(anchor);

		_gkMenuBurger = new Button
		{
			Text = "☰",
			Flat = true,
			TooltipText = GkUiLocale.MenuBurgerTooltip(),
		};
		_gkMenuBurger.CustomMinimumSize = new Vector2(44f, 44f);
		_gkMenuBurger.AddThemeFontSizeOverride("font_size", 22);
		_gkMenuBurger.Pressed += ToggleGkMenu;
		anchor.AddChild(_gkMenuBurger);

		_gkMenuPanel = new PanelContainer
		{
			Visible = false,
			MouseFilter = Control.MouseFilterEnum.Stop,
		};
		_gkMenuPanel.SetAnchorsPreset(Control.LayoutPreset.TopLeft);
		_gkMenuPanel.OffsetLeft = 8f;
		_gkMenuPanel.OffsetTop = 56f;
		_gkMenuPanel.OffsetRight = 300f;
		_gkMenuPanel.OffsetBottom = 400f;
		hudRoot.AddChild(_gkMenuPanel);

		var outer = new MarginContainer();
		outer.AddThemeConstantOverride("margin_left", 12);
		outer.AddThemeConstantOverride("margin_right", 12);
		outer.AddThemeConstantOverride("margin_top", 10);
		outer.AddThemeConstantOverride("margin_bottom", 10);
		_gkMenuPanel.AddChild(outer);

		var v = new VBoxContainer();
		v.AddThemeConstantOverride("separation", 8);
		outer.AddChild(v);

		var helpBtn = new Button
		{
			Text = GkUiLocale.MenuHelp(),
		};
		helpBtn.Pressed += OnGkMenuHelpPressed;
		v.AddChild(helpBtn);

		v.AddChild(new HSeparator());

		_gkBtnParcourHub = new Button
		{
			Text = GkUiLocale.MenuGoParcourHub(),
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
		};
		_gkBtnParcourHub.Pressed += OnGkMenuGoParcourHub;
		v.AddChild(_gkBtnParcourHub);

		var parcourTitle = new Label
		{
			Text = GkUiLocale.MenuParcourFramesTitle(),
		};
		parcourTitle.AddThemeFontSizeOverride("font_size", 14);
		v.AddChild(parcourTitle);

		_gkMenuFrameLabel = new Label { Text = "—" };
		_gkMenuFrameLabel.AddThemeFontSizeOverride("font_size", 12);
		v.AddChild(_gkMenuFrameLabel);

		var row = new HBoxContainer();
		row.AddThemeConstantOverride("separation", 8);
		_gkBtnParcourPrev = new Button
		{
			Text = GkUiLocale.MenuPreviousFrame(),
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
		};
		_gkBtnParcourPrev.Pressed += OnGkMenuParcourPrev;
		_gkBtnParcourNext = new Button
		{
			Text = GkUiLocale.MenuNextFrame(),
			SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
		};
		_gkBtnParcourNext.Pressed += OnGkMenuParcourNext;
		row.AddChild(_gkBtnParcourPrev);
		row.AddChild(_gkBtnParcourNext);
		v.AddChild(row);

		_gkMenuParcourHint = new Label
		{
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			Text = GkUiLocale.MenuParcourCorridorHint(),
		};
		_gkMenuParcourHint.AddThemeFontSizeOverride("font_size", 11);
		_gkMenuParcourHint.AddThemeColorOverride("font_color", new Color(0.75f, 0.75f, 0.78f));
		v.AddChild(_gkMenuParcourHint);
	}

	private void OnGkMenuGoParcourHub()
	{
		SetGkMenuVisible(false);
		OnBackLevelRequested(ParcourHubKey);
	}

	private void OnGkMenuHelpPressed()
	{
		SetGkMenuVisible(false);
		ToggleGkUserHelp();
	}

	private void ToggleGkMenu()
	{
		SetGkMenuVisible(!_gkMenuOpen);
	}

	private void SetGkMenuVisible(bool open)
	{
		if (_gkMenuPanel == null)
			return;
		_gkMenuOpen = open;
		_gkMenuPanel.Visible = open;
		if (open)
		{
			RefreshGkMenuParcourUi();
			Input.MouseMode = Input.MouseModeEnum.Visible;
		}
		else if (!_gkHelpOpen)
			Input.MouseMode = Input.MouseModeEnum.Captured;
	}

	private void RefreshGkMenuParcourUi()
	{
		var ctx = BridgeSpatial.ReadContextKey()?.Trim() ?? "";
		var objectRoom = BridgeSpatial.IsObjectLocusKey(ctx);
		var canParcour = _spawner != null && _camera != null && !objectRoom && !string.IsNullOrEmpty(ctx);

		if (_gkBtnParcourPrev != null)
			_gkBtnParcourPrev.Disabled = !canParcour;
		if (_gkBtnParcourNext != null)
			_gkBtnParcourNext.Disabled = !canParcour;
		if (_gkMenuParcourHint != null)
			_gkMenuParcourHint.Visible = !canParcour;

		if (_gkMenuFrameLabel == null || _spawner == null || _camera == null)
			return;

		if (!canParcour)
		{
			_gkMenuFrameLabel.Text = "—";
			return;
		}

		var cur = _spawner.ResolveNearestFrameSeqFromCameraPosition(_camera.GlobalPosition);
		_gkMenuFrameLabel.Text = GkUiLocale.MenuFrameLine(cur, Spawner.FrameSlotCount);
	}

	private void OnGkMenuParcourPrev()
	{
		if (_spawner == null || _camera == null)
			return;
		var ctx = BridgeSpatial.ReadContextKey()?.Trim() ?? "";
		if (string.IsNullOrEmpty(ctx) || BridgeSpatial.IsObjectLocusKey(ctx))
			return;
		var cur = _spawner.ResolveNearestFrameSeqFromCameraPosition(_camera.GlobalPosition);
		_spawner.MoveCameraToParcourSeq(cur - 1);
		_viewer?.ClosePanel();
		RefreshGkMenuParcourUi();
	}

	private void OnGkMenuParcourNext()
	{
		if (_spawner == null || _camera == null)
			return;
		var ctx = BridgeSpatial.ReadContextKey()?.Trim() ?? "";
		if (string.IsNullOrEmpty(ctx) || BridgeSpatial.IsObjectLocusKey(ctx))
			return;
		var cur = _spawner.ResolveNearestFrameSeqFromCameraPosition(_camera.GlobalPosition);
		_spawner.MoveCameraToParcourSeq(cur + 1);
		_viewer?.ClosePanel();
		RefreshGkMenuParcourUi();
	}
}
