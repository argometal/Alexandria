using System;
using System.IO;
using System.Linq;
using System.Text;

/// <summary>
/// Resuelve la carpeta de datos del **realm activo** (misma convención que LibraryBuild):
/// <c>data/active_realm.txt</c> → <c>data/realms/&lt;ruta relativa&gt;/</c> (p.ej. <c>default</c> o <c>Lab/proyecto</c>).
/// </summary>
public static class AlexandriaDataRoot
{
	public const string RepoRoot = @"C:\Alexandria";
	public static readonly string ActiveRealmFile = Path.Combine(RepoRoot, "data", "active_realm.txt");

	/// <summary>Alineado con <c>alexandria_paths.dart</c>: <c>[a-zA-Z0-9_.-]</c> por segmento.</summary>
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

	/// <summary>Ruta bajo <c>data/realms/</c>: uno o más segmentos separados por <c>/</c>.</summary>
	public static string SanitizeRealmPath(string raw)
	{
		if (string.IsNullOrWhiteSpace(raw))
			return "default";
		var segments = raw.Replace('\\', '/').Split('/', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
		if (segments.Length == 0)
			return "default";
		var parts = new System.Collections.Generic.List<string>();
		foreach (var s in segments)
		{
			var id = SanitizeRealmId(s);
			if (!string.IsNullOrEmpty(id))
				parts.Add(id);
		}
		if (parts.Count == 0)
			return "default";
		return string.Join("/", parts);
	}

	public static string ReadActiveRealmId()
	{
		try
		{
			if (!File.Exists(ActiveRealmFile))
				return "default";
			var t = File.ReadAllText(ActiveRealmFile).Trim();
			return string.IsNullOrEmpty(t) ? "default" : SanitizeRealmPath(t);
		}
		catch
		{
			return "default";
		}
	}

	/// <summary>Directorio raíz del realm activo: <c>data/realms/&lt;segmentos…&gt;/</c>.</summary>
	public static string RealmDataRoot
	{
		get
		{
			var rel = ReadActiveRealmId();
			var segments = rel.Split('/', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
			var parts = new[] { RepoRoot, "data", "realms" }.Concat(segments).ToArray();
			return Path.Combine(parts);
		}
	}
}
