using System;
using System.Collections.Generic;
using System.IO;
using Godot;

/// <summary>
/// [Cambio 353] Bridge espacial: GK escribe seq actual; LB escribe mapa por KEY.
/// </summary>
public static class BridgeSpatial
{
	public const string BridgeDir = @"C:\Alexandria\data\bridge";
	public const string CurrentSeqFile = "current_seq.txt";
	public const string LastPositionFile = "last_position.json";

	public static string CurrentSeqPath => Path.Combine(BridgeDir, CurrentSeqFile);
	public static string LastPositionPath => Path.Combine(BridgeDir, LastPositionFile);

	public static void WriteCurrentSeq(int seq)
	{
		try
		{
			Directory.CreateDirectory(BridgeDir);
			File.WriteAllText(CurrentSeqPath, seq.ToString());
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][SEQ_WRITE] " + e.Message);
		}
	}

	/// <summary>
	/// Lee last_position.json → seq guardado para [key], o null si no hay.
	/// Formato: { "byKey": { "KEY": 3 } }
	/// </summary>
	public static int? ReadSavedSeqForOpenKey(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return null;
		try
		{
			if (!File.Exists(LastPositionPath))
				return null;
			var text = File.ReadAllText(LastPositionPath);
			var json = new Json();
			if (json.Parse(text) != Error.Ok)
				return null;
			if (json.Data.VariantType != Variant.Type.Dictionary)
				return null;
			var root = json.Data.AsGodotDictionary();
			if (!root.ContainsKey("byKey"))
				return null;
			var byKey = root["byKey"].AsGodotDictionary();
			if (!byKey.ContainsKey(key))
				return null;
			var v = byKey[key];
			return v.VariantType switch
			{
				Variant.Type.Int => v.AsInt32(),
				Variant.Type.Float => (int)v.AsDouble(),
				_ => null,
			};
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][LAST_POS_READ] " + e.Message);
			return null;
		}
	}
}
