using Godot;
using System;



public partial class RealmController : Node
{
	[Signal]
	public delegate void FrameSelectedEventHandler(string key);

	// [SCOPE:CAMERA_CONTROL]
	private CameraRig _camera;

	public override void _Ready()
	{
		GD.Print("[RC][INIT]");

		_camera = GetNode<CameraRig>("/root/Realm/CameraRig");
		GD.Print(_camera == null ? "[RC][CAMERA NULL]" : "[RC][CAMERA OK]");
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

				
		GD.Print($"[RC][ACTION] select key={key}");

		if (string.IsNullOrEmpty(key))
		{
			GD.Print("[RC][BLOCK] EMPTY click ignored");
			return;
		}

		// [A15][BRIDGE_WRITE]
		var bridgePath = @"C:\Alexandria\data\bridge\";

		System.IO.File.WriteAllText(bridgePath + "open_key.txt", key);
		System.IO.File.WriteAllText(bridgePath + "active_key.txt", key);

		// [A15][REMOVED] GK no dispara refresh

	


		try
		{

			string bridge = @"C:\Alexandria\data\bridge";

			string active = System.IO.Path.Combine(bridge, "active_key.txt");
			System.IO.File.WriteAllText(active, key);

			GD.Print("[RC][BRIDGE_WRITE] active_key=" + key);
		}
		catch (Exception e)
		{
			GD.PrintErr("[RC][BRIDGE_ERR] " + e.Message);
		}
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
