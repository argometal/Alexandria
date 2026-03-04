using Godot;

public partial class CameraRig : Node3D
{
	[Export] public float Speed = 5f;
	[Export] public float MouseSensitivity = 0.002f;

	private float _yaw = 0f;

	public override void _Ready()
	{
		Input.MouseMode = Input.MouseModeEnum.Captured;
		// [SCOPE:PASSIVE_RIG] sin loops ni input
		SetProcess(false);
		SetProcessInput(false);
	}


// [SCOPE:INPUT_REMOVED] CameraRig sin input directo

// [SCOPE:AUTO_MOVE_REMOVED] Movimiento solo vía RealmController

// INPUT REMOVED — CONTROLLED BY REALMCONTROLLER

	public void MoveForward(float delta)
	{
		var dir = GlobalTransform.Basis.Z;
		GlobalTranslate(dir * Speed * delta);
	
		// GD.Print("[CAMERA][MOVE_FORWARD]");
	}

	public void MoveRight(float delta)
	{
		var dir = -GlobalTransform.Basis.X;
		GlobalTranslate(dir * Speed * delta);
		// GD.Print("[CAMERA][MOVE_RIGHT]");
	}

	public void RotateYaw(float delta)
	{
		_yaw -= delta * MouseSensitivity;
		RotateY(-delta * MouseSensitivity);
		// GD.Print("[CAMERA][ROTATE]");
	}
}
