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

	/// <summary>ORM-15V3 Fase 2: nivel / snapshot parent (solo RealmController).</summary>
	public static void WriteContextKey(string key)
	{
		try
		{
			Directory.CreateDirectory(BridgeDir);
			File.WriteAllText(Path.Combine(BridgeDir, "context_key.txt"), key ?? "");
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][CONTEXT_WRITE] " + e.Message);
		}
	}

	/// <summary>ORM-15V3 Fase 2: entrada mostrada en viewer (solo RealmController).</summary>
	public static void WriteFocusKey(string key)
	{
		try
		{
			Directory.CreateDirectory(BridgeDir);
			File.WriteAllText(Path.Combine(BridgeDir, "focus_key.txt"), key ?? "");
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][FOCUS_WRITE] " + e.Message);
		}
	}

	/// <summary>Fase 4: lectura de context_key (sin open_key).</summary>
	public static string ReadContextKey()
	{
		try
		{
			var p = Path.Combine(BridgeDir, "context_key.txt");
			if (!File.Exists(p))
				return "";
			return File.ReadAllText(p).Trim();
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][CONTEXT_READ] " + e.Message);
			return "";
		}
	}

	/// <summary>Lectura de focus_key para resolver viewer por KEY (standalone runtime).</summary>
	public static string ReadFocusKey()
	{
		try
		{
			var p = Path.Combine(BridgeDir, "focus_key.txt");
			if (!File.Exists(p))
				return "";
			return File.ReadAllText(p).Trim();
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][FOCUS_READ] " + e.Message);
			return "";
		}
	}

	/// <summary>Último seq escrito por FrameTemplate (0..19 típico).</summary>
	public static int? ReadCurrentSeqOrNull()
	{
		try
		{
			if (!File.Exists(CurrentSeqPath))
				return null;
			if (!int.TryParse(File.ReadAllText(CurrentSeqPath).Trim(), out var s))
				return null;
			return s;
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][SEQ_READ] " + e.Message);
			return null;
		}
	}

	/// <summary>
	/// Lee last_position.json → seq guardado para [key] (p. ej. context_key al cambiar de nivel).
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
