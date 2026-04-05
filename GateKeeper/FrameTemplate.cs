using Godot;
using System;

public partial class FrameTemplate : Node3D
{
	[Signal]
	public delegate void FrameSelectedEventHandler(string key);

	private string _key = "";
	private int _seq = 0;
	private Label3D _label;

	public void SetKey(string key)
	{
		_key = key;
		GD.Print($"[FRAME][SET_KEY] key={_key}");
	}

	/// <summary>Índice de slot (0..19). Actualiza etiqueta espacial "Locus N" (N = seq + 1).</summary>
	public void SetSeq(int seq)
	{
		_seq = seq;
		UpdateLabel();
	}

	private void UpdateLabel()
	{
		if (_label == null)
		{
			_label = new Label3D();
			_label.Name = "SpatialLabel";
			_label.PixelSize = 0.05f;
			_label.Position = new Vector3(0f, 1.2f, 0.6f);
			_label.Billboard = BaseMaterial3D.BillboardModeEnum.Enabled;
			AddChild(_label);
		}

		_label.Text = $"Locus {_seq + 1}";
	}

	public override void _Ready()
	{
		var area = GetNode<Area3D>("ClickArea");
		area.Set("input_pickable", true);

		area.Monitoring = true;
		area.InputEvent += OnInputEvent;

		GD.Print("[FRAME][READY] ClickArea active");
	}

	private void OnInputEvent(Node camera, InputEvent @event, Vector3 position, Vector3 normal, long shapeIdx)
	{
		if (@event is InputEventMouseButton mouse && mouse.Pressed)
		{
			BridgeSpatial.WriteCurrentSeq(_seq);
			GD.Print($"[FRAME_CLICK] seq={_seq} key={(string.IsNullOrEmpty(_key) ? "(empty)" : _key)}");

			EmitSignal(SignalName.FrameSelected, _key ?? "");
		}
	}
}
