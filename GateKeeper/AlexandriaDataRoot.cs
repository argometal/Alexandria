using System;
using System.IO;
using System.Text;

/// <summary>
/// Resuelve la carpeta de datos del **realm activo** (misma convención que LibraryBuild):
/// <c>data/active_realm.txt</c> → <c>data/realms/&lt;id&gt;/</c>.
/// </summary>
public static class AlexandriaDataRoot
{
	public const string RepoRoot = @"C:\Alexandria";
	public static readonly string ActiveRealmFile = Path.Combine(RepoRoot, "data", "active_realm.txt");

	/// <summary>Alineado con <c>alexandria_paths.dart</c>: <c>[a-zA-Z0-9_.-]</c>.</summary>
	public static string SanitizeRealmId(string raw)
	{
		if (string.IsNullOrWhiteSpace(raw))
			return "default";
		var t = raw.Trim();
		var sb = new StringBuilder();
		foreach (var c in t)
		{
			if (char.IsLetterOrDigit(c) || c == '_' || c == '.' || c == '-')
				sb.Append(c);
			else
				sb.Append('_');
		}
		t = sb.ToString();
		if (t.Length == 0 || t == "." || t == "..")
			return "default";
		return t;
	}

	public static string ReadActiveRealmId()
	{
		try
		{
			if (!File.Exists(ActiveRealmFile))
				return "default";
			var t = File.ReadAllText(ActiveRealmFile).Trim();
			return string.IsNullOrEmpty(t) ? "default" : SanitizeRealmId(t);
		}
		catch
		{
			return "default";
		}
	}

	/// <summary>Directorio raíz del realm activo: <c>data/realms/&lt;id&gt;/</c>.</summary>
	public static string RealmDataRoot => Path.Combine(RepoRoot, "data", "realms", ReadActiveRealmId());
}
