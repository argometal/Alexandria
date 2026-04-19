using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Godot;

/// <summary>
/// Resolución de imágenes bajo <c>assets/&lt;key&gt;/</c> del realm activo.
/// </summary>
public static class AlexandriaAssets
{
	public class WallManifestImage
	{
		public string Filename { get; set; } = "";
		public string Hash { get; set; } = "";
	}

	public class WallManifestData
	{
		public long Version { get; set; }
		public List<WallManifestImage> Images { get; set; } = new List<WallManifestImage>();
	}

	public class CollageGroup
	{
		public List<string> ImagePaths { get; set; } = new List<string>();
	}

	public static string Root => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "assets");
	private static string WallManifestRoot => Path.Combine(AlexandriaDataRoot.RealmDataRoot, "manifests", "wall");
	private static readonly string[] HeroNames =
	{
		"hero.png", "hero.jpg", "hero.jpeg", "hero.webp",
	};

	/// <summary>Legacy RAZ: portada fija si no hay hero en disco.</summary>
	private static readonly string[] CoverNames =
	{
		"cover.png", "cover.jpg", "cover.jpeg", "cover.webp",
	};

	private static readonly string[] ImageExtensions = { ".png", ".jpg", ".jpeg", ".webp" };

	/// <summary>Si coexisten varios <c>hero.*</c>, usa el más reciente por fecha (evita quedar pegado a un <c>hero.png</c> viejo).</summary>
	public static string FindHeroPath(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";
		var dir = Path.Combine(Root, key.Trim());
		if (!Directory.Exists(dir))
			return "";
		string best = "";
		var bestTicks = 0L;
		foreach (var name in HeroNames)
		{
			var full = Path.Combine(dir, name);
			if (!File.Exists(full))
				continue;
			try
			{
				var t = File.GetLastWriteTimeUtc(full).Ticks;
				if (string.IsNullOrEmpty(best) || t >= bestTicks)
				{
					bestTicks = t;
					best = full;
				}
			}
			catch
			{
				if (string.IsNullOrEmpty(best))
					best = full;
			}
		}
		return best;
	}

	public static bool IsHeroFileName(string fileName)
	{
		var lower = fileName.ToLowerInvariant();
		foreach (var h in HeroNames)
		{
			if (string.Equals(lower, h, StringComparison.OrdinalIgnoreCase))
				return true;
		}
		return false;
	}

	public static bool IsCoverFileName(string fileName)
	{
		var lower = fileName.ToLowerInvariant();
		foreach (var c in CoverNames)
		{
			if (string.Equals(lower, c, StringComparison.OrdinalIgnoreCase))
				return true;
		}
		return false;
	}

	public static string FindCoverPath(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";
		var dir = Path.Combine(Root, key.Trim());
		if (!Directory.Exists(dir))
			return "";
		foreach (var name in CoverNames)
		{
			var full = Path.Combine(dir, name);
			if (File.Exists(full))
				return full;
		}
		return "";
	}

	/// <summary>Primera imagen en carpeta (utilidad; el marco solo usa hero + cover, legacy).</summary>
	public static string FindFirstImageInFolder(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";
		var dir = Path.Combine(Root, key.Trim());
		if (!Directory.Exists(dir))
			return "";
		var files = new List<string>();
		foreach (var ext in ImageExtensions)
		{
			try
			{
				files.AddRange(Directory.GetFiles(dir, "*" + ext, SearchOption.TopDirectoryOnly));
			}
			catch
			{
				// ignore
			}
		}
		var pick = files
			.Distinct(StringComparer.OrdinalIgnoreCase)
			.OrderBy(f => f, StringComparer.OrdinalIgnoreCase)
			.FirstOrDefault();
		return pick ?? "";
	}

	/// <summary>Marco (legacy): <c>hero.*</c> → <c>cover.*</c> → primera imagen en carpeta (objetos LB_* a menudo sin hero nominal).</summary>
	public static string FindFrameDisplayImagePath(string key)
	{
		var hero = FindHeroPath(key);
		if (!string.IsNullOrEmpty(hero))
			return hero;
		var cover = FindCoverPath(key);
		if (!string.IsNullOrEmpty(cover))
			return cover;
		return FindFirstImageInFolder(key);
	}

	/// <summary>Firma del archivo que alimenta el marco (hero → cover → primera imagen), para hot-reload sin <c>refresh_now</c>.</summary>
	public static string GetFrameDisplaySignature(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";
		var path = FindFrameDisplayImagePath(key);
		if (string.IsNullOrEmpty(path) || !File.Exists(path))
			return "frame:empty";
		try
		{
			var fi = new FileInfo(path);
			return $"frame:{Path.GetFileName(path)}:{fi.Length}:{fi.LastWriteTimeUtc.Ticks}";
		}
		catch
		{
			return "frame:err";
		}
	}

	public static Image TryLoadImage(string path)
	{
		if (string.IsNullOrEmpty(path) || !File.Exists(path))
			return null;
		var img = new Image();
		if (img.Load(path) != Error.Ok)
			return null;
		return img;
	}

	/// <summary>
	/// <c>object-fit: contain</c> en CPU: cuadrado <paramref name="boxPixels"/>×<paramref name="boxPixels"/>;
	/// bandas con <paramref name="padColor"/> (sin shader). La cara del <c>BoxMesh</c> del frame es 1:1 en UV.
	/// </summary>
	public static ImageTexture CreateSquareLetterboxedTexture(
		Image source,
		int boxPixels = 768,
		Color? padColor = null)
	{
		if (source == null)
			return null;
		source.Convert(Image.Format.Rgba8);
		var w = source.GetWidth();
		var h = source.GetHeight();
		if (w <= 0 || h <= 0)
			return ImageTexture.CreateFromImage(source);

		var fill = padColor ?? new Color(0.12f, 0.098f, 0.086f, 1f);
		var s = (float)boxPixels;
		var scale = Math.Min(s / w, s / h);
		var dw = Math.Max(1, (int)Math.Round(w * scale));
		var dh = Math.Max(1, (int)Math.Round(h * scale));
		var ox = (boxPixels - dw) / 2;
		var oy = (boxPixels - dh) / 2;

		var fitted = source.Duplicate() as Image;
		if (fitted == null)
			return ImageTexture.CreateFromImage(source);
		fitted.Convert(Image.Format.Rgba8);
		fitted.Resize(dw, dh, Image.Interpolation.Bilinear);

		var canvas = Image.CreateEmpty(boxPixels, boxPixels, false, Image.Format.Rgba8);
		canvas.Fill(fill);
		canvas.BlendRect(fitted, new Rect2I(0, 0, dw, dh), new Vector2I(ox, oy));

		return ImageTexture.CreateFromImage(canvas);
	}

	private static string GetWallManifestPath(string key) =>
		Path.Combine(WallManifestRoot, (key ?? "").Trim() + ".json");

	private static bool TryReadWallManifest(string key, out WallManifestData data)
	{
		data = null;
		if (string.IsNullOrWhiteSpace(key))
			return false;
		var manifestPath = GetWallManifestPath(key);
		if (!File.Exists(manifestPath))
			return false;

		try
		{
			var text = File.ReadAllText(manifestPath);
			var json = new Json();
			if (json.Parse(text) != Error.Ok || json.Data.VariantType != Variant.Type.Dictionary)
				return false;
			var root = json.Data.AsGodotDictionary();
			var parsed = new WallManifestData();
			if (root.ContainsKey("version"))
			{
				var v = root["version"];
				parsed.Version = v.VariantType switch
				{
					Variant.Type.Int => v.AsInt64(),
					Variant.Type.Float => (long)v.AsDouble(),
					_ => 0L
				};
			}

			if (root.ContainsKey("images"))
			{
				var arr = root["images"].AsGodotArray();
				foreach (var item in arr)
				{
					if (item.VariantType != Variant.Type.Dictionary)
						continue;
					var d = item.AsGodotDictionary();
					var filename = d.ContainsKey("filename") ? d["filename"].AsString().Trim() : "";
					var hash = d.ContainsKey("hash") ? d["hash"].AsString().Trim() : "";
					if (string.IsNullOrEmpty(filename))
						continue;
					parsed.Images.Add(new WallManifestImage { Filename = filename, Hash = hash });
				}
			}

			data = parsed;
			return true;
		}
		catch
		{
			return false;
		}
	}

	/// <summary>
	/// Rutas de pared para GK: solo el manifest wall generado por Library Build (rol Collage).
	/// Sin fallback a carpeta: evita mezclar imágenes viewer/content con el collage del corredor.
	/// </summary>
	public static List<string> GetWallImagePaths(string key)
	{
		var result = new List<string>();
		if (string.IsNullOrWhiteSpace(key))
			return result;

		var manifestPath = GetWallManifestPath(key);
		if (!TryReadWallManifest(key, out var manifest))
		{
			// Sin archivo: pared vacía (normal hasta generar manifests con LB). Solo error si existe pero no parsea.
			if (File.Exists(manifestPath))
				GD.PrintErr($"[WALL] key={key} manifest wall ilegible: {manifestPath}");
			return result;
		}

		var baseDir = Path.Combine(Root, key.Trim());
		foreach (var img in manifest.Images)
		{
			// Contrato: rutas relativas a data/assets/{key}/
			var full = Path.Combine(baseDir, img.Filename);
			if (File.Exists(full))
				result.Add(full);
		}

		result = result
			.Distinct(StringComparer.OrdinalIgnoreCase)
			.ToList();

		if (result.Count == 0 && manifest.Images.Count > 0)
			GD.PrintErr($"[WALL] key={key} manifest lista imágenes pero ningún archivo resuelto bajo {baseDir}.");

		return result;
	}

	/// <summary>
	/// Firma de fuente visual de pared para invalidación runtime (alineada con <see cref="GetWallImagePaths"/>).
	/// </summary>
	public static string GetWallSourceSignature(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return "";
		var paths = GetWallImagePaths(key);
		if (paths.Count == 0)
			return "wall:0";
		try
		{
			var parts = paths.Select(p =>
			{
				try
				{
					var fi = new FileInfo(p);
					return $"{Path.GetFileName(p)}:{fi.Length}:{fi.LastWriteTimeUtc.Ticks}";
				}
				catch
				{
					return Path.GetFileName(p);
				}
			});
			return $"wall:{paths.Count}:{string.Join("|", parts)}";
		}
		catch
		{
			return "wall:err";
		}
	}

	/// <summary>
	/// Unidad lógica de pared: collage group.
	/// Fallback seguro inicial: 1 imagen = 1 grupo.
	/// </summary>
	public static List<CollageGroup> GetWallCollageGroups(string key)
	{
		var images = GetWallImagePaths(key);
		var groups = new List<CollageGroup>();
		foreach (var img in images)
		{
			groups.Add(new CollageGroup
			{
				ImagePaths = new List<string> { img }
			});
		}

		return groups;
	}

	/// <summary>
	/// Construye una textura de panel para un grupo de collage.
	/// 1 imagen: se comporta como panel individual.
	/// N imágenes: composición horizontal en una sola textura.
	/// </summary>
	public static ImageTexture BuildCollageTexture(List<string> imagePaths)
	{
		if (imagePaths == null || imagePaths.Count == 0)
			return null;

		if (imagePaths.Count == 1)
		{
			var img = TryLoadImage(imagePaths[0]);
			if (img == null)
				return null;
			img.Convert(Image.Format.Rgba8);
			return ImageTexture.CreateFromImage(img);
		}

		return BuildHorizontalStrip512(imagePaths);
	}

	/// <summary>
	/// Pared: hasta 4 fotos (sin hero ni cover ni duplicados por hash). Si no hay galería: hero o cover a pantalla completa.
	/// </summary>
	public static ImageTexture TryBuildWallCollageTexture(string key)
	{
		if (string.IsNullOrWhiteSpace(key))
			return null;
		var dir = Path.Combine(Root, key.Trim());
		if (!Directory.Exists(dir))
			return null;

		var gallery = GetWallImagePaths(key).Take(4).ToList();
		var hero = FindHeroPath(key);
		var cover = FindCoverPath(key);

		if (gallery.Count == 0)
		{
			var fallbackPath = !string.IsNullOrEmpty(hero) ? hero : cover;
			if (string.IsNullOrEmpty(fallbackPath))
				return null;
			var single = TryLoadImage(fallbackPath);
			if (single == null)
				return null;
			single.Convert(Image.Format.Rgba8);
			single.Resize(768, 768, Image.Interpolation.Bilinear);
			return WallTextureFromImage(single);
		}

		if (gallery.Count == 1)
			return BuildSingleFull(gallery[0]);

		return BuildHorizontalStrip512(gallery);
	}

	/// <summary>90° en sentido horario (a la derecha), para alinear el collage con el UV del plano de la pared.</summary>
	private static Image Rotate90Clockwise(Image src)
	{
		src.Convert(Image.Format.Rgba8);
		var w = src.GetWidth();
		var h = src.GetHeight();
		var dst = Image.CreateEmpty(h, w, false, Image.Format.Rgba8);
		for (var dx = 0; dx < h; dx++)
		{
			for (var dy = 0; dy < w; dy++)
				dst.SetPixel(dx, dy, src.GetPixel(dy, h - 1 - dx));
		}

		return dst;
	}

	private static ImageTexture WallTextureFromImage(Image img) =>
		ImageTexture.CreateFromImage(Rotate90Clockwise(img));

	private static ImageTexture BuildSingleFull(string path)
	{
		var img = TryLoadImage(path);
		if (img == null)
			return null;
		img.Convert(Image.Format.Rgba8);
		img.Resize(768, 768, Image.Interpolation.Bilinear);
		return WallTextureFromImage(img);
	}

	/// <summary>
	/// Collage horizontal: izquierda → derecha, preservando orden temporal de selección.
	/// </summary>
	private static ImageTexture BuildHorizontalStrip512(IReadOnlyList<string> paths)
	{
		const int stripSize = 768;
		var canvas = Image.CreateEmpty(stripSize, stripSize, false, Image.Format.Rgba8);
		canvas.Fill(new Color(0.11f, 0.09f, 0.078f, 1f));

		var n = Math.Min(paths.Count, 4);
		var x = 0;

		for (var i = 0; i < n; i++)
		{
			var colW = (stripSize - x) / (n - i);
			var src = TryLoadImage(paths[i]);
			if (src == null)
			{
				x += colW;
				continue;
			}

			src.Convert(Image.Format.Rgba8);
			src.Resize(colW, stripSize, Image.Interpolation.Bilinear);
			canvas.BlendRect(src, new Rect2I(0, 0, colW, stripSize), new Vector2I(x, 0));
			x += colW;
		}

		return WallTextureFromImage(canvas);
	}
}
