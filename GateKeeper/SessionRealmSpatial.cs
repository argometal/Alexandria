using System;
using System.Collections.Generic;
using Godot;

/// <summary>
/// Último marco (seq) de parcour **por realm activo**, solo en memoria mientras GateKeeper sigue en ejecución.
/// No escribe disco. Al cargar un realm por primera vez en la sesión no hay entrada → marco 0.
/// </summary>
public static class SessionRealmSpatial
{
	private static readonly Dictionary<string, int> ParcourSeqByRealmId = new(StringComparer.OrdinalIgnoreCase);

	public static int GetParcourSeqForRealmOrDefault(string realmId, int defaultSeq = 0)
	{
		var k = (realmId ?? "").Trim();
		if (k.Length == 0)
			return defaultSeq;
		return ParcourSeqByRealmId.TryGetValue(k, out var s) ? s : defaultSeq;
	}

	public static void SetParcourSeqForRealm(string realmId, int seq)
	{
		var k = (realmId ?? "").Trim();
		if (k.Length == 0)
			return;
		ParcourSeqByRealmId[k] = Mathf.Clamp(seq, 0, 19);
	}
}
