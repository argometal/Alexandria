using System;
using System.IO;

public static class A15Logger
{
	private static readonly string LogDir = @"C:\Alexandria\logs";
	private static readonly string LogFile = Path.Combine(LogDir, "a15.log");

	public static void Log(string tag, string message)
	{
		try
		{
			if (!Directory.Exists(LogDir))
				Directory.CreateDirectory(LogDir);

			string line = $"{DateTime.UtcNow:O} | {tag} | {message}";
			File.AppendAllText(LogFile, line + Environment.NewLine);
		}
		catch { }
	}
}