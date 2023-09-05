var exec = require('cordova/exec');

const CONST_NATIVE_MODULE_NAME = 'FibriCheckCordovaSDK'

const DEFAULT_CONFIG_PROPS = {
    sampleTime: 60,
    flashEnabled: true,
    gravEnabled: false,
    gyroEnabled: false,
    accEnabled: false,
    rotationEnabled: false,
    movementDetectionEnabled: true,
    fingerDetectionExpiryTime: -1,
    pulseDetectionExpiryTime: 10,
    waitForStartRecordingSignal: false,
};

function handleNativeErrorFactory (source) {
    return (err) => {
        console.log(`Native error in ${source}: `, err);
    }
}

exports.initialise = function () {
    return new Promise((resolve, reject) => {
        // Initialise FibriCheck Layer
        exec(() => {
            resolve()
        },
        (err) => {
            reject(err);
        }, 
        CONST_NATIVE_MODULE_NAME, 
        'initialise'
        );
    })   
};

exports.updateConfiguration = function(properties) {
    return new Promise((resolve, reject) => {
        const mergedProps = {...DEFAULT_CONFIG_PROPS, ...properties};

        exec(() => {
            resolve();
        }, (err) => {
            reject(err);
        }, 
        CONST_NATIVE_MODULE_NAME, 
        'updateConfiguration',
        [JSON.stringify(mergedProps)]
        );
    })
}

exports.startMeasurement = function () {
    return new Promise((resolve, reject) => {
        exec(() => {
            resolve()
        },
        (err) => {
            reject(err)
        }, 
        CONST_NATIVE_MODULE_NAME, 
        'startMeasurement'
        );
    });
}

exports.stopMeasurement = function() {
    return new Promise((resolve, reject) => {
        exec(() => {
            resolve()
        },
        (err) => {
            reject(err)
        }, 
        CONST_NATIVE_MODULE_NAME, 
        'stopMeasurement'
        );
    });
}

// Callbacks
exports.onSampleReady = function(callback) {
    exec((nativeData) => {
        const {ppg, raw} = JSON.parse(nativeData)
        callback(ppg, raw);
    }, 
    handleNativeErrorFactory('onSampleReady'), 
    CONST_NATIVE_MODULE_NAME, 
    'onSampleReady')
}

exports.onFingerDetected = function(callback) {
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onFingerDetected'),
    CONST_NATIVE_MODULE_NAME,
    'onFingerDetected');
}

exports.onFingerRemoved = function(callback) {
    exec((nativeData) => {
        const {y, v, stdDev} = JSON.parse(nativeData)
        callback(y, v, stdDev);
    }, 
    handleNativeErrorFactory('onFingerRemoved'),
    CONST_NATIVE_MODULE_NAME, 
    'onFingerRemoved')
}

exports.onCalibrationReady = function(callback) {
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onCalibrationReady'),
    CONST_NATIVE_MODULE_NAME,
    'onCalibrationReady');
}

exports.onHeartBeat = function(callback) {
    exec((nativeData) => {
        const heartrate = parseInt(nativeData);
        callback(heartrate)

    }, 
    handleNativeErrorFactory('onHeartBeat'),
    CONST_NATIVE_MODULE_NAME, 
    'onHeartBeat');
}

exports.onTimeRemaining = function(callback){
    exec((nativeData) => {
        const seconds = parseInt(nativeData);
        callback(seconds);
    },
    handleNativeErrorFactory('onTimeRemaining'),
    CONST_NATIVE_MODULE_NAME,
    'onTimeRemaining');
}

exports.onMeasurementFinished = function(callback){
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onMeasurementFinished'),
    CONST_NATIVE_MODULE_NAME,
    'onMeasurementFinished');
}

exports.onMeasurementStart = function(callback){
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onMeasurementStart'),
    CONST_NATIVE_MODULE_NAME,
    'onMeasurementStart');
}

exports.onFingerDetectionTimeExpired = function(callback){
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onFingerDetectionTimeExpired'),
    CONST_NATIVE_MODULE_NAME,
    'onFingerDetectionTimeExpired');
}

exports.onPulseDetected = function(callback){
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onPulseDetected'),
    CONST_NATIVE_MODULE_NAME,
    'onPulseDetected');
}

exports.onPulseDetectionTimeExpired = function(callback){
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onPulseDetectionTimeExpired'),
    CONST_NATIVE_MODULE_NAME,
    'onPulseDetectionTimeExpired');
}

exports.onMovementDetected = function(callback){
    exec(() => {
        callback();
    },
    handleNativeErrorFactory('onMovementDetected'),
    CONST_NATIVE_MODULE_NAME,
    'onMovementDetected');
}

exports.onMeasurementProcessed = function(callback){
    exec((nativeData) => {
        const result = JSON.parse(nativeData);
        callback(result);
    }, 
    handleNativeErrorFactory('onMeasurementProcessed'),
    CONST_NATIVE_MODULE_NAME, 
    'onMeasurementProcessed')
}

exports.onMeasurementError = function(callback){
    exec((errorString) => {
        callback(errorString);
    }, 
    handleNativeErrorFactory('onMeasurementError'),
    CONST_NATIVE_MODULE_NAME, 
    'onMeasurementError')
}




