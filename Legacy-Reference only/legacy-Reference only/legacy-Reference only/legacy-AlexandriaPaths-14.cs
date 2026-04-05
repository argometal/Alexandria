using System;
using System.IO;

public static class AlexandriaPaths
{
	public static string GetRoot()
	{
		// [CHANGE 89] Unified runtime root for Godot + Flutter.
		// All runtime data must live here:
		//   C:\Alexandria\data
		// This avoids reading stale data from APPDATA or local exe/data folders.
		return @"C:\Alexandria\data";
	}

	public static string GetDbPath()
	{
		return Path.Combine(GetRoot(), "alexandria.db");
	}

	public static string GetAssetsRoot()
	{
		return Path.Combine(GetRoot(), "assets");
	}

	public static string GetBridgeRoot()
	{
		return Path.Combine(GetRoot(), "bridge");
	}

	public static void EnsureBridge()
	{
		string bridge = GetBridgeRoot();
		if (!Directory.Exists(bridge))
			Directory.CreateDirectory(bridge);
	}
}