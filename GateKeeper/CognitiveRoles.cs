public static class CognitiveRoles
{
	public const string Realm = "realm";
	public const string Parcour = "parcour";
	public const string Object = "object";

	/// <summary>
	/// Homologación GK/LB: ROOM legacy colapsa en OBJECT.
	/// </summary>
	public static string Normalize(string raw)
	{
		var s = (raw ?? "").Trim().ToLowerInvariant();
		if (s == "room")
			return Object;
		if (s == Realm || s == Parcour || s == Object)
			return s;
		return Object;
	}
}
