import Foundation
import AVFoundation
import FibriCheckCameraSDK

struct FibriCheckConfiguration: Decodable {
    let sampleTime: UInt?
    let flashEnabled: Bool?
    let gravEnabled: Bool?
    let gyroEnabled: Bool?
    let accEnabled: Bool?
    let rotationEnabled: Bool?
    let movementDetectionEnabled: Bool?
    let fingerDetectionExpiryTime: Int?
    let pulseDetectionExpiryTime: UInt?
    let waitForStartRecordingSignal: Bool?
}


@objc(FibriCheckCordovaSDK) class FibriCheckCordovaSDK: CDVPlugin {

    var fibricheckerInstance: FibriChecker?

    @objc(initialise:)
    func initialise(command: CDVInvokedUrlCommand) {

        let rootSelf = self

        var isAuthorized: Bool {
            get async {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                
                // Determine if the user previously authorized camera access.
                var isAuthorized = status == .authorized
                
                // If the system hasn't determined the user's authorization status,
                // explicitly prompt them for approval.
                if status != .authorized {
                    isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
                }
                
                return isAuthorized
            }
        }
        
        Task {
            await isAuthorized         

            rootSelf.fibricheckerInstance = FibriChecker()

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }

    }

    @objc(updateConfiguration:)
    func updateConfiguration(command: CDVInvokedUrlCommand) {
        
        let dataString: String = String(describing: command.arguments[0])
        // Get JSON Properties
        let fcConfig: FibriCheckConfiguration = try! JSONDecoder().decode(FibriCheckConfiguration.self, from: dataString.data(using: .utf8)!)
                
        if let flashEnabled = fcConfig.flashEnabled {
            self.fibricheckerInstance?.flashEnabled = flashEnabled
        }
        
        if let sampleTime = fcConfig.sampleTime {
            self.fibricheckerInstance?.sampleTime = sampleTime
        }
        
        if let gravEnabled = fcConfig.gravEnabled {
            self.fibricheckerInstance?.gravEnabled = gravEnabled
        }
        
        if let gyroEnabled = fcConfig.gyroEnabled {
            self.fibricheckerInstance?.gyroEnabled = gyroEnabled
        }
        
        if let accEnabled = fcConfig.accEnabled {
            self.fibricheckerInstance?.accEnabled = accEnabled
        }
        
        if let rotationEnabled = fcConfig.rotationEnabled {
            self.fibricheckerInstance?.rotationEnabled = rotationEnabled
        }
        
        if let movementDetectionEnabled = fcConfig.movementDetectionEnabled {
            self.fibricheckerInstance?.movementDetectionEnabled = movementDetectionEnabled
        }
        
        if let fingerDetectionExpiryTime = fcConfig.fingerDetectionExpiryTime {
            // @TODO: Leftover from negative number assignment to UInt in ObjectiveC, needs to be updated
            self.fibricheckerInstance?.fingerDetectionExpiryTime = UInt.init(bitPattern: fingerDetectionExpiryTime)
        }
        
        if let pulseDetectionExpiryTime = fcConfig.pulseDetectionExpiryTime {
            self.fibricheckerInstance?.pulseDetectionExpiryTime = pulseDetectionExpiryTime

        }
        
        if let waitForStartRecordingSignal = fcConfig.waitForStartRecordingSignal {
            self.fibricheckerInstance?.waitForStartRecordingSignal = waitForStartRecordingSignal
        }



        let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(startMeasurement:)
    func startMeasurement(command: CDVInvokedUrlCommand) {
        
        let rootSelf = self

        var isAuthorized: Bool {
            get async {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                
                // Determine if the user previously authorized camera access.
                var isAuthorized = status == .authorized
                
                // If the system hasn't determined the user's authorization status,
                // explicitly prompt them for approval.
                if status != .authorized {
                    isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
                }
                
                return isAuthorized
            }
        }

        Task {
            guard await isAuthorized else {
                rootSelf.commandDelegate!.send(
                    CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: "NO_CAMERA_PERMISSION"
                    ),
                    callbackId: command.callbackId
                )
                return
            }
            
            Task.detached(priority: .background){
                rootSelf.fibricheckerInstance?.startMeasurement();
            }

            let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK
                )
            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(stopMeasurement:)
    func stopMeasurement(command: CDVInvokedUrlCommand) {
        
        let rootSelf = self
        
        rootSelf.fibricheckerInstance?.stop();

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK
        )
        rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(onHeartBeat:)
    func onHeartBeat(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onHeartBeat = {
            (heartrate: UInt) -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: heartrate
            )
            
            pluginResult?.setKeepCallbackAs(true)
            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onTimeRemaining:)
    func onTimeRemaining(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onTimeRemaining = {
            (seconds: UInt) -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: seconds
            )
            
            pluginResult?.setKeepCallbackAs(true)
            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onSampleReady:)
    func onSampleReady(command: CDVInvokedUrlCommand) {
        let rootSelf = self 

        fibricheckerInstance?.onSampleReady = {
            (ppg: Double, raw: Double) -> () in

            let resultsDict = [
                "ppg": ppg,
                "raw": raw
            ]
            
            do {                
                let resultsJson = try JSONSerialization.data(withJSONObject: resultsDict,options: .prettyPrinted)

                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: String(data: resultsJson, encoding: String.Encoding.ascii)
                )
                
                pluginResult?.setKeepCallbackAs(true)
                rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                
            } catch {
                // @TODO: Properly Hanlde Error
            }       
        }
    }


    @objc(onFingerDetected:)
    func onFingerDetected(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onFingerDetected = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onFingerRemoved:)
    func onFingerRemoved(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onFingerRemoved = {
            (y: Double, v: Double, stdDev: Double) -> () in

            let resultsDict = [
                "y": y,
                "v": v,
                "stdDev": stdDev
            ]
            
            do {                
                let resultsJson = try JSONSerialization.data(withJSONObject: resultsDict,options: .prettyPrinted)

                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: String(data: resultsJson, encoding: String.Encoding.ascii)
                )
                
                pluginResult?.setKeepCallbackAs(true)
                rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                
            } catch {
                // @TODO: Properly Hanlde Error
            }       
        }
    }

    @objc(onCalibrationReady:)
    func onCalibrationReady(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onCalibrationReady = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onMeasurementFinished:)
    func onMeasurementFinished(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onMeasurementFinished = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onMeasurementStart:)
    func onMeasurementStart(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onMeasurementStart = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onFingerDetectionTimeExpired:)
    func onFingerDetectionTimeExpired(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onFingerDetectionTimeExpired = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onPulseDetected:)
    func onPulseDetected(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onPulseDetected = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onPulseDetectionTimeExpired:)
    func onPulseDetectionTimeExpired(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onPulseDetectionTimeExpired = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onMovementDetected:)
    func onMovementDetected(command: CDVInvokedUrlCommand) {
        let rootSelf = self

        fibricheckerInstance?.onMovementDetected = {
            () -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)

            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onMeasurementProcessed:)
    func onMeasurementProcessed(command: CDVInvokedUrlCommand) {
        let rootSelf = self

         fibricheckerInstance?.onMeasurementProcessed = {
            (measurementData: FibriCheckCameraSDK.Measurement?) -> () in

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: measurementData?.mapToJson()
            )
            
            pluginResult?.setKeepCallbackAs(true)
            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(onMeasurementError:)
    func onMeasurementError(command: CDVInvokedUrlCommand) {
        let rootSelf = self

         fibricheckerInstance?.onMeasurementError = {
            (measurementError: String?) -> () in    

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: measurementError
            )
            
            pluginResult?.setKeepCallbackAs(true)
            rootSelf.commandDelegate!.send(pluginResult, callbackId: command.callbackId)          
        }
    }
}
