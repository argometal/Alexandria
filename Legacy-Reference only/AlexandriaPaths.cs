using System;
using System.IO;

public static class AlexandriaPaths
{
	public static string GetRoot()
	{
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