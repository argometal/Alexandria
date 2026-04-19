using System;
using System.Collections.Generic;

/// <summary>
/// Runtime-only unlock map for place recall (hero blur gate). Cleared when GateKeeper exits.
/// </summary>
public static class PlaceRecallSessionState
{
	private static readonly HashSet<string> UnlockedKeys =
		new(StringComparer.OrdinalIgnoreCase);

	public static bool IsUnlocked(string entryKey)
	{
		if (string.IsNullOrWhiteSpace(entryKey))
			return false;
		return UnlockedKeys.Contains(entryKey.Trim());
	}

	public static void Unlock(string entryKey)
	{
		if (string.IsNullOrWhiteSpace(entryKey))
			return;
		UnlockedKeys.Add(entryKey.Trim());
	}

	public static void ClearSession()
	{
		UnlockedKeys.Clear();
	}
}
