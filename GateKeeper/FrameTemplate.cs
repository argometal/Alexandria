using Godot;
using System;

public partial class FrameTemplate : Node3D
{
	[Signal]
	public delegate void FrameSelectedEventHandler(string key);

	private string _key = "";

	public void SetKey(string key)
	{
		_key = key;
		GD.Print($"[FRAME][SET_KEY] key={_key}");
	}

	public override void _Ready()
	{
		var area = GetNode<Area3D>("ClickArea");
		area.Set("input_pickable", true);

		area.Monitoring = true;
		area.InputEvent += OnInputEvent;

		// [SCOPE:REALM_LINK]
		// [FIX][A15] ruta correcta dentro de Realm
		var realm = GetNode<RealmController>("/root/Realm/RealmController");
		this.FrameSelected += realm.OnFrameSelected;

		GD.Print("[FRAME][READY] ClickArea active");
	}

	private void OnInputEvent(Node camera, InputEvent @event, Vector3 position, Vector3 normal, long shapeIdx)
	{
		if (@event is InputEventMouseButton mouse && mouse.Pressed)
		{

			if (string.IsNullOrEmpty(_key))
			{
				GD.PrintErr("[FRAME][BLOCK] EMPTY CLICK");
				return;
			}

			GD.Print($"[FRAME][CLICK] key={_key}");

			EmitSignal(SignalName.FrameSelected, _key);

		}
	}
}
