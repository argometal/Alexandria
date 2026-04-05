using Godot;
using System;



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

		// acción mínima (expandiremos después)
		HandleSelect(key);
	}

	private void HandleSelect(string key)
	{
		GD.Print($"[RC][ACTION] select key={(string.IsNullOrEmpty(key) ? "(empty)" : key)}");

		var bridge = @"C:\Alexandria\data\bridge";
		try
		{
			System.IO.Directory.CreateDirectory(bridge);
			var k = key ?? "";
			System.IO.File.WriteAllText(System.IO.Path.Combine(bridge, "active_key.txt"), k);
			System.IO.File.WriteAllText(System.IO.Path.Combine(bridge, "open_key.txt"), k);
		}
		catch (Exception e)
		{
			GD.PrintErr("[RC][BRIDGE_ERR] " + e.Message);
			return;
		}

		GD.Print(string.IsNullOrEmpty(key)
			? "[RC][BRIDGE_WRITE] open_key=(empty) active_key=(empty)"
			: "[RC][BRIDGE_WRITE] open_key=" + key + " active_key=" + key);

		_viewer?.NotifyFrameOpened(key ?? "");
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
