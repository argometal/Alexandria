using Godot;

/// <summary>
/// Paleta compartida suelo/techo del corredor (oliva cálido, acorde con piedra y marcos dorados).
/// Debe coincidir con <c>segment/FloorScene.tscn</c>, <c>CeilingScene.tscn</c> y el suelo/techo en <c>env/raz_environment.tres</c> (cielo procedural).
/// </summary>
public static class CorridorVisualTheme
{
	public static readonly Color FloorOlive = new(0.302f, 0.278f, 0.212f);
	public static readonly Color CeilingOlive = new(0.208f, 0.204f, 0.165f);

	public const float FloorRoughness = 0.92f;
	public const float CeilingRoughness = 0.88f;

	public static StandardMaterial3D CreateFloorMaterial()
	{
		var m = new StandardMaterial3D();
		m.AlbedoColor = FloorOlive;
		m.Roughness = FloorRoughness;
		return m;
	}

	public static StandardMaterial3D CreateCeilingMaterial()
	{
		var m = new StandardMaterial3D();
		m.AlbedoColor = CeilingOlive;
		m.Roughness = CeilingRoughness;
		return m;
	}

	/// <summary>Aplica material oliva al <c>Mesh</c> hijo típico de Floor/CeilingScene.</summary>
	public static void ApplyToFloorCeilingSegment(Node3D segmentRoot, bool ceiling)
	{
		var mesh = segmentRoot.GetNodeOrNull<MeshInstance3D>("Mesh");
		if (mesh == null)
			return;
		mesh.MaterialOverride = ceiling ? CreateCeilingMaterial() : CreateFloorMaterial();
	}
}
