using System.Reflection;
using System.Text;

namespace Alexandria;

/// <summary>
/// Registro persistente en disco para fallos y arranques del launcher (visible en futuras versiones / soporte).
/// </summary>
internal static class LauncherDiagnostics
{
    private static readonly object LogLock = new();

    /// <summary>Ruta del archivo principal de log (misma para todos los ExtractId).</summary>
    internal static string LogFilePath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Alexandria",
        "diagnostics",
        "launcher.log");

    internal static string DiagnosticsFolder => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Alexandria",
        "diagnostics");

    internal static void Log(string category, string message, Exception? ex = null)
    {
        try
        {
            var dir = DiagnosticsFolder;
            Directory.CreateDirectory(dir);
            var sb = new StringBuilder();
            sb.Append(DateTime.UtcNow.ToString("o"))
                .Append('\t')
                .Append(category)
                .Append('\t')
                .Append(message.Replace("\r\n", " ").Replace('\n', ' ').Replace('\r', ' '));
            if (ex != null)
            {
                sb.Append(" | EX: ").Append(ex.GetType().Name).Append(' ').Append(ex.Message);
            }

            sb.Append('\n');
            lock (LogLock)
            {
                File.AppendAllText(LogFilePath, sb.ToString());
                TrimLogIfNeeded(LogFilePath, maxBytes: 480_000);
            }
        }
        catch
        {
            // nunca propagar: el launcher debe seguir
        }
    }

    private static void TrimLogIfNeeded(string path, int maxBytes)
    {
        try
        {
            var fi = new FileInfo(path);
            if (!fi.Exists || fi.Length <= maxBytes)
            {
                return;
            }

            const int tailCap = 240_000;
            using var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            var len = fs.Length;
            var take = (int)Math.Min(tailCap, len);
            fs.Seek(len - take, SeekOrigin.Begin);
            var buf = new byte[take];
            _ = fs.Read(buf, 0, take);
            var tail = Encoding.UTF8.GetString(buf);
            File.WriteAllText(path, "[... log truncado UTF-8 ...]\n" + tail);
        }
        catch
        {
            // ignorar recorte
        }
    }

    internal static void LogSessionStart(string extractRoot, string extractId)
    {
        var v = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "?";
        var baseDir = AppContext.BaseDirectory;
        Log("session",
            $"producer={AlexandriaBranding.StudioName} extractId={extractId} version={v} extractRoot={extractRoot} appBaseDir={baseDir}");
    }
}
