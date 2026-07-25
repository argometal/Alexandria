using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using Godot;

/// <summary>
/// Misma lógica que <c>AlexandriaSiblingApps</c> en Flutter: bundle (CREAR-APP) o repo dev con <c>data/realms</c>.
/// </summary>
public static class SiblingApps
{
	public enum Kind
	{
		GateKeeper,
		LibraryBuild,
		TrainingLab,
	}

	public static bool TryLaunch(Kind kind)
	{
		var path = ResolveAll()[kind];
		if (string.IsNullOrEmpty(path) || !File.Exists(path))
			return false;
		try
		{
			var dir = Path.GetDirectoryName(path);
			Process.Start(new ProcessStartInfo
			{
				FileName = path,
				WorkingDirectory = string.IsNullOrEmpty(dir) ? System.Environment.CurrentDirectory : dir,
				UseShellExecute = true,
			});
			return true;
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[SiblingApps] {ex.Message}");
			return false;
		}
	}

	public static IReadOnlyDictionary<Kind, string?> ResolveAll()
	{
		var empty = new Dictionary<Kind, string?>
		{
			[Kind.GateKeeper] = null,
			[Kind.LibraryBuild] = null,
			[Kind.TrainingLab] = null,
		};

		try
		{
			// Misma raíz que Realm/bridge/PAO vía [AlexandriaDataRoot.RepoRoot], no solo subir desde el .exe.
			try
			{
				var rr = AlexandriaDataRoot.RepoRoot;
				var classicRealms = Path.Combine(rr, "data", "realms");
				if (Directory.Exists(classicRealms))
				{
					var dev = DevPathsFromRepoRoot(rr);
					if (dev[Kind.GateKeeper] != null || dev[Kind.LibraryBuild] != null ||
						dev[Kind.TrainingLab] != null)
						return dev;
				}
			}
			catch (Exception ex)
			{
				GD.PrintErr($"[SiblingApps.Resolve] repoRoot: {ex.Message}");
			}

			var exe = OS.GetExecutablePath();
			if (string.IsNullOrEmpty(exe))
				return empty;

			var dir = new DirectoryInfo(Path.GetDirectoryName(exe) ?? ".");
			for (var i = 0; i < 22 && dir != null; i++)
			{
				var root = dir.FullName;
				var bundleLb = Path.Combine(root, "LibraryBuild", "library_build.exe");
				var bundleGk = Path.Combine(root, "GateKeeper", "Gatekeeper.exe");
				var bundleLab = Path.Combine(root, "TrainingLab", "training_app.exe");
				if (File.Exists(bundleLb) && File.Exists(bundleGk) && File.Exists(bundleLab))
				{
					return new Dictionary<Kind, string?>
					{
						[Kind.LibraryBuild] = bundleLb,
						[Kind.GateKeeper] = bundleGk,
						[Kind.TrainingLab] = bundleLab,
					};
				}

				var classicRealms = Path.Combine(root, "data", "realms");
				if (Directory.Exists(classicRealms))
				{
					var dev = DevPathsFromRepoRoot(root);
					if (dev[Kind.GateKeeper] != null || dev[Kind.LibraryBuild] != null ||
						dev[Kind.TrainingLab] != null)
						return dev;
				}

				dir = dir.Parent;
			}
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[SiblingApps.Resolve] {ex.Message}");
		}

		return empty;
	}

	private static Dictionary<Kind, string?> DevPathsFromRepoRoot(string root)
	{
		string? gk = null;
		var gkExport = Path.Combine(root, "GateKeeper", "export", "Gatekeeper.exe");
		var gkPlain = Path.Combine(root, "GateKeeper", "Gatekeeper.exe");
		if (File.Exists(gkExport))
			gk = gkExport;
		else if (File.Exists(gkPlain))
			gk = gkPlain;

		var lb = Path.Combine(
			root, "LibraryBuild", "build", "windows", "x64", "runner", "Release", "library_build.exe");
		var lab = Path.Combine(
			root, "training_app", "build", "windows", "x64", "runner", "Release", "training_app.exe");

		return new Dictionary<Kind, string?>
		{
			[Kind.GateKeeper] = gk,
			[Kind.LibraryBuild] = File.Exists(lb) ? lb : null,
			[Kind.TrainingLab] = File.Exists(lab) ? lab : null,
		};
	}
}
