package us.codifi.embeddedbarcodereader;

import android.app.Fragment;
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

import java.util.List;

/**
 * This sample performs continuous scanning, displaying the barcode and source image whenever
 * a barcode is scanned.
 */
public class EmbedQRReader extends Fragment {


	public interface BarCodeReadListener {
		void onBarcodeRead(String barcodeValue);
		void onBarcodeError(String message);
	}

	private BarCodeReadListener eventListener;

	private static final String TAG = EmbedQRReader.class.getSimpleName();
	private DecoratedBarcodeView barcodeView;
	private BeepManager beepManager;
	private String lastText;

	private View view;

	private BarcodeCallback callback = new BarcodeCallback() {
		@Override
		public void barcodeResult(BarcodeResult result) {
			if(result.getText() == null || result.getText().equals(lastText)) {
				// Prevent duplicate scans
				return;
			}

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
		barcodeView.decodeContinuous(callback);

		beepManager = new BeepManager(getActivity());
		return view;
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
		//TODO do something!!!
//		this.barcodeView.getBarcodeView().setCameraSettings();
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
