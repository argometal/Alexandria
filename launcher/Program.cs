using System.Collections.Generic;
using System.Diagnostics;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Windows.Forms;

namespace Alexandria;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        try
        {
            if (BuildInfo.ExtractId == "PLACEHOLDER")
            {
                LauncherDiagnostics.Log("reject", "ExtractId PLACEHOLDER — ejecutable no publicado con CREAR-APP.");
                MessageBox.Show(
                    "Este ejecutable se genera con CREAR-APP.bat en la maquina de desarrollo.\nNo ejecutes el launcher desde el repo sin publicar.\n\n"
                    + "Detalle en:\n" + LauncherDiagnostics.LogFilePath
                    + "\n\n" + AlexandriaBranding.CreditLine,
                    AlexandriaBranding.LauncherCaption,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
                return;
            }

            var root = EnsureBundleExtracted();
            LauncherDiagnostics.LogSessionStart(root, BuildInfo.ExtractId);
            LauncherDiagnostics.Log("spawn_policy",
                "solo LibraryBuild al arrancar; GateKeeper, TrainingLab y DataTransfer se abren desde Library Build cuando hagan falta (menos RAM).");

            var missing = new List<string>();
            if (!TryStartChild(Path.Combine(root, "LibraryBuild", "library_build.exe"), "LibraryBuild"))
            {
                missing.Add("LibraryBuild\\library_build.exe");
            }

            if (missing.Count > 0)
            {
                var msg = new StringBuilder();
                msg.AppendLine("Faltan archivos en el bundle extraido:");
                foreach (var m in missing)
                {
                    msg.AppendLine(" · " + m);
                }

                msg.AppendLine();
                msg.AppendLine("Log: " + LauncherDiagnostics.LogFilePath);
                msg.AppendLine();
                msg.AppendLine(AlexandriaBranding.CreditLine);
                LauncherDiagnostics.Log("warn_missing", string.Join("; ", missing));
                MessageBox.Show(
                    msg.ToString(),
                    AlexandriaBranding.LauncherCaption,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
            }
        }
        catch (Exception ex)
        {
            LauncherDiagnostics.Log("fatal", ex.Message, ex);
            MessageBox.Show(
                ex.Message + "\n\nLog: " + LauncherDiagnostics.LogFilePath
                + "\n\n" + AlexandriaBranding.CreditLine,
                AlexandriaBranding.LauncherCaption,
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            Environment.Exit(1);
        }
    }

    private static bool TryStartChild(string path, string label)
    {
        if (!File.Exists(path))
        {
            LauncherDiagnostics.Log("missing", $"{label}: {path}");
            return false;
        }

        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = path,
                WorkingDirectory = Path.GetDirectoryName(path) ?? Environment.CurrentDirectory,
                UseShellExecute = true,
            });
            LauncherDiagnostics.Log("spawn", $"{label}: {path}");
            return true;
        }
        catch (Exception ex)
        {
            LauncherDiagnostics.Log("spawn_fail", $"{label}: {path} — {ex.Message}", ex);
            return false;
        }
    }

    private static string EnsureBundleExtracted()
    {
        var baseDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Alexandria",
            BuildInfo.ExtractId);

        var marker = Path.Combine(baseDir, ".extract_ok");
        if (File.Exists(marker))
        {
            LauncherDiagnostics.Log("extract", $"reuse extractRoot={baseDir}");
            return baseDir;
        }

        LauncherDiagnostics.Log("extract", $"fresh extract into {baseDir}");
        if (Directory.Exists(baseDir))
        {
            try
            {
                Directory.Delete(baseDir, true);
            }
            catch (Exception ex)
            {
                LauncherDiagnostics.Log("extract_warn", "No se pudo borrar carpeta previa; se intenta continuar.", ex);
            }
        }

        Directory.CreateDirectory(baseDir);

        var asm = Assembly.GetExecutingAssembly();
        var names = asm.GetManifestResourceNames();
        var resName = names.FirstOrDefault(n => n.EndsWith("bundle.zip", StringComparison.OrdinalIgnoreCase))
            ?? throw new InvalidOperationException("Recurso embebido bundle.zip no encontrado. " + string.Join(", ", names));

        using var stream = asm.GetManifestResourceStream(resName)
            ?? throw new InvalidOperationException("No se pudo abrir el stream del bundle.");

        ExtractZip(stream, baseDir);
        File.WriteAllText(marker, DateTime.UtcNow.ToString("o"));
        return baseDir;
    }

    private static void ExtractZip(Stream stream, string dest)
    {
        using var zip = new ZipArchive(stream, ZipArchiveMode.Read, leaveOpen: false);
        foreach (var entry in zip.Entries)
        {
            var rel = entry.FullName.Replace('/', Path.DirectorySeparatorChar).TrimEnd(Path.DirectorySeparatorChar);
            if (string.IsNullOrEmpty(rel))
            {
                continue;
            }

            var target = Path.Combine(dest, rel);
            if (string.IsNullOrEmpty(entry.Name))
            {
                Directory.CreateDirectory(target);
                continue;
            }

            var parent = Path.GetDirectoryName(target);
            if (!string.IsNullOrEmpty(parent))
            {
                Directory.CreateDirectory(parent);
            }

            entry.ExtractToFile(target, overwrite: true);
        }
    }
}
