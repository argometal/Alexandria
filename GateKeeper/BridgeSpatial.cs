using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using Godot;

/// <summary>
/// [Cambio 353] Bridge espacial: GK escribe seq actual; LB escribe mapa por KEY.
/// </summary>
public static class BridgeSpatial
{
	private static readonly Regex ObjectLocusKeySuffix = new Regex(@"_O\d{2}$", RegexOptions.Compiled);

	/// <summary>Hoja de objeto bajo parcour (p. ej. L1_O01). Usado para spawn y bridge seq.</summary>
	public static bool IsObjectLocusKey(string key) =>
		!string.IsNullOrEmpty(key) && ObjectLocusKeySuffix.IsMatch(key);

	public static string BridgeDir => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "bridge");
	public const string CurrentSeqFile = "current_seq.txt";
	public const string LastPositionFile = "last_position.json";
	public const string NavigationIntentFile = "navigation_intent.txt";

	public static string CurrentSeqPath => Path.Combine(BridgeDir, CurrentSeqFile);
	public static string LastPositionPath => Path.Combine(BridgeDir, LastPositionFile);

	public static string NavigationIntentPath => Path.Combine(BridgeDir, NavigationIntentFile);

	public const string PlaceRecallEnabledFile = "place_recall_enabled.txt";

	public static string PlaceRecallEnabledPath => Path.Combine(BridgeDir, PlaceRecallEnabledFile);

	/// <summary>Library Build writes <c>en</c>/<c>es</c>/<c>pt</c>; GateKeeper reads for HUD and F1 help.</summary>
	public const string GkUiLangFile = "gk_ui_lang.txt";

	public static string GkUiLangPath => Path.Combine(BridgeDir, GkUiLangFile);

	/// <summary>
	/// Place recall ON si línea 1 de <c>navigation_intent.txt</c> es <c>place_recall</c> (modo estudio),
	/// o si <c>place_recall_enabled.txt</c> sigue en <c>1</c> (compat. cajón LB).
	/// </summary>
	public static bool ReadPlaceRecallGloballyEnabled()
	{
		try
		{
			if (ReadNavigationIntentModeFirstLine() == "place_recall")
				return true;
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][PLACE_RECALL_INTENT] " + e.Message);
		}

		try
		{
			if (!File.Exists(PlaceRecallEnabledPath))
				return false;
			var t = File.ReadAllText(PlaceRecallEnabledPath).Trim();
			if (string.IsNullOrEmpty(t))
				return false;
			return t == "1"
				|| t.Equals("true", StringComparison.OrdinalIgnoreCase)
				|| t.Equals("yes", StringComparison.OrdinalIgnoreCase);
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][PLACE_RECALL_READ] " + e.Message);
			return false;
		}
	}

	/// <summary>Primera línea de <c>navigation_intent.txt</c> (explore / review / seek / drift / place_recall).</summary>
	public static string ReadNavigationIntentModeFirstLine()
	{
		try
		{
			if (!File.Exists(NavigationIntentPath))
				return "explore";
			var raw = File.ReadAllText(NavigationIntentPath).Trim();
			if (string.IsNullOrEmpty(raw))
				return "explore";
			var lines = raw.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
			if (lines.Length == 0)
				return "explore";
			var mode = lines[0].Trim().ToLowerInvariant();
			return string.IsNullOrEmpty(mode) ? "explore" : mode;
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][INTENT_MODE_READ] " + e.Message);
			return "explore";
		}
	}

	/// <summary>
	/// Modo de intención (explore / review / seek / drift) — LibraryBuild.
	/// Formato: línea 1 = modo; línea 2 opcional = clave del locus en foco (mismo objeto cuyo Hero ancla place/hint/ridiculous).
	/// HUD: RealmController muestra "Intent: modo · marco KEY" si hay segunda línea.
	/// </summary>
	public static string ReadNavigationIntent()
	{
		try
		{
			if (!File.Exists(NavigationIntentPath))
				return "explore";
			var raw = File.ReadAllText(NavigationIntentPath).Trim();
			if (string.IsNullOrEmpty(raw))
				return "explore";
			var lines = raw.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
			if (lines.Length == 0)
				return "explore";
			var mode = lines[0].Trim().ToLowerInvariant();
			if (string.IsNullOrEmpty(mode))
				return "explore";
			if (lines.Length >= 2)
			{
				var anchor = lines[1].Trim();
				if (!string.IsNullOrEmpty(anchor))
					return $"{mode} · frame {anchor}";
			}
			return mode;
		}
		catch (Exception e)
		{
			GD.PrintErr("[BRIDGE][INTENT_READ] " + e.Message);
			return "explore";
		}
	}

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
