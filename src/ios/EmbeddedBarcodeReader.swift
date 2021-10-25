import Foundation
import AVFoundation

@objc(EmbeddedBarcodeReader) class EmbeddedBarcodeReader: CDVPlugin, AVCaptureMetadataOutputObjectsDelegate {

    class CameraPreview: UIView {
        var videoPreviewLayer:AVCaptureVideoPreviewLayer?
        var qrCodeFrameView:UIView?

        func interfaceOrientationToVideoOrientation(_ orientation : UIInterfaceOrientation) -> AVCaptureVideoOrientation {
            switch (orientation) {
            case UIInterfaceOrientation.portrait:
                return AVCaptureVideoOrientation.portrait;
            case UIInterfaceOrientation.portraitUpsideDown:
                return AVCaptureVideoOrientation.portraitUpsideDown;
            case UIInterfaceOrientation.landscapeLeft:
                return AVCaptureVideoOrientation.landscapeLeft;
            case UIInterfaceOrientation.landscapeRight:
                return AVCaptureVideoOrientation.landscapeRight;
            default:
                return AVCaptureVideoOrientation.portraitUpsideDown;
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews();
            if let sublayers = self.layer.sublayers {
                for layer in sublayers {
                    layer.frame = self.bounds;
                }
            }

            self.videoPreviewLayer?.connection?.videoOrientation = interfaceOrientationToVideoOrientation(UIApplication.shared.statusBarOrientation);
        }

        func addPreviewLayer() {
            videoPreviewLayer?.frame = self.bounds
            self.backgroundColor = UIColor.clear
            self.layer.addSublayer(videoPreviewLayer!)
        }

        func removePreviewLayer() {
            self.videoPreviewLayer?.removeFromSuperlayer()
            self.videoPreviewLayer = nil
        }
    }

    var cameraPreview: CameraPreview!
    var captureSession:AVCaptureSession?
    var barcodeReadCallback:String?

    var xPoint:CGFloat = 0.0
    var yPoint:CGFloat = 0.0
    var width:CGFloat = 0.0
    var height:CGFloat = 0.0
    var lastRead:String? = nil
    var lastTimeRead: Date = Date.init()
    var captureDevice: AVCaptureDevice?

    override func pluginInitialize() {
        super.pluginInitialize()
        self.webView!.backgroundColor = UIColor.clear
        self.webView!.isOpaque = false
    }

    @objc(startReading:) func startReading(_ command: CDVInvokedUrlCommand) {
//        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let cameraDefault = (command.arguments[4] as AnyObject?) as? String ?? "back"

        if (cameraDefault == "front") {
            captureDevice = ((AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified).devices)
                .filter({ $0.hasMediaType(AVMediaType.video) && $0.position == .front}).first)
        } else {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        }

        do {
            xPoint = CGFloat((command.arguments[0] as AnyObject).floatValue) + self.webView.frame.origin.x
            yPoint = CGFloat((command.arguments[1] as AnyObject).floatValue) + self.webView.frame.origin.y
            width = CGFloat((command.arguments[2] as AnyObject).floatValue)
            height = CGFloat((command.arguments[3] as AnyObject).floatValue)

            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice!)

            // Initialize the captureSession object.
            captureSession = AVCaptureSession()

            // Set the input device on the capture session.
            captureSession?.addInput(input)

            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)

            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            cameraPreview = CameraPreview(frame: CGRect(x: xPoint, y: yPoint, width: width, height: height));
            cameraPreview.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            cameraPreview.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            //            videoPreviewLayer?.frame = view.layer.bounds
            self.webView!.backgroundColor = UIColor.clear
            self.webView!.isOpaque = false
            self.webView!.superview!.addSubview(cameraPreview!)
            self.webView!.superview!.bringSubviewToFront(self.webView)
//            self.webView!.superview!.sendSubview(toBack: cameraPreview!)
            cameraPreview.addPreviewLayer();

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
            self.webView?.bringSubviewToFront(cameraPreview.qrCodeFrameView!)

        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera Started")
        commandDelegate!.send(pluginResult, callbackId:command.callbackId)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection)  {

        var newReadTime: Date
        var milsSinceLastRead: Double

        // Check if the metadataObjects array contains at least one object.
        if metadataObjects.count == 0 {
            cameraPreview.qrCodeFrameView?.frame = CGRect.zero
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let currentObj = metadataObj.stringValue
            let barCodeObject = cameraPreview.videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            cameraPreview.qrCodeFrameView?.frame = CGRect.init(x: self.xPoint + barCodeObject!.bounds.minX, y: self.yPoint + barCodeObject!.bounds.minY, width: barCodeObject!.bounds.width, height: barCodeObject!.bounds.height)

            if metadataObj.stringValue != nil {
                if (self.barcodeReadCallback != nil) {
                    newReadTime = Date.init()
                    milsSinceLastRead = newReadTime.timeIntervalSince(lastTimeRead)
                    if (lastRead == currentObj && milsSinceLastRead < 7) {
                        return
                    }
                    lastTimeRead = newReadTime
                    lastRead = metadataObj.stringValue!

                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: metadataObj.stringValue)
                    pluginResult!.setKeepCallbackAs(true)
                    commandDelegate!.send(pluginResult, callbackId:self.barcodeReadCallback)
                }
            }
        }
    }

    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let potentialDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified).devices
        for device in potentialDevices {
            //let device = device as! AVCaptureDevice
            if device.position == position {
                return device
            }
        }


        return nil
    }

    //API methods for cordova

    @objc(startListening:) func startListening(_ command: CDVInvokedUrlCommand) {
        //add addListener
        print("listening")
        barcodeReadCallback = command.callbackId
    }

    @objc(stopReading:) func stopReading(_ command: CDVInvokedUrlCommand) {
        //stop camera
        captureSession?.stopRunning()
        cameraPreview.removePreviewLayer()
        cameraPreview.videoPreviewLayer = nil
        self.barcodeReadCallback = nil
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera Stopped")
        commandDelegate!.send(pluginResult, callbackId:command.callbackId)
    }

    @objc(hideCamera:) func hideCamera(_ command: CDVInvokedUrlCommand) {
        //hide camera
    }

    @objc(showCamera:) func showCamera(_ command: CDVInvokedUrlCommand) {
        //show camera
    }

    @objc(switchCamera:) func switchCamera(_ command: CDVInvokedUrlCommand) {
        //switch camera
        if let session = captureSession {
            //Indicate that some changes will be made to the session
            session.beginConfiguration()

            //Remove existing input
            let currentCameraInput: AVCaptureInput = (session.inputs.first)!

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

    @objc(getSupportedFlashModes:) func getSupportedFlashModes(_ command: CDVInvokedUrlCommand) {
        //get supported flash modes
    }

    @objc(setFlashMode:) func setFlashMode(_ command: CDVInvokedUrlCommand) {
          print("Flash Mode");
//          let errMsg = "";
//
//          let flashMode = (command.arguments[0] as AnyObject!) as? String;
//
//          if (captureSession != nil) {
//            if (flashMode == "off") {
//                [self.sessionManager, setFlashMode:AVCaptureFlashModeOff];
//            } else if ([flashMode isEqual: "on"]) {
//              [self.sessionManager setFlashMode:AVCaptureFlashModeOn];
//            } else if ([flashMode isEqual: "auto"]) {
//              [self.sessionManager setFlashMode:AVCaptureFlashModeAuto];
//            } else if ([flashMode isEqual: "torch"]) {
//              [self.sessionManager setTorchMode];
//            } else {
//              errMsg = "Flash Mode not supported";
//            }
//          } else {
//            errMsg = "Session not started";
//          }
//
//          if (errMsg) {
//            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errMsg);
//            commandDelegate!.send(pluginResult, callbackId:command.callbackId)
//          } else {
//            let pluginResult = CDVPluginResult(status: OK, messageAs: flashMode);
//            commandDelegate!.send(pluginResult, callbackId:command.callbackId)
//          }
    }

    func setPreviewSize(_ command: CDVInvokedUrlCommand) {
        //set preview size
    }
}
