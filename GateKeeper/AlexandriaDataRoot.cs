using System;
using System.IO;
using System.Linq;
using System.Text;
using Godot;

/// <summary>
/// Resuelve la carpeta de datos del **realm activo** (misma convención que LibraryBuild):
/// <c>data/active_realm.txt</c> → <c>data/realms/&lt;ruta relativa&gt;/</c> (p.ej. <c>default</c> o <c>Lab/proyecto</c>).
/// La raíz del repo no es fija: coincide con <c>alexandria_paths.dart</c> (env, <c>res://</c>, cwd, exe, default).
/// </summary>
public static class AlexandriaDataRoot
{
	/// <summary>
	/// Un único archivo en la raíz del repo (junto a <c>GateKeeper/</c>): primera línea = ruta absoluta.
	/// Lo escribe Library Build al arrancar para que GateKeeper use **la misma** raíz que Flutter.
	/// </summary>
	private const string RuntimeRootMarkerFileName = "alexandria_runtime_root.txt";

	private const string DefaultRepoRoot = @"C:\Alexandria";
	private static string _repoRootCache;
	private static readonly object RepoRootLock = new();

	/// <summary>Raíz del repo donde existe <c>data/realms/</c> (mismo criterio que <c>AlexandriaPaths.repoRoot</c> en Dart).</summary>
	public static string RepoRoot
	{
		get
		{
			if (_repoRootCache != null)
				return _repoRootCache;
			lock (RepoRootLock)
			{
				if (_repoRootCache != null)
					return _repoRootCache;
				_repoRootCache = ResolveRepoRoot();
				GD.Print($"[AlexandriaDataRoot] RepoRoot={_repoRootCache}");
				return _repoRootCache;
			}
		}
	}

	public static string ActiveRealmFile => Path.Combine(RepoRoot, "data", "active_realm.txt");

	private static string NormalizeRepoRoot(string raw)
	{
		var t = raw.Trim();
		if (string.IsNullOrEmpty(t))
			t = DefaultRepoRoot;
		try
		{
			return Path.GetFullPath(t);
		}
		catch
		{
			return Path.GetFullPath(DefaultRepoRoot);
		}
	}

	private static bool HasDataRealms(string repoRoot)
	{
		if (string.IsNullOrWhiteSpace(repoRoot))
			return false;
		try
		{
			var n = NormalizeRepoRoot(repoRoot);
			var realms = Path.Combine(n, "data", "realms");
			return Directory.Exists(realms);
		}
		catch
		{
			return false;
		}
	}

	/// <summary>
	/// Repo típico = carpeta que contiene <c>GateKeeper/</c> y <c>LibraryBuild/</c>, aunque aún no exista <c>data/realms/</c>.
	/// Evita caer siempre en <c>C:\Alexandria</c> y desincronizar GK respecto a LB.
	/// </summary>
	private static bool LooksLikeAlexandriaRepoRoot(string root)
	{
		if (string.IsNullOrWhiteSpace(root))
			return false;
		try
		{
			var n = NormalizeRepoRoot(root);
			var gk = Path.Combine(n, "GateKeeper");
			var lb = Path.Combine(n, "LibraryBuild");
			return Directory.Exists(gk) && Directory.Exists(lb);
		}
		catch
		{
			return false;
		}
	}

	private static string FindRepoRootBySiblingFolders(string startDir)
	{
		if (string.IsNullOrWhiteSpace(startDir))
			return null;
		try
		{
			var d = new DirectoryInfo(startDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
			for (var i = 0; i < 36 && d != null; i++)
			{
				if (LooksLikeAlexandriaRepoRoot(d.FullName))
					return NormalizeRepoRoot(d.FullName);
				d = d.Parent;
			}
		}
		catch
		{
		}
		return null;
	}

	private static string FindRepoRootWalkingUp(string startDir)
	{
		if (string.IsNullOrWhiteSpace(startDir))
			return null;
		try
		{
			var d = new DirectoryInfo(startDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
			for (var i = 0; i < 32 && d != null; i++)
			{
				if (HasDataRealms(d.FullName))
					return NormalizeRepoRoot(d.FullName);
				d = d.Parent;
			}
		}
		catch
		{
		}
		return null;
	}

	private static string TryReadRuntimeRootMarkerFile(string markerPath)
	{
		try
		{
			if (string.IsNullOrEmpty(markerPath))
			{
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.TryReadRuntimeRootMarkerFile", "markerPath empty");
				return null;
			}

			if (!File.Exists(markerPath))
			{
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.TryReadRuntimeRootMarkerFile",
					$"MISSING file={markerPath}");
				return null;
			}

			var line = File.ReadAllText(markerPath).Trim();
			if (string.IsNullOrEmpty(line))
			{
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.TryReadRuntimeRootMarkerFile",
					$"EMPTY first line file={markerPath}");
				return null;
			}

			var preview = line.Length > 200 ? line.Substring(0, 200) + "…" : line;
			var hasR = HasDataRealms(line);
			var looks = LooksLikeAlexandriaRepoRoot(line);
			if (hasR || looks)
			{
				var root = NormalizeRepoRoot(line);
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.TryReadRuntimeRootMarkerFile",
					$"OK file={markerPath} HasDataRealms={hasR} LooksLikeRepo={looks} normalized={root}");
				return root;
			}

			AppDiagnosticsLog.Trace("AlexandriaDataRoot.TryReadRuntimeRootMarkerFile",
				$"INVALID file={markerPath} linePreview={preview} HasDataRealms=false LooksLikeRepo=false");
			GD.PrintErr($"[AlexandriaDataRoot] marcador inválido (sin data/realms ni GateKeeper+LibraryBuild): {markerPath}");
		}
		catch (Exception e)
		{
			AppDiagnosticsLog.E("AlexandriaDataRoot.TryReadRuntimeRootMarkerFile", markerPath ?? "?", e);
			GD.PrintErr($"[AlexandriaDataRoot] marcador: {e.Message}");
		}
		return null;
	}

	/// <summary>Marcador junto al proyecto Godot: <c>…/alexandria_runtime_root.txt</c> (padre de <c>GateKeeper/</c>).</summary>
	private static string TryReadRuntimeRootMarkerBesideProject()
	{
		try
		{
			var res = ProjectSettings.GlobalizePath("res://");
			if (string.IsNullOrEmpty(res))
				return null;
			var gateKeeperDir = Path.GetFullPath(res.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
			var parent = Directory.GetParent(gateKeeperDir);
			if (parent == null)
				return null;
			var marker = Path.Combine(parent.FullName, RuntimeRootMarkerFileName);
			var root = TryReadRuntimeRootMarkerFile(marker);
			if (root != null)
				GD.Print($"[AlexandriaDataRoot] RepoRoot desde marcador LB ({marker}) → {root}");
			return root;
		}
		catch (Exception e)
		{
			GD.PrintErr($"[AlexandriaDataRoot] marcador proyecto: {e.Message}");
			return null;
		}
	}

	private static string TryReadRuntimeRootMarkerWalkingUp(string startDir)
	{
		if (string.IsNullOrWhiteSpace(startDir))
			return null;
		try
		{
			var d = new DirectoryInfo(startDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
			for (var i = 0; i < 32 && d != null; i++)
			{
				var marker = Path.Combine(d.FullName, RuntimeRootMarkerFileName);
				var root = TryReadRuntimeRootMarkerFile(marker);
				if (root != null)
				{
					GD.Print($"[AlexandriaDataRoot] RepoRoot desde marcador LB ({marker}) → {root}");
					return root;
				}
				d = d.Parent;
			}
		}
		catch
		{
		}
		return null;
	}

	private static string ResolveRepoRoot()
	{
		AppDiagnosticsLog.InitIfNeeded();
		string exeSafe = "";
		try
		{
			exeSafe = OS.GetExecutablePath() ?? "";
		}
		catch
		{
		}

		AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
			$"BEGIN cwd={System.Environment.CurrentDirectory} exe={exeSafe}");

		var env = System.Environment.GetEnvironmentVariable("ALEXANDRIA_ROOT")?.Trim();
		if (!string.IsNullOrEmpty(env))
		{
			var envHas = HasDataRealms(env);
			var envLooks = LooksLikeAlexandriaRepoRoot(env);
			AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
				$"ALEXANDRIA_ROOT=\"{env}\" HasDataRealms={envHas} LooksLikeRepo={envLooks}");
			if (envHas)
			{
				var r = NormalizeRepoRoot(env);
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot", $"CHOSEN=env HasDataRealms -> {r}");
				return r;
			}

			if (envLooks)
			{
				var r = NormalizeRepoRoot(env);
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot", $"CHOSEN=env LooksLikeRepo -> {r}");
				return r;
			}

			AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
				"ALEXANDRIA_ROOT rejected (no data/realms and not GateKeeper+LibraryBuild layout)");
		}
		else
			AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot", "ALEXANDRIA_ROOT unset");

		var fromMarker = TryReadRuntimeRootMarkerBesideProject();
		if (fromMarker != null)
		{
			AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
				$"CHOSEN=runtimeMarkerBesideProject -> {fromMarker}");
			return fromMarker;
		}

		try
		{
			var exe = OS.GetExecutablePath();
			if (!string.IsNullOrEmpty(exe))
			{
				var exeDir = Path.GetDirectoryName(exe);
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
					$"try runtime marker walking up from exeDir={exeDir}");
				var fromMarkerWalk = TryReadRuntimeRootMarkerWalkingUp(exeDir ?? ".");
				if (fromMarkerWalk != null)
				{
					AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
						$"CHOSEN=runtimeMarkerWalkFromExe -> {fromMarkerWalk}");
					return fromMarkerWalk;
				}
			}
		}
		catch (Exception e)
		{
			AppDiagnosticsLog.E("AlexandriaDataRoot.ResolveRepoRoot", "marcador exe", e);
			GD.PrintErr($"[AlexandriaDataRoot] marcador exe: {e.Message}");
		}

		try
		{
			var res = ProjectSettings.GlobalizePath("res://");
			if (!string.IsNullOrEmpty(res))
			{
				var trimmed = res.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot", $"res:// trimmed={trimmed}");
				var fromRes = FindRepoRootWalkingUp(trimmed);
				if (fromRes != null)
				{
					AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
						$"CHOSEN=walkUp(res has data/realms) -> {fromRes}");
					return fromRes;
				}

				var fromResSiblings = FindRepoRootBySiblingFolders(trimmed);
				if (fromResSiblings != null)
				{
					AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
						$"CHOSEN=siblingsFrom(res) -> {fromResSiblings}");
					return fromResSiblings;
				}
			}
		}
		catch (Exception e)
		{
			AppDiagnosticsLog.E("AlexandriaDataRoot.ResolveRepoRoot", "res://", e);
			GD.PrintErr($"[AlexandriaDataRoot] res://: {e.Message}");
		}

		try
		{
			var fromCwd = FindRepoRootWalkingUp(System.Environment.CurrentDirectory);
			if (fromCwd != null)
			{
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
					$"CHOSEN=walkUp(cwd) -> {fromCwd}");
				return fromCwd;
			}

			var fromCwdSiblings = FindRepoRootBySiblingFolders(System.Environment.CurrentDirectory);
			if (fromCwdSiblings != null)
			{
				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
					$"CHOSEN=siblingsFrom(cwd) -> {fromCwdSiblings}");
				return fromCwdSiblings;
			}
		}
		catch
		{
		}

		AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot", "cwd: no walkUp/siblings match");

		try
		{
			var exe = OS.GetExecutablePath();
			if (!string.IsNullOrEmpty(exe))
			{
				var exeDir = Path.GetDirectoryName(exe);
				var fromExe = FindRepoRootWalkingUp(exeDir);
				if (fromExe != null)
				{
					AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
						$"CHOSEN=walkUp(exeDir) -> {fromExe}");
					return fromExe;
				}

				var fromExeSiblings = FindRepoRootBySiblingFolders(exeDir);
				if (fromExeSiblings != null)
				{
					AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
						$"CHOSEN=siblingsFrom(exeDir) -> {fromExeSiblings}");
					return fromExeSiblings;
				}

				var dir = new DirectoryInfo(exeDir ?? ".");
				for (var i = 0; i < 28 && dir != null; i++)
				{
					var w = FindRepoRootWalkingUp(dir.FullName);
					if (w != null)
					{
						AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
							$"CHOSEN=walkUp(exe parent i={i}) -> {w}");
						return w;
					}

					var ws = FindRepoRootBySiblingFolders(dir.FullName);
					if (ws != null)
					{
						AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
							$"CHOSEN=siblingsFrom(exe parent i={i}) -> {ws}");
						return ws;
					}

					dir = dir.Parent;
				}

				AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
					"exe parent chain: exhausted without data/realms or sibling repo");
			}
		}
		catch (Exception e)
		{
			AppDiagnosticsLog.E("AlexandriaDataRoot.ResolveRepoRoot", "exe path", e);
			GD.PrintErr($"[AlexandriaDataRoot] exe path: {e.Message}");
		}

		if (HasDataRealms(DefaultRepoRoot))
		{
			var r = NormalizeRepoRoot(DefaultRepoRoot);
			AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
				$"CHOSEN=fallback DefaultRepoRoot (has data/realms) -> {r}");
			return r;
		}

		AppDiagnosticsLog.Trace("AlexandriaDataRoot.ResolveRepoRoot",
			"CHOSEN=fallback DefaultRepoRoot LAST RESORT (no marker/cwd/exe/realms match on this machine)");
		GD.PrintErr(
			"[AlexandriaDataRoot] No se encontró repo con data/realms ni carpeta GateKeeper+LibraryBuild; " +
			"usando fallback C:\\Alexandria (probable desajuste con Library Build). Define ALEXANDRIA_ROOT.");
		return NormalizeRepoRoot(DefaultRepoRoot);
	}

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
