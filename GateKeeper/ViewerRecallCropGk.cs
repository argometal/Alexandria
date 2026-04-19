using System;
using System.IO;
using Godot;

/// <summary>
/// Reads <c>recall_crop</c> image src from <c>viewer/{{key}}.json</c> (body blocks) for GateKeeper visuals.
/// </summary>
public static class ViewerRecallCropGk
{
	public static string TryReadRecallCropSrc(string realmDataRoot, string objectKey)
	{
		var path = Path.Combine(realmDataRoot, "viewer", objectKey + ".json");
		if (!File.Exists(path))
			return "";
		try
		{
			var text = File.ReadAllText(path);
			var json = new Json();
			if (json.Parse(text) != Error.Ok || json.Data.VariantType != Variant.Type.Dictionary)
				return "";
			var data = json.Data.AsGodotDictionary();
			if (data.ContainsKey("recallCropSrc"))
			{
				var top = data["recallCropSrc"].AsString().Trim();
				if (!string.IsNullOrEmpty(top))
					return top;
			}

			if (data.ContainsKey("recall_crop"))
			{
				var top = data["recall_crop"].AsString().Trim();
				if (!string.IsNullOrEmpty(top))
					return top;
			}

			if (!data.ContainsKey("body"))
				return "";
			var body = data["body"].AsGodotArray();
			foreach (Variant item in body)
			{
				if (item.VariantType != Variant.Type.Dictionary)
					continue;
				var d = item.AsGodotDictionary();
				var type = d.ContainsKey("type") ? d["type"].AsString() : "p";
				if (type != "img")
					continue;
				var role = d.ContainsKey("role") ? d["role"].AsString().ToLowerInvariant() : "";
				if (role != "recall_crop")
					continue;
				var src = d.ContainsKey("src") ? d["src"].AsString().Trim() : "";
				if (!string.IsNullOrEmpty(src))
					return src;
			}
		}
		catch (Exception e)
		{
			GD.PrintErr("[VIEWER_RECALL_CROP] " + e.Message);
		}

		return "";
	}
}
