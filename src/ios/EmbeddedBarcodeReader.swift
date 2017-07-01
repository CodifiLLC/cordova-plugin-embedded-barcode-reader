import Foundation
import AVFoundation

@objc(EmbeddedBarcodeReader) class EmbeddedBarcodeReader: CDVPlugin, AVCaptureMetadataOutputObjectsDelegate {
    
    class CameraPreview: UIViewController {
        var videoPreviewLayer:AVCaptureVideoPreviewLayer?
        var qrCodeFrameView:UIView?
        
        override func viewDidLoad() {
            super.viewDidLoad()
        }
    }
    
    var cameraPreview: CameraPreview!
    var captureSession:AVCaptureSession?
    var barcodeReadCallback:String?
    
    var xPoint:CGFloat = 0.0
    var yPoint:CGFloat = 0.0
    var width:CGFloat = 0.0
    var height:CGFloat = 0.0
    
    func startReading(_ command: CDVInvokedUrlCommand) {
        cameraPreview = CameraPreview();
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        do {
            xPoint = CGFloat((command.arguments[0] as AnyObject!).floatValue) + self.webView.frame.origin.x
            yPoint = CGFloat((command.arguments[1] as AnyObject!).floatValue) + self.webView.frame.origin.y
            width = CGFloat((command.arguments[2] as AnyObject!).floatValue)
            height = CGFloat((command.arguments[3] as AnyObject!).floatValue)
            
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            cameraPreview.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraPreview.videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            //            videoPreviewLayer?.frame = view.layer.bounds
            cameraPreview.videoPreviewLayer?.frame = CGRect.init(x: xPoint, y: yPoint, width: width, height: height)
            self.webView?.backgroundColor = UIColor.clear
            self.webView?.isOpaque = false
            self.webView?.layer.addSublayer(cameraPreview.videoPreviewLayer!)
            self.webView.superview?.bringSubview(toFront: self.webView)
            
            // Start video capture.
            captureSession?.startRunning()
            
            // Move the message label and top bar to the front
            //            view.bringSubview(toFront: messageLabel)
            //            view.bringSubview(toFront: topbar)
            
            // Initialize QR Code Frame to highlight the QR code
            cameraPreview.qrCodeFrameView = UIView()
            
            cameraPreview.qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
            cameraPreview.qrCodeFrameView?.layer.borderWidth = 2
            self.webView?.addSubview(cameraPreview.qrCodeFrameView!)
            self.webView?.bringSubview(toFront: cameraPreview.qrCodeFrameView!)
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera Started")
        commandDelegate!.send(pluginResult, callbackId:command.callbackId)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            cameraPreview.qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = cameraPreview.videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            cameraPreview.qrCodeFrameView?.frame = CGRect.init(x: self.xPoint + barCodeObject!.bounds.minX, y: self.yPoint + barCodeObject!.bounds.minY, width: barCodeObject!.bounds.width, height: barCodeObject!.bounds.height)
            
            if metadataObj.stringValue != nil {
                if (self.barcodeReadCallback != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: metadataObj.stringValue)
                    commandDelegate!.send(pluginResult, callbackId:self.barcodeReadCallback)
                }
            }
        }
    }
    
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        if let potentialDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            for device in potentialDevices {
                let device = device as! AVCaptureDevice
                if device.position == position {
                    return device
                }
            }
        }
        
        return nil
    }
    
    //API methods for cordova
    
    func startListening(_ command: CDVInvokedUrlCommand) {
        //add addListener
        print("listening")
        barcodeReadCallback = command.callbackId
    }
    
    func stopReading(_ command: CDVInvokedUrlCommand) {
        //stop camera
        captureSession?.stopRunning()
        cameraPreview.videoPreviewLayer?.removeFromSuperlayer()
        cameraPreview.videoPreviewLayer = nil
        self.barcodeReadCallback = nil
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera Stopped")
        commandDelegate!.send(pluginResult, callbackId:command.callbackId)
    }
    
    func hideCamera(_ command: CDVInvokedUrlCommand) {
        //hide camera
    }
    
    func showCamera(_ command: CDVInvokedUrlCommand) {
        //show camera
    }
    
    func switchCamera(_ command: CDVInvokedUrlCommand) {
        //switch camera
        if let session = captureSession {
            //Indicate that some changes will be made to the session
            session.beginConfiguration()
            
            //Remove existing input
            let currentCameraInput: AVCaptureInput = (session.inputs.first as? AVCaptureInput)!
            
            session.removeInput(currentCameraInput)
            
            //Get new input
            var newCamera: AVCaptureDevice! = nil
            if let input = currentCameraInput as? AVCaptureDeviceInput {
                if (input.device.position == .back) {
                    newCamera = cameraWithPosition(position: .front)
                } else {
                    newCamera = cameraWithPosition(position: .back)
                }
            }
            
            //Add input to session
            var err: NSError?
            var newVideoInput: AVCaptureDeviceInput!
            do {
                newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            } catch let err1 as NSError {
                err = err1
                newVideoInput = nil
            }
            
            if newVideoInput == nil || err != nil {
                print("Error creating capture device input")
            } else {
                session.addInput(newVideoInput)
            }
            
            //Commit all the configuration changes at once
            session.commitConfiguration()
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera Switched")
            commandDelegate!.send(pluginResult, callbackId:command.callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Couldn't switch")
            commandDelegate!.send(pluginResult, callbackId:command.callbackId)
        }
        
    }
    
    func getSupportedFlashModes(_ command: CDVInvokedUrlCommand) {
        //get supported flash modes
    }
    
    func setFlashMode(_ command: CDVInvokedUrlCommand) {
        //set flash mode
    }
    
    func setPreviewSize(_ command: CDVInvokedUrlCommand) {
        //set preview size
    }
}
