using System.IO;
using Godot;

public partial class FrameTemplate : Node3D
{
	/// <summary>
	/// Letterbox CPU sobre textura cuadrada. El marco usa <c>QuadMesh</c> (UV 0–1 en una cara); el antiguo <c>BoxMesh</c> partía el UV entre 6 caras y rompía la imagen.
	/// Pon <c>false</c> para prueba con textura cruda (estirada al cuadro).
	/// </summary>
	private const bool UseCpuLetterboxOnFrame = true;

	[Signal]
	public delegate void FrameSelectedEventHandler(string key);

	private string _key = "";
	private int _seq = 0;
	private Label3D _label;
	private StandardMaterial3D _materialTemplate;

	public void SetKey(string key)
	{
		_key = key;
		GD.Print($"[FRAME][SET_KEY] key={_key}");
		ApplyHeroMaterial();
	}

	/// <summary>Vuelve a leer disco (tras cambiar solo manifest/collage u otro asset sin snapshot).</summary>
	public void RefreshHeroFromDisk() => ApplyHeroMaterial();

	/// <summary>Índice de slot (0..19). Actualiza etiqueta espacial "Locus N" (N = seq + 1).</summary>
	public void SetSeq(int seq)
	{
		_seq = seq;
		UpdateLabel();
	}

	/// <summary>Key del locus asignada por snapshot (vacío = slot libre).</summary>
	public string GetLocusKey() => _key;

	private void UpdateLabel()
	{
		if (_label == null)
		{
			_label = new Label3D();
			_label.Name = "SpatialLabel";
			_label.PixelSize = 0.0125f;
			_label.Position = new Vector3(0f, 1.2f, 0.6f);
			_label.Billboard = BaseMaterial3D.BillboardModeEnum.Enabled;
			AddChild(_label);
		}

		_label.Text = $"Locus {_seq + 1}";
		_label.Modulate = new Color(1f, 0.88f, 0.55f);
	}

	public override void _Ready()
	{
		var mesh = GetNode<MeshInstance3D>("Mesh");
		if (mesh.MaterialOverride is StandardMaterial3D sm)
			_materialTemplate = (StandardMaterial3D)sm.Duplicate();

		var area = GetNode<Area3D>("ClickArea");
		area.Set("input_pickable", true);

		area.Monitoring = true;
		area.InputEvent += OnInputEvent;

		GD.Print("[FRAME][READY] ClickArea active");
		ApplyHeroMaterial();
	}

	private void ApplyHeroMaterial()
	{
		var mesh = GetNodeOrNull<MeshInstance3D>("Mesh");
		if (mesh == null)
			return;

		StandardMaterial3D mat;
		if (GodotObject.IsInstanceValid(_materialTemplate))
			mat = (StandardMaterial3D)_materialTemplate.Duplicate();
		else
		{
			mat = new StandardMaterial3D();
			mat.AlbedoColor = new Color(0.149f, 0.118f, 0.098f);
			mat.Metallic = 0.25f;
			mat.Roughness = 0.42f;
		}

		// QuadMesh: una sola cara delgada; sin culling doble el marco puede verse negro según el ángulo del pasillo.
		mat.CullMode = BaseMaterial3D.CullModeEnum.Disabled;

		var imgPath = AlexandriaAssets.FindFrameDisplayImagePath(_key);
		if (!string.IsNullOrEmpty(imgPath))
		{
			var image = new Image();
			if (image.Load(imgPath) == Error.Ok)
			{
				ImageTexture tex = null;
				if (UseCpuLetterboxOnFrame)
					tex = AlexandriaAssets.CreateSquareLetterboxedTexture(image);
				mat.AlbedoTexture = tex ?? ImageTexture.CreateFromImage(image);
				mat.AlbedoColor = Colors.White;
				mat.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
				mat.EmissionEnabled = false;
				try
				{
					var fi = new FileInfo(imgPath);
					GD.Print($"[FRAME][HERO] seq={_seq} key={_key} file={fi.Name} len={fi.Length} writeUtcTicks={fi.LastWriteTimeUtc.Ticks}");
				}
				catch
				{
					GD.Print($"[FRAME][IMG] {_key} ← {imgPath}");
				}
			}
			else
				GD.PrintErr($"[FRAME][IMG_LOAD_FAIL] {imgPath}");
		}
		else if (!string.IsNullOrEmpty(_key))
			GD.Print($"[FRAME][NO_ASSETS] key={_key} (sin carpeta o sin imágenes bajo data/assets)");

		mesh.MaterialOverride = mat;
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
