package us.codifi.embeddedbarcodereader;

import android.app.Fragment;
import android.hardware.Camera;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.google.zxing.ResultPoint;
import com.google.zxing.client.android.BeepManager;
import com.journeyapps.barcodescanner.BarcodeCallback;
import com.journeyapps.barcodescanner.BarcodeResult;
import com.journeyapps.barcodescanner.DecoratedBarcodeView;
import com.journeyapps.barcodescanner.camera.CameraSettings;

import java.util.List;
import java.util.Date;

/**
 * This sample performs continuous scanning, displaying the barcode and source image whenever
 * a barcode is scanned.
 */
public class EmbedQRReader extends Fragment {


	public interface BarCodeReadListener {
		void onBarcodeRead(String barcodeValue);
		void onBarcodeError(String message);
	}

	public String defaultCamera;

	private BarCodeReadListener eventListener;

	private static final String TAG = EmbedQRReader.class.getSimpleName();
	private DecoratedBarcodeView barcodeView;
	private BeepManager beepManager;
	private Date lastReadTime = new Date();
	private String lastText;
	private int numberOfCameras = 0;

	private View view;

	private BarcodeCallback callback = new BarcodeCallback() {
		@Override
		public void barcodeResult(BarcodeResult result) {
			Date newReadTime = new Date();
			long milsSinceRead = newReadTime.getTime() - lastReadTime.getTime();
			if (result.getText() == null || (result.getText().equals(lastText) && milsSinceRead < 7000l)) {
				// Prevent duplicate scans by ignoring nulls or duplicate reads within 7s
				Log.d(TAG,"Ignoring duplicate read: " + lastText);
				return;
			}

			lastReadTime = newReadTime;
			lastText = result.getText();
			barcodeView.setStatusText(result.getText());
			beepManager.playBeepSoundAndVibrate();

			eventListener.onBarcodeRead(lastText);

			//Added preview of scanned barcode
//			ImageView imageView = (ImageView) findViewById(R.id.barcodePreview);
//			imageView.setImageBitmap(result.getBitmapWithResultPoints(Color.YELLOW));
			Log.d(TAG,"QR READ: " + lastText);
		}

		@Override
		public void possibleResultPoints(List<ResultPoint> resultPoints) {
		}
	};
	private int x;
	private int y;
	private int width;
	private int height;

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		String appResourcesPackage = getActivity().getPackageName();

		// Inflate the layout for this fragment
		view = inflater.inflate(getResources().getIdentifier("continuous_scan", "layout", appResourcesPackage), container, false);

		FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(width, height);
		layoutParams.setMargins(x, y, 0, 0);
		FrameLayout frameContainerLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("frame_container", "id", appResourcesPackage));
		frameContainerLayout.setLayoutParams(layoutParams);

		barcodeView = (DecoratedBarcodeView) view.findViewById(getResources().getIdentifier("barcode_scanner", "id", appResourcesPackage));

		//set camera
		CameraSettings settings = barcodeView.getBarcodeView().getCameraSettings();
		settings.setRequestedCameraId(this.getDefaultCameraId());

		//start scanning
		barcodeView.decodeContinuous(callback);

		beepManager = new BeepManager(getActivity());
		return view;
	}

	private int getDefaultCameraId() {
		//TODO update to android.hardware.camera2 library
		// Find the total number of cameras available
		numberOfCameras = Camera.getNumberOfCameras();

		int camType = defaultCamera != null && defaultCamera.equals("front") ?
			Camera.CameraInfo.CAMERA_FACING_FRONT :
			Camera.CameraInfo.CAMERA_FACING_BACK;

		int defaultCameraId = 0;

		// Find the ID of the default camera
		Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
		for (int i = 0; i < numberOfCameras; i++) {
			Camera.getCameraInfo(i, cameraInfo);
			if (cameraInfo.facing == camType) {
				defaultCameraId = i;
				break;
			}
		}

		return defaultCameraId;
	}

	@Override
	public void onResume() {
		super.onResume();

		barcodeView.resume();
	}

	@Override
	public void onPause() {
		super.onPause();

		barcodeView.pause();
	}

	public void pause(View view) {
		barcodeView.pause();
	}

	public void resume(View view) {
		barcodeView.resume();
	}

	public void triggerScan(View view) {
		barcodeView.decodeSingle(callback);
	}

	void setRect(int x, int y, int width, int height){
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	void setEventListener(BarCodeReadListener listener){
		eventListener = listener;
	}

	void switchCamera(){
		//If we have multiple cameras, just invert which one is selected
		if (numberOfCameras == 2) {
			if (isAdded()) {
				getActivity().runOnUiThread(new Runnable() {
					@Override
					public void run() {
						CameraSettings settings = barcodeView.getBarcodeView().getCameraSettings();
						int newCameraId = (settings.getRequestedCameraId() + 1) % 2;
						settings.setRequestedCameraId(newCameraId);
						Log.d(TAG, "new cameraId " + newCameraId);

						barcodeView.pause();
						barcodeView.resume();
						Log.d(TAG, "camera restarted");
					}
				});
			}
		} else {
			//if we don't have at least 2 cameras, ignore this.
			Log.d(TAG, "not enough cameras to switch");
		}
	}

	void setTorchMode(boolean enabled){
		if(enabled){
			this.barcodeView.setTorchOn();
		} else {
			this.barcodeView.setTorchOff();
		}
	}
	/*@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		return barcodeView.onKeyDown(keyCode, event) || super.onKeyDown(keyCode, event);
	}*/
}
