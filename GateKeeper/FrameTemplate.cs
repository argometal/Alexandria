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

		// FrameSelected se conecta desde Spawner por frame (evita doble OnFrameSelected).

		GD.Print("[FRAME][READY] ClickArea active");
	}

	private void OnInputEvent(Node camera, InputEvent @event, Vector3 position, Vector3 normal, long shapeIdx)
	{
		if (@event is InputEventMouseButton mouse && mouse.Pressed)
		{
			// Un solo punto de decisión: RealmController (evita [FRAME][BLOCK] duplicado).
			GD.Print(string.IsNullOrEmpty(_key)
				? "[FRAME][CLICK] empty slot (forwarding to RC)"
				: $"[FRAME][CLICK] key={_key}");

			EmitSignal(SignalName.FrameSelected, _key ?? "");
		}
	}
}
