Cordova Plugin Embedded Barcode Reader
====================

Cordova plugin that allows barcode interaction from HTML for showing camera preview below or above the HTML.<br/>

Plugin architecture and some base code is based on https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview

# Features

<ul>
  <li>Start a barcode reader preview from HTML code.</li>
  <li>Send the preview box to back of the HTML content.</li>
  <li>Set a custom position for the barcode preview box.</li>
  <li>Set a custom size for the preview box.</li>
  <li>Maintain HTML interactivity.</li>
</ul>

# Installation

Use any one of the installation methods listed below depending on which framework you use.

```
cordova plugin add https://github.com/CodifiLLC/cordova-plugin-embedded-barcode-reader.git

ionic plugin add https://github.com/CodifiLLC/cordova-plugin-embedded-barcode-reader.git

<plugin spec="https://github.com/CodifiLLC/cordova-plugin-embedded-barcode-reader.git" source="git" />
```

# Methods

### startCamera(options, [successCallback, errorCallback])

Starts the barcode preview instance.
<br>

<strong>Options:</strong>
All options stated are optional and will default to values here

* `x` - Defaults to 0
* `y` - Defaults to 0
* `width` - Defaults to window.screen.width
* `height` - Defaults to window.screen.height
* `camera` - See <code>[CAMERA_DIRECTION](#camera_Settings.CameraDirection)</code> - Defaults to front camera/code>
* `toBack` - Defaults to false - Set to true if you want your html in front of your preview

```javascript
let options = {
  x: 0,
  y: 0,
  width: window.screen.width,
  height: window.screen.height,
  camera: EmbeddedBarcodeReader.CAMERA_DIRECTION.BACK,
  toBack: false
};

EmbeddedBarcodeReader.startCamera(options);
```

When setting the toBack to true, remember to add the style below on your app's HTML or body element:

```css
html, body, .ion-app, .ion-content {
  background-color: transparent;
}
```

### stopCamera([successCallback, errorCallback])

<info>Stops the barcode preview instance.</info><br/>

```javascript
EmbeddedBarcodeReader.stopCamera();
```

### switchCamera([successCallback, errorCallback])

<info>Switch between the rear camera and front camera, if available.</info><br/>

```javascript
EmbeddedBarcodeReader.switchCamera();
```

### show([successCallback, errorCallback])

<info>Show the preview box.</info><br/>

```javascript
EmbeddedBarcodeReader.show();
```

### hide([successCallback, errorCallback])

<info>Hide the preview box.</info><br/>

```javascript
EmbeddedBarcodeReader.hide();
```

### addBarcodeReadListener(options, successCallback, [errorCallback])

<info>
	Adds a listener event for barcodes being read. You will need to a new listener in order to get back the barcodes.
	Everytime a barcode is read, the barcode result will be returned as a string to your callback.
</info><br/>

```javascript
EmbeddedBarcodeReader.addBarcodeReadListener(function(readBarcode){
  // Log the barcode
  console.log('We just read another barcode', readBarcode);
});

```

Note: the app will not report the same barcode via the callback if read back-to-back within 7 seconds.


# Settings

<a name="camera_Settings.CameraDirection"></a>

### CAMERA_DIRECTION

<info>Camera direction settings:</info><br/>

| Name | Type | Default |
| --- | --- | --- |
| BACK | string | back |
| FRONT | string | front |


# Credits

Based on Cordova Camera Preview https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview
