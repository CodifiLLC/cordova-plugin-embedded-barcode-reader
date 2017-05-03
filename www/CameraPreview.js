var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {};

function isFunction(obj) {
    return !!(obj && obj.constructor && obj.call && obj.apply);
};

CameraPreview.startCamera = function(options, onSuccess, onError) {
    options = options || {};
    options.x = options.x || 0;
    options.y = options.y || 0;
    options.width = options.width || window.screen.width;
    options.height = options.height || window.screen.height;
    options.camera = options.camera || CameraPreview.CAMERA_DIRECTION.FRONT;
    if (typeof(options.tapPhoto) === 'undefined') {
        options.tapPhoto = true;
    }
    options.previewDrag = options.previewDrag || false;
    options.toBack = options.toBack || false;
    if (typeof(options.alpha) === 'undefined') {
        options.alpha = 1;
    }

    exec(onSuccess, onError, PLUGIN_NAME, "startReading", [options.x, options.y, options.width, options.height, options.camera, options.tapPhoto, options.previewDrag, options.toBack, options.alpha]);
};

CameraPreview.addBarcodeReadListener = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "startListening", []);
};

CameraPreview.stopCamera = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "stopReading", []);
};

CameraPreview.switchCamera = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.getSupportedFlashModes = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getSupportedFlashModes", []);
};

CameraPreview.setFlashMode = function(flashMode, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setFlashMode", [flashMode]);
};

CameraPreview.FLASH_MODE = {
    OFF: 'off',
    ON: 'on',
    AUTO: 'auto',
    RED_EYE: 'red-eye', // Android Only
    TORCH: 'torch'
};

CameraPreview.CAMERA_DIRECTION = {
    BACK: 'back',
    FRONT: 'front'
};

module.exports = CameraPreview;
