using Godot;
using System;
using System.IO;

public partial class RealmController : Node
{
	[Signal]
	public delegate void FrameSelectedEventHandler(string key);

	// [SCOPE:CAMERA_CONTROL]
	private CameraRig _camera;
	private ViewerService _viewer;

	public override void _Ready()
	{
		GD.Print("[RC][INIT]");

		_camera = GetNode<CameraRig>("/root/Realm/CameraRig");
		_viewer = GetNodeOrNull<ViewerService>("/root/Realm/ViewerService");
		if (_viewer != null)
		{
			_viewer.EnterLevelRequested += OnEnterLevelRequested;
			_viewer.FocusKeyNavigationRequested += ApplyFocusOnlyFromViewer;
			_viewer.BackLevelRequested += OnBackLevelRequested;
		}
		GD.Print(_camera == null ? "[RC][CAMERA NULL]" : "[RC][CAMERA OK]");
		GD.Print(_viewer == null ? "[RC][VIEWER NULL] path=/root/Realm/ViewerService" : "[RC][VIEWER OK]");
		Input.MouseMode = Input.MouseModeEnum.Captured;

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

	private void OnBackLevelRequested(string parentKey)
	{
		if (string.IsNullOrEmpty(parentKey))
			return;

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

		if (@event is InputEventMouseMotion motion)
		{
			if (Input.MouseMode != Input.MouseModeEnum.Captured)
				return;

			_camera.RotateYaw((float)motion.Relative.X);
		}

		if (@event is InputEventKey key && key.Pressed && key.Keycode == Key.Escape)
		{
			if (Input.MouseMode == Input.MouseModeEnum.Captured)
			{
				Input.MouseMode = Input.MouseModeEnum.Visible;
				// GD.Print("[RC][ESC_RELEASE_MOUSE]");
			}
			else
			{
				Input.MouseMode = Input.MouseModeEnum.Captured;
				// GD.Print("[RC][ESC_CAPTURE_MOUSE]");
			}
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

	}


}
