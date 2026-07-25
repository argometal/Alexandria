using System.IO;

/// <summary>
/// GateKeeper HUD / viewer strings follow <c>bridge/gk_ui_lang.txt</c> (written by Library Build). Default <c>en</c>.
/// </summary>
public static class GkUiLocale
{
	/// <summary>Two-letter code: <c>en</c>, <c>es</c>, or <c>pt</c>. Missing/invalid file → <c>en</c>.</summary>
	public static string ReadGkUiLanguageCode()
	{
		try
		{
			var p = BridgeSpatial.GkUiLangPath;
			if (!File.Exists(p))
				return "en";
			var t = File.ReadAllText(p).Trim().ToLowerInvariant();
			if (t.Length >= 2)
				t = t.Substring(0, 2);
			return t is "es" or "pt" or "en" ? t : "en";
		}
		catch
		{
			return "en";
		}
	}

	public static bool IsSpanishUi() => ReadGkUiLanguageCode() == "es";

	public static string CloseTooltip() => IsSpanishUi() ? "Cerrar" : "Close";

	public static string MenuBurgerTooltip() =>
		IsSpanishUi() ? "Menú: ayuda y navegación del parcour" : "Menu: help and parcour navigation";

	public static string MenuHelp() => IsSpanishUi() ? "Ayuda (F1)" : "Help (F1)";

	/// <summary>Section title for frame stepping (not “unstuck”).</summary>
	public static string MenuParcourFramesTitle() =>
		IsSpanishUi() ? "Marcos del parcour" : "Parcour frames";

	public static string MenuPreviousFrame() =>
		IsSpanishUi() ? "← Marco anterior" : "← Previous frame";

	public static string MenuNextFrame() =>
		IsSpanishUi() ? "Marco siguiente →" : "Next frame →";

	public static string MenuParcourCorridorHint() =>
		IsSpanishUi()
			? "Solo en el pasillo del parcour. En un objeto, usa «Atrás» en el visor."
			: "Only on the parcour corridor. In an object viewer, use Back.";

	public static string MenuGoParcourHub() =>
		IsSpanishUi() ? "Ir al hub del parcour" : "Go to parcour hub";

	public static string MenuSectionAlexandriaApps() =>
		IsSpanishUi() ? "Suite Alexandria" : "Alexandria suite";

	public static string MenuOpenLibraryBuild() =>
		IsSpanishUi() ? "Abrir Library Build" : "Open Library Build";

	public static string MenuOpenTrainingLab() =>
		IsSpanishUi() ? "Abrir Training Lab" : "Open Training Lab";

	public static string MenuFrameLine(int zeroBasedIndex, int slotCount) =>
		IsSpanishUi()
			? $"Marco {zeroBasedIndex + 1} / {slotCount} (índice {zeroBasedIndex})"
			: $"Frame {zeroBasedIndex + 1} / {slotCount} (index {zeroBasedIndex})";

	public static string PlaceRecallSection() =>
		IsSpanishUi() ? "Place recall" : "Place recall";

	public static string PlaceRecallTapToOpen() =>
		IsSpanishUi() ? "▸ Place recall — tocar para abrir" : "▸ Place recall — tap to open";

	public static string PlaceRecallTapToClose() =>
		IsSpanishUi() ? "▾ Place recall — tocar para cerrar" : "▾ Place recall — tap to close";

	public static string PlaceRecallCurrentMissingCrop() =>
		IsSpanishUi()
			? "Place recall: este objeto necesita una imagen recall_crop en el cuerpo del visor y el archivo en assets."
			: "Place recall: this object needs a recall_crop image in the viewer body and the file under assets.";

	public static string PlaceRecallNeedThreeOtherObjects() =>
		IsSpanishUi()
			? "Place recall: hacen falta al menos otros tres objetos distintos en el realm con recall_crop y archivos válidos."
			: "Place recall: need at least three other objects in the realm with a recall_crop and valid image files.";

	public static string PlaceRecallInvalidContext() =>
		IsSpanishUi()
			? "Place recall no está disponible en esta vista."
			: "Place recall is not available for this view.";

	public static string PlaceRecallPickCrop() =>
		IsSpanishUi()
			? "Toca el recorte que corresponde a este marco."
			: "Tap the crop that belongs to this frame.";

	public static string PlaceRecallCorrect() => IsSpanishUi() ? "Correcto." : "Correct.";

	public static string PlaceRecallWrong() => IsSpanishUi() ? "No es ese." : "Not quite.";

	public static string PlaceRecallEnterObjectTitle() =>
		"Enter object level";

	public static string PlaceRecallEnterObjectBody() =>
		"Place recall mode is on. Do you want to reset all frame unlocks for this session before entering?\n\n"
		+ "· Reset — heroes go back to locked until you solve each crop again.\n"
		+ "· Keep — your current unlocks stay.";

	public static string PlaceRecallEnterObjectReset() => "Reset unlocks";

	public static string PlaceRecallEnterObjectKeep() => "Keep unlocks";

	public static string LabelHint() => IsSpanishUi() ? "Pista" : "Hint";

	public static string LabelPlace() => IsSpanishUi() ? "Lugar" : "Place";

	public static string LabelRidiculousStory() =>
		IsSpanishUi() ? "Historia ridícula" : "Ridiculous story";

	public static string NoFocusKey() => IsSpanishUi() ? "(sin clave de foco)" : "(no focus key)";

	public static string NoFocusKeyTitle() => IsSpanishUi() ? "Hueco vacío (sin clave)" : "Empty slot (no key)";

	public static string EmptySlotNoKey() =>
		IsSpanishUi()
			? "Este marco no tiene clave en el snapshot. Revisa seq en data/bridge/current_seq.txt."
			: "This frame has no key in the snapshot. Check seq in data/bridge/current_seq.txt.";

	public static string SyncingLibraryBuild() =>
		IsSpanishUi() ? "Sincronizando con Library Build…" : "Syncing with Library Build…";

	public static string NoBodyYet() => IsSpanishUi() ? "Sin contenido aún." : "No content yet.";

	public static string BackParcour() => IsSpanishUi() ? "← Hub del parcour" : "← Parcour hub";

	public static string Back() => IsSpanishUi() ? "← Atrás" : "← Back";

	public static string EnterChild() => IsSpanishUi() ? "→ Entrar" : "→ Enter";

	public static string SectionObjectLore() => IsSpanishUi() ? "Lore del objeto" : "Object lore";

	public static string SectionOtherContent() => IsSpanishUi() ? "Contenido" : "Content";

	public static string MissingImage() => IsSpanishUi() ? "(imagen ausente)" : "(missing image)";

	public static string LoadError() => IsSpanishUi() ? "(error al cargar)" : "(load error)";

	public static string RolePrefix() => IsSpanishUi() ? "Rol" : "Role";

	public static string NextReviewPrefix() => IsSpanishUi() ? "Próxima revisión" : "Next review";

	public static string RecallStatsLine(
		double recallScore, double stabilityDays, double memoryStrength, int reviewCount) =>
		IsSpanishUi()
			? $"Recall {recallScore:0.00} · Estabilidad {stabilityDays:0.0}d · Fuerza {memoryStrength:0.00} · Revisiones {reviewCount}"
			: $"Recall score {recallScore:0.00} · Stability {stabilityDays:0.0}d · Strength {memoryStrength:0.00} · Reviews {reviewCount}";
}
