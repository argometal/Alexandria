using Godot;
#nullable enable

using System;

public partial class CameraRig : Node3D
{
	[Export] public float Speed { get; set; } = 6.0f;
	[Export] public float MouseSensitivity { get; set; } = 0.002f;

	private float _yaw = 0.0f;
	private float _pitch = 0.0f;
	private Camera3D? _camera;

	public override void _Ready()
	{
		_camera = GetNode<Camera3D>("Camera3D");

		Input.MouseMode = Input.MouseModeEnum.Captured;

		_yaw = Rotation.Y;
		_pitch = _camera.Rotation.X;

		GD.Print("MOVE READY");
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent &&
			keyEvent.Pressed &&
			keyEvent.Keycode == Key.Escape)
		{
			Input.MouseMode =
				Input.MouseMode == Input.MouseModeEnum.Captured
				? Input.MouseModeEnum.Visible
				: Input.MouseModeEnum.Captured;
			return;
		}

		if (@event is InputEventMouseMotion mouseMotion &&
			Input.MouseMode == Input.MouseModeEnum.Captured)
		{
			_yaw -= (float)mouseMotion.Relative.X * MouseSensitivity;
			_pitch -= (float)mouseMotion.Relative.Y * MouseSensitivity;

			_pitch = Mathf.Clamp(_pitch, Mathf.DegToRad(-70.0f), Mathf.DegToRad(70.0f));

			Rotation = new Vector3(Rotation.X, _yaw, Rotation.Z);

			if (_camera != null)
				_camera.Rotation = new Vector3(_pitch, _camera.Rotation.Y, _camera.Rotation.Z);
		}
	}

	public override void _Process(double delta)
	{
		Vector3 input = Vector3.Zero;

		if (Input.IsActionPressed("ui_up")) input.Z -= 1;
		if (Input.IsActionPressed("ui_down")) input.Z += 1;
		if (Input.IsActionPressed("ui_left")) input.X -= 1;
		if (Input.IsActionPressed("ui_right")) input.X += 1;

		if (input == Vector3.Zero)
			return;

		Vector3 fwd = new Vector3(Mathf.Sin(_yaw), 0, Mathf.Cos(_yaw));
		Vector3 right = new Vector3(Mathf.Cos(_yaw), 0, -Mathf.Sin(_yaw));

		Vector3 dir = (right * input.X + fwd * input.Z).Normalized();
		GlobalPosition += dir * Speed * (float)delta;
	}
}
