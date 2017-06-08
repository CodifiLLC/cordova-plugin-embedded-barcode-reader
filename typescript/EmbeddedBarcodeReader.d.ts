interface EmbeddedBarcodeReader {
  addBarcodeReadListener(onSuccess?:any, onError?:any):any;
  startCamera(options?:any, onSuccess?:any, onError?:any):any;
  stopCamera(onSuccess?:any, onError?:any):any;
  switchCamera(onSuccess?:any, onError?:any):any;
  hide(onSuccess?:any, onError?:any):any;
  show(onSuccess?:any, onError?:any):any;
  getSupportedFlashModes(onSuccess?:any, onError?:any):any;
  setFlashMode(flashMode:string, onSuccess?:any, onError?:any):any;
}
