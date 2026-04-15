using Godot;
using System;
using System.Collections.Generic;
using System.IO;

public partial class RealmController : Node
{
	[Signal]
	public delegate void FrameSelectedEventHandler(string key);

	// [SCOPE:CAMERA_CONTROL]
	private CameraRig _camera;
	private Spawner _spawner;
	private ViewerService _viewer;
	private Label _intentHud = null!;
	private double _intentPoll;
	private double _bridgeSeqSyncTimer;
	private int _lastBridgeSeqWritten = -999;
	private string _lastRealmIdForSessionSeq = "";

	/// <summary>
	/// Historial de foco dentro del viewer (enlaces / tarjetas): Back restaura el foco anterior sin cambiar context_key.
	/// </summary>
	private readonly Stack<string> _viewerFocusStack = new();

	public override void _Ready()
	{
		GD.Print("[RC][INIT]");

		_camera = GetNode<CameraRig>("/root/Realm/CameraRig");
		_spawner = GetNodeOrNull<Spawner>("/root/Realm/Spawner");
		_viewer = GetNodeOrNull<ViewerService>("/root/Realm/ViewerService");
		if (_viewer != null)
		{
			_viewer.EnterLevelRequested += OnEnterLevelRequested;
			_viewer.FocusKeyNavigationRequested += ApplyFocusOnlyFromViewer;
			_viewer.BackLevelRequested += OnViewerBackWithFocusStack;
		}
		GD.Print(_camera == null ? "[RC][CAMERA NULL]" : "[RC][CAMERA OK]");
		GD.Print(_viewer == null ? "[RC][VIEWER NULL] path=/root/Realm/ViewerService" : "[RC][VIEWER OK]");
		Input.MouseMode = Input.MouseModeEnum.Captured;

		var hudLayer = new CanvasLayer();
		hudLayer.Layer = 30;
		AddChild(hudLayer);
		var hudRoot = new Control();
		hudRoot.SetAnchorsPreset(Control.LayoutPreset.FullRect);
		hudRoot.MouseFilter = Control.MouseFilterEnum.Ignore;
		hudLayer.AddChild(hudRoot);
		_intentHud = new Label();
		_intentHud.HorizontalAlignment = HorizontalAlignment.Right;
		_intentHud.SetAnchorsPreset(Control.LayoutPreset.TopRight);
		_intentHud.OffsetLeft = -400f;
		_intentHud.OffsetTop = 10f;
		_intentHud.OffsetRight = -12f;
		_intentHud.OffsetBottom = 36f;
		_intentHud.Text = "Intent: " + BridgeSpatial.ReadNavigationIntent();
		hudRoot.AddChild(_intentHud);

		SetupGkHudMenu(hudRoot);
		SetupGkUserHelp();

		SetProcess(true);
		SetProcessInput(true);
		SetProcessUnhandledInput(true);
	}

	public void OnFrameSelected(string key)
	{
		GD.Print($"[RC][EVENT] FrameSelected key={key}");
		ApplyFocusOnlyFromViewer(key ?? "");
	}

	/// <summary>
	/// Clic en frame o link en viewer: solo focus_key; no cambia context_key (Fase 4 — sin open/active).
	/// EMPTY permitido — alineado ORM-15V3 (seq ya escribe FrameTemplate).
	/// </summary>
	private void ApplyFocusOnlyFromViewer(string key)
	{
		var k = key ?? "";
		GD.Print($"[RC][FOCUS] key={(string.IsNullOrEmpty(k) ? "(empty)" : k)}");

		try
		{
			Directory.CreateDirectory(BridgeSpatial.BridgeDir);
			var prev = BridgeSpatial.ReadFocusKey().Trim();
			var next = k.Trim();
			if (!string.IsNullOrEmpty(prev) && !string.IsNullOrEmpty(next) &&
				!string.Equals(prev, next, StringComparison.Ordinal))
				_viewerFocusStack.Push(prev);

			BridgeSpatial.WriteFocusKey(k);
		}
		catch (Exception e)
		{
			GD.PrintErr("[RC][BRIDGE_ERR] " + e.Message);
			return;
		}

		GD.Print(string.IsNullOrEmpty(k)
			? "[RC][BRIDGE_WRITE] focus_key=(empty)"
			: "[RC][BRIDGE_WRITE] focus_key=" + k);

		_viewer?.NotifyFrameOpened(k);
	}

	private void OnEnterLevelRequested(string key)
	{
		if (string.IsNullOrEmpty(key))
			return;

		_viewerFocusStack.Clear();

		try
		{
			Directory.CreateDirectory(BridgeSpatial.BridgeDir);
			BridgeSpatial.WriteContextKey(key);
			BridgeSpatial.WriteFocusKey(key);

			var refreshPath = Path.Combine(BridgeSpatial.BridgeDir, "refresh_now.txt");
			File.WriteAllText(refreshPath, "1");
		}
		catch (Exception e)
		{
			GD.PrintErr("[RC][WARP_ERR] " + e.Message);
			return;
		}

		GD.Print($"[RC][WARP] context_key={key} focus_key={key}");
		_viewer?.ClosePanel();
	}

	/// <summary>Back del viewer: primero deshace navegaciones de foco; si no hay pila, sube de nivel.</summary>
	private void OnViewerBackWithFocusStack(string hierarchyTarget)
	{
		if (_viewerFocusStack.Count > 0)
		{
			var prevFocus = _viewerFocusStack.Pop();
			try
			{
				Directory.CreateDirectory(BridgeSpatial.BridgeDir);
				BridgeSpatial.WriteFocusKey(prevFocus);
			}
			catch (Exception e)
			{
				GD.PrintErr("[RC][FOCUS_BACK_ERR] " + e.Message);
				return;
			}

			GD.Print($"[RC][FOCUS_BACK] focus_key={prevFocus}");
			_viewer?.NotifyFrameOpened(prevFocus);
			return;
		}

		OnBackLevelRequested(hierarchyTarget);
	}

	private void OnBackLevelRequested(string parentKey)
	{
		if (string.IsNullOrEmpty(parentKey))
			return;

		_viewerFocusStack.Clear();

		try
		{
			Directory.CreateDirectory(BridgeSpatial.BridgeDir);
			BridgeSpatial.WriteContextKey(parentKey);
			BridgeSpatial.WriteFocusKey(parentKey);
			var refreshPath = Path.Combine(BridgeSpatial.BridgeDir, "refresh_now.txt");
			File.WriteAllText(refreshPath, "1");
		}
		catch (Exception e)
		{
			GD.PrintErr("[RC][BACK_ERR] " + e.Message);
			return;
		}

		GD.Print($"[RC][BACK] context_key={parentKey} focus_key={parentKey}");
		_viewer?.ClosePanel();
	}

	
	public override void _Input(InputEvent @event)
	{
		// [TRACE][RC][INPUT_EVENT]
		// GD.Print("[RC][INPUT_EVENT]");

		if (_camera == null)
		{
			GD.PrintErr("[RC][FAIL][CAMERA_NULL]");
			return;
		}

		if (@event is InputEventKey f1 && f1.Pressed && !f1.Echo && f1.Keycode == Key.F1)
		{
			if (_gkMenuOpen)
				SetGkMenuVisible(false);
			ToggleGkUserHelp();
			GetViewport().SetInputAsHandled();
			return;
		}

		if (@event is InputEventKey esc && esc.Pressed && !esc.Echo && esc.Keycode == Key.Escape)
		{
			if (_gkHelpOpen)
			{
				ToggleGkUserHelp();
				GetViewport().SetInputAsHandled();
				return;
			}

			if (_gkMenuOpen)
			{
				SetGkMenuVisible(false);
				GetViewport().SetInputAsHandled();
				return;
			}

			if (Input.MouseMode == Input.MouseModeEnum.Captured)
				Input.MouseMode = Input.MouseModeEnum.Visible;
			else
				Input.MouseMode = Input.MouseModeEnum.Captured;
			return;
		}

		if (_gkHelpOpen || _gkMenuOpen)
			return;

		if (@event is InputEventMouseMotion motion)
		{
			if (Input.MouseMode != Input.MouseModeEnum.Captured)
				return;

			_camera.RotateYaw((float)motion.Relative.X);
		}
	}

	public override void _Process(double delta)
	{
		// [TRACE][RC][PROCESS_ALIVE]
		// GD.Print("[RC][PROCESS_ALIVE]");

		if (_camera == null)
		{
			GD.PrintErr("[RC][FAIL][CAMERA_NULL_PROCESS]");
			return;
		}

		// Parcour: memoria de sesión por realm (no disco). Object: no actualiza seq (no pisar parcour al visitar objeto).
		_bridgeSeqSyncTimer += delta;
		if (_bridgeSeqSyncTimer >= 0.25)
		{
			_bridgeSeqSyncTimer = 0;
			if (_spawner != null)
			{
				var realmId = AlexandriaDataRoot.ReadActiveRealmId();
				if (realmId != _lastRealmIdForSessionSeq)
				{
					_lastRealmIdForSessionSeq = realmId;
					_lastBridgeSeqWritten = -999;
				}

				var ctx = BridgeSpatial.ReadContextKey()?.Trim() ?? "";
				if (!string.IsNullOrEmpty(ctx) && !BridgeSpatial.IsObjectLocusKey(ctx))
				{
					var nearest = _spawner.ResolveNearestFrameSeqFromCameraPosition(_camera.GlobalPosition);
					if (nearest != _lastBridgeSeqWritten)
					{
						_lastBridgeSeqWritten = nearest;
						SessionRealmSpatial.SetParcourSeqForRealm(realmId, nearest);
					}
				}
			}
		}

		// _camera.RotateYaw(1f); // [SCOPE:DEBUG_ROTATION_REMOVED]

		if (Input.MouseMode != Input.MouseModeEnum.Captured)
			return;

		if (Input.IsActionPressed("ui_up"))
			_camera.MoveForward((float)delta);

		if (Input.IsActionPressed("ui_down"))
			_camera.MoveForward(-(float)delta);

		if (Input.IsActionPressed("ui_right"))
			_camera.MoveRight((float)delta);

		if (Input.IsActionPressed("ui_left"))
			_camera.MoveRight(-(float)delta);

		_intentPoll += delta;
		if (_intentPoll >= 0.35)
		{
			_intentPoll = 0;
			if (_intentHud != null)
				_intentHud.Text = "Intent: " + BridgeSpatial.ReadNavigationIntent();
		}
	}


}
