using System;
using System.IO;
using System.Text;

/// <summary>
/// Log de app en <c>%LOCALAPPDATA%\Alexandria\diagnostics\gatekeeper.log</c> (misma carpeta que el launcher).
/// </summary>
public static class AppDiagnosticsLog
{
	private static readonly object LockObj = new();
	private static bool _inited;

	public static void InitIfNeeded()
	{
		if (_inited)
			return;
		_inited = true;
		try
		{
			var dir = Path.Combine(
				Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
				"Alexandria", "diagnostics");
			Directory.CreateDirectory(dir);
			AppDomain.CurrentDomain.UnhandledException += (_, e) =>
			{
				try
				{
					E("UNHANDLED", e.ExceptionObject?.ToString() ?? "?");
				}
				catch { }
			};
			W("SESSION", "GateKeeper start");
		}
		catch { }
	}

	/// <summary>Ruta del log en disco (visible sin consola: Explorador → <c>%LOCALAPPDATA%\Alexandria\diagnostics</c>).</summary>
	public static string DiagnosticLogFilePath =>
		Path.Combine(
			Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
			"Alexandria", "diagnostics", "gatekeeper.log");

	private static string LogPath => DiagnosticLogFilePath;

	public static void E(string tag, string msg)
	{
		AppendErrorLine($"{DateTime.UtcNow:o}\tERROR\t{tag}\t{msg}\n");
	}

	public static void E(string tag, string msg, Exception ex)
	{
		AppendErrorLine($"{DateTime.UtcNow:o}\tERROR\t{tag}\t{msg} | {ex}\n");
	}

	private static void AppendErrorLine(string line)
	{
		try
		{
			lock (LockObj)
			{
				File.AppendAllText(LogPath, line, Encoding.UTF8);
				TrimIfNeeded();
			}
		}
		catch { }
	}

	public static void W(string tag, string msg)
	{
		try
		{
			lock (LockObj)
			{
				File.AppendAllText(LogPath, $"{DateTime.UtcNow:o}\tINFO\t{tag}\t{msg}\n", Encoding.UTF8);
				TrimIfNeeded();
			}
		}
		catch { }
	}

	/// <summary>
	/// Rastro paso a paso (release): <c>origen\tmensaje</c> en <c>gatekeeper.log</c> para reproducir fallos de rutas / viewer.
	/// </summary>
	public static void Trace(string origin, string message)
	{
		W("TRACE", $"{origin}\t{message}");
	}

	private static void TrimIfNeeded()
	{
		try
		{
			const int maxBytes = 500000;
			var fi = new FileInfo(LogPath);
			if (!fi.Exists || fi.Length <= maxBytes)
				return;
			const int keep = 240000;
			using var fs = new FileStream(LogPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
			var len = fs.Length;
			var start = len - keep;
			if (start < 0)
				start = 0;
			fs.Seek(start, SeekOrigin.Begin);
			var buf = new byte[len - start];
			_ = fs.Read(buf, 0, buf.Length);
			File.WriteAllText(LogPath, "[... log truncado ...]\n" + Encoding.UTF8.GetString(buf), Encoding.UTF8);
		}
		catch { }
	}
}
