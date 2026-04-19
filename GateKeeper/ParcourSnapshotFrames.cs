using System;
using System.Collections.Generic;
using System.IO;
using Godot;

/// <summary>
/// Reads object locus keys from snapshot JSON files (no SQLite in GK).
/// Place recall: <b>strict</b> sibling pool = keys in <c>snapshot/{{parentKey}}.json</c> (same parent in LB).
/// Optional <b>relaxed</b> pool when the parent is the primary parcour only — see <see cref="LoadObjectKeysUnionFromAllSnapshotFiles"/>.
/// </summary>
public static class ParcourSnapshotFrames
{
	private static string SnapshotDir =>
		Path.Combine(AlexandriaDataRoot.RealmDataRoot, "snapshot");

	/// <summary>
	/// Object frame keys (e.g. *_O01) for one parent: <c>snapshot/{{parentKey}}.json</c>, or <c>current.json</c> fallback.
	/// This is the <b>strict sibling</b> set for place recall when the viewer entry’s parent is a non-parcour locus (e.g. Lk).
	/// </summary>
	public static List<string> LoadObjectKeysForParentSnapshot(string parentKey)
	{
		var keys = new List<string>();
		if (string.IsNullOrWhiteSpace(parentKey))
			return keys;

		var path = Path.Combine(SnapshotDir, parentKey.Trim() + ".json");
		if (!File.Exists(path))
		{
			path = Path.Combine(SnapshotDir, "current.json");
			if (!File.Exists(path))
				return keys;
		}

		var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		AppendObjectKeysFromSnapshotFile(path, set);
		foreach (var k in set)
			keys.Add(k);
		return keys;
	}

	/// <summary>
	/// Union of object keys appearing in every <c>*.json</c> under <c>snapshot/</c> (deduped).
	/// Used only for <b>relaxed</b> place recall when objects hang directly under the primary parcour
	/// so authors are not forced to place four object frames at that single level.
	/// </summary>
	public static List<string> LoadObjectKeysUnionFromAllSnapshotFiles()
	{
		var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		try
		{
			if (!Directory.Exists(SnapshotDir))
				return new List<string>();

			foreach (var path in Directory.GetFiles(SnapshotDir, "*.json"))
				AppendObjectKeysFromSnapshotFile(path, set);
		}
		catch (Exception e)
		{
			GD.PrintErr("[SNAPSHOT][UNION] " + e.Message);
		}

		var list = new List<string>(set.Count);
		foreach (var k in set)
			list.Add(k);
		return list;
	}

	private static void AppendObjectKeysFromSnapshotFile(string path, HashSet<string> into)
	{
		try
		{
			var text = File.ReadAllText(path);
			var json = new Json();
			if (json.Parse(text) != Error.Ok || json.Data.VariantType != Variant.Type.Dictionary)
				return;
			var data = json.Data.AsGodotDictionary();
			if (!data.ContainsKey("frames"))
				return;
			var frames = data["frames"].AsGodotArray();
			foreach (Variant f in frames)
			{
				if (f.VariantType != Variant.Type.Dictionary)
					continue;
				var d = f.AsGodotDictionary();
				if (!d.ContainsKey("key"))
					continue;
				var k = d["key"].AsString().Trim();
				if (string.IsNullOrEmpty(k) || !BridgeSpatial.IsObjectLocusKey(k))
					continue;
				into.Add(k);
			}
		}
		catch (Exception e)
		{
			GD.PrintErr("[SNAPSHOT][FRAMES] " + path + " " + e.Message);
		}
	}
}
