using System;
using System.IO;
using Godot;

/// <summary>
/// Al entrar a un nivel objeto con modo <c>place_recall</c>: elegir reiniciar desbloqueos de sesión o conservarlos.
/// </summary>
public partial class RealmController
{
	private ConfirmationDialog _placeRecallEnterDialog = null!;
	private string _pendingEnterLevelKey = "";
	private Input.MouseModeEnum _mouseModeBeforePlaceRecallEnterDialog;

	private static bool ShouldOfferPlaceRecallSessionResetOnObjectEnter(string key) =>
		BridgeSpatial.IsObjectLocusKey(key)
		&& string.Equals(
			BridgeSpatial.ReadNavigationIntentModeFirstLine(),
			"place_recall",
			StringComparison.Ordinal);

	private void SetupPlaceRecallEnterObjectDialog()
	{
		var layer = new CanvasLayer { Layer = 110 };
		AddChild(layer);

		_placeRecallEnterDialog = new ConfirmationDialog();
		_placeRecallEnterDialog.Name = "PlaceRecallEnterConfirm";
		_placeRecallEnterDialog.Title = GkUiLocale.PlaceRecallEnterObjectTitle();
		_placeRecallEnterDialog.DialogText = GkUiLocale.PlaceRecallEnterObjectBody();
		_placeRecallEnterDialog.OkButtonText = GkUiLocale.PlaceRecallEnterObjectReset();
		_placeRecallEnterDialog.CancelButtonText = GkUiLocale.PlaceRecallEnterObjectKeep();
		layer.AddChild(_placeRecallEnterDialog);

		_placeRecallEnterDialog.Confirmed += OnPlaceRecallEnterDialogConfirmed;
		_placeRecallEnterDialog.Canceled += OnPlaceRecallEnterDialogCanceled;
	}

	private void ShowPlaceRecallEnterObjectDialog(string key)
	{
		_pendingEnterLevelKey = key;
		_mouseModeBeforePlaceRecallEnterDialog = Input.MouseMode;
		Input.MouseMode = Input.MouseModeEnum.Visible;
		_placeRecallEnterDialog.PopupCentered();
		GD.Print($"[RC][PLACE_RECALL_ENTER] prompt for key={key}");
	}

	private void OnPlaceRecallEnterDialogConfirmed()
	{
		var k = _pendingEnterLevelKey;
		_pendingEnterLevelKey = "";
		Input.MouseMode = _mouseModeBeforePlaceRecallEnterDialog;
		PlaceRecallSessionState.ClearSession();
		_spawner?.RefreshAllPlaceRecallVisuals();
		if (!string.IsNullOrEmpty(k))
			ExecuteEnterLevelWarp(k);
	}

	private void OnPlaceRecallEnterDialogCanceled()
	{
		var k = _pendingEnterLevelKey;
		_pendingEnterLevelKey = "";
		Input.MouseMode = _mouseModeBeforePlaceRecallEnterDialog;
		if (!string.IsNullOrEmpty(k))
			ExecuteEnterLevelWarp(k);
	}

	private void ExecuteEnterLevelWarp(string key)
	{
		try
		{
			Directory.CreateDirectory(BridgeSpatial.BridgeDir);
			BridgeSpatial.WriteContextKey(key);
			BridgeSpatial.WriteFocusKey(key);

			var refreshPath = Path.Combine(BridgeSpatial.BridgeDir, "refresh_now.txt");
			File.WriteAllText(refreshPath, "1");
		}
		catch (Exception e)
		{
			GD.PrintErr("[RC][WARP_ERR] " + e.Message);
			return;
		}

		GD.Print($"[RC][WARP] context_key={key} focus_key={key}");
		_viewer?.ClosePanel();
	}
}
