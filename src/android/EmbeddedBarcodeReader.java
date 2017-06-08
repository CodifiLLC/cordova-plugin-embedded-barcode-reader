package us.codifi.embeddedbarcodereader;

import android.Manifest;
import android.content.pm.PackageManager;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

public class EmbeddedBarcodeReader extends CordovaPlugin implements EmbedQRReader.BarCodeReadListener {

	private static final String TAG = "EmbeddedBarcodeReader";

	private static final String SUPPORTED_FLASH_MODES_ACTION = "getSupportedFlashModes";
	private static final String FLASH_MODE_ACTION = "setFlashMode";
	private static final String START_CAMERA_ACTION = "startReading";
	private static final String START_LISTENTING_ACTION = "startListening";
	private static final String STOP_CAMERA_ACTION = "stopReading";
	private static final String SWITCH_CAMERA_ACTION = "switchCamera";
	private static final String SHOW_CAMERA_ACTION = "showCamera";
	private static final String HIDE_CAMERA_ACTION = "hideCamera";

	private static final int CAM_REQ_CODE = 0;

	private static final String[] permissions = {
			Manifest.permission.CAMERA
	};

	//private CameraActivity fragment;
	private EmbedQRReader fragment;
	private CallbackContext readBarcodeCallbackContext;

	private CallbackContext execCallback;
	private JSONArray execArgs;

	private int containerViewId = 1;

	public EmbeddedBarcodeReader() {
		super();
		Log.d(TAG, "Constructing");
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

		if (START_CAMERA_ACTION.equals(action)) {
			if (cordova.hasPermission(permissions[0])) {
				Log.d(TAG, "starting camera");
				return startCamera(
						args.getInt(0),
						args.getInt(1),
						args.getInt(2),
						args.getInt(3),
						args.getString(4),
						args.getBoolean(7),
						args.getString(8),
						callbackContext
				);
			} else {
				this.execCallback = callbackContext;
				this.execArgs = args;
				Log.d(TAG, "requesting permission");
				cordova.requestPermissions(this, CAM_REQ_CODE, permissions);
			}
		} else if (START_LISTENTING_ACTION.equals(action)) {
			//set the listener for the read events
			this.readBarcodeCallbackContext = callbackContext;
			return true;
		} else if (SUPPORTED_FLASH_MODES_ACTION.equals(action)) {
			return getSupportedFlashModes(callbackContext);
		} else if (FLASH_MODE_ACTION.equals(action)) {
			return setFlashMode(args.getString(0), callbackContext);
		} else if (STOP_CAMERA_ACTION.equals(action)) {
			this.readBarcodeCallbackContext = null;
			return stopCamera(callbackContext);
		} else if (HIDE_CAMERA_ACTION.equals(action)) {
			return hideCamera(callbackContext);
		} else if (SHOW_CAMERA_ACTION.equals(action)) {
			return showCamera(callbackContext);
		} else if (SWITCH_CAMERA_ACTION.equals(action)) {
			return switchCamera(callbackContext);
		}
		return false;
	}

	@Override
	public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
		for (int r : grantResults) {
			if (r == PackageManager.PERMISSION_DENIED) {
				execCallback.sendPluginResult(new PluginResult(PluginResult.Status.ILLEGAL_ACCESS_EXCEPTION));
				return;
			}
		}
		if (requestCode == CAM_REQ_CODE) {
			startCamera(
					this.execArgs.getInt(0),
					this.execArgs.getInt(1),
					this.execArgs.getInt(2),
					this.execArgs.getInt(3),
					this.execArgs.getString(4),
					this.execArgs.getBoolean(7),
					this.execArgs.getString(8),
					this.execCallback);
			this.readBarcodeCallbackContext = execCallback;
		}
	}

	private boolean hasView(CallbackContext callbackContext) {
		if (fragment == null) {
			callbackContext.error("No preview");
			return false;
		}

		return true;
	}

	private boolean startCamera(int x, int y, int width, int height, String defaultCamera, final Boolean toBack, String alpha, CallbackContext callbackContext) {
		Log.d(TAG, "start camera action");
		if (fragment != null) {
			callbackContext.error("Camera already started");
			return true;
		}

		final float opacity = Float.parseFloat(alpha);

		fragment = new EmbedQRReader();
		fragment.setEventListener(this);
		fragment.defaultCamera = defaultCamera;

		DisplayMetrics metrics = cordova.getActivity().getResources().getDisplayMetrics();
		// offset
		int computedX = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, x, metrics);
		int computedY = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, y, metrics);

		// size
		int computedWidth = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, width, metrics);
		int computedHeight = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, height, metrics);

		fragment.setRect(computedX, computedY, computedWidth, computedHeight);

		final CallbackContext cb = callbackContext;

		cordova.getActivity().runOnUiThread(new Runnable() {
			@Override
			public void run() {


				//create or update the layout params for the container view
				FrameLayout containerView = (FrameLayout) cordova.getActivity().findViewById(containerViewId);
				if (containerView == null) {
					containerView = new FrameLayout(cordova.getActivity().getApplicationContext());
					containerView.setId(containerViewId);

					FrameLayout.LayoutParams containerLayoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
					cordova.getActivity().addContentView(containerView, containerLayoutParams);
				}
				//display camera bellow the webview
				if (toBack) {
					webView.getView().setBackgroundColor(0x00000000);
					((ViewGroup) webView.getView()).bringToFront();
				} else {
					//set camera back to front
					containerView.setAlpha(opacity);
					containerView.bringToFront();
				}

				//add the fragment to the container
				FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
				FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
				fragmentTransaction.add(containerView.getId(), fragment);
				fragmentTransaction.commit();

				Log.d(TAG, "camera fragment started");
				cb.success("Camera started");
			}
		});

		return true;
	}

	public void onBarcodeRead(String barcodeValue) {
		Log.d(TAG, "returning barcode");

		JSONArray data = new JSONArray();
		data.put(barcodeValue);

		if (this.readBarcodeCallbackContext != null) {
			PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, data);
			pluginResult.setKeepCallback(true);
			this.readBarcodeCallbackContext.sendPluginResult(pluginResult);
		}
	}

	public void onBarcodeError(String message) {
		Log.d(TAG, "EmbeddedBarcodeReader onBarcodeError");
		if (this.readBarcodeCallbackContext != null) {
			this.readBarcodeCallbackContext.error(message);
		}
	}

	private boolean getSupportedFlashModes(CallbackContext callbackContext) {
		JSONArray jsonFlashModes = new JSONArray();
		jsonFlashModes.put("on");
		jsonFlashModes.put("off");
		callbackContext.success(jsonFlashModes);
		return true;
	}

	private boolean setFlashMode(String flashMode, CallbackContext callbackContext) {
		if(flashMode.equalsIgnoreCase("on") || flashMode.equalsIgnoreCase("enabled")) {
			fragment.setTorchMode(true);
		} else {
			fragment.setTorchMode(false);
		}
		callbackContext.success(flashMode);
		return true;
	}

	private boolean stopCamera(CallbackContext callbackContext) {
		if (!this.hasView(callbackContext)) {
			return true;
		}

		FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
		FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
		fragmentTransaction.remove(fragment);
		fragmentTransaction.commit();
		fragment = null;

		callbackContext.success();
		return true;
	}

	private boolean showCamera(CallbackContext callbackContext) {
		if (!this.hasView(callbackContext)) {
			return true;
		}

		FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
		FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
		fragmentTransaction.show(fragment);
		fragmentTransaction.commit();

		callbackContext.success();
		return true;
	}

	private boolean hideCamera(CallbackContext callbackContext) {
		if (!this.hasView(callbackContext)) {
			return true;
		}

		FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
		FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
		fragmentTransaction.hide(fragment);
		fragmentTransaction.commit();

		callbackContext.success();
		return true;
	}

	private boolean switchCamera(CallbackContext callbackContext) {
		if (!this.hasView(callbackContext)) {
			return true;
		}

		fragment.switchCamera();

		callbackContext.success();
		return true;
	}
}
