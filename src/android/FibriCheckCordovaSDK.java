package com.qompium.fibricheck_cordova_sdk;


import java.util.Hashtable;

import android.Manifest;
import android.content.Context;
import android.util.Log;
import android.widget.LinearLayout;

import com.qompium.fibricheck.camerasdk.FibriChecker;
import com.qompium.fibricheck.camerasdk.listeners.FibriListener;
import com.qompium.fibricheck.camerasdk.measurement.MeasurementData;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.google.gson.Gson;

/**
 * This class echoes a string called from JavaScript.
 */


public class FibriCheckCordovaSDK extends CordovaPlugin {
    private static final String TAG = "FibriCheck-Cordova-SDK";
    private FibriChecker fibriChecker;
    private LinearLayout linearLayout;
    Hashtable<String, CallbackContext> callbacks;


    private CallbackContext eventCallback;

    public static final String CAMERA = Manifest.permission.CAMERA;
    public static final int CAMERA_REQ_CODE = 0;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("initialise")) {
            this.initialise(callbackContext);
            return true;
        } else if(action.equals("startMeasurement")){
            this.startMeasurement(callbackContext);
            return true;
        } else if(action.equals("stopMeasurement")){
            this.stopMeasurement(callbackContext);
            return true;
        } else if(action.equals("updateConfiguration")){
            this.updateConfiguration(callbackContext, args.getString(0));
            return true;
        } else if(action.matches("onSampleReady|onFingerDetected|onFingerRemoved|onCalibrationReady|onHeartBeat|onTimeRemaining|onMeasurementFinished|onMeasurementStart|onFingerDetectionTimeExpired|onPulseDetected|onPulseDetectionTimeExpired|onMovementDetected|onMeasurementProcessed|onMeasurementError")){
            registerEventHandler(action, callbackContext);
            return true;

        }
        return false;
    }

    protected void getCameraPermission(int requestCode){
        cordova.requestPermission(this, requestCode, CAMERA);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException
    {
        //TODO: Implement override
        Log.i(TAG, "Return Permissions Result");
    }
    private void initialise(CallbackContext callbackContext) {

        Context context = this.cordova.getContext();
        FibriCheckCordovaSDK self = this;
        callbacks = new Hashtable<String, CallbackContext>();

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {

                linearLayout = new LinearLayout(context);
                linearLayout.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT));
                linearLayout.setOrientation(LinearLayout.HORIZONTAL);

                cordova.getActivity().addContentView(linearLayout, linearLayout.getLayoutParams());

                if (!cordova.hasPermission(CAMERA)) {
                    getCameraPermission(CAMERA_REQ_CODE);
                }

                // Get Root View
                fibriChecker = new FibriChecker.FibriBuilder(linearLayout.getContext(), linearLayout).build();

                fibriChecker.setFibriListener(new FibriListener() {
                    @Override
                    public void onSampleReady(final double ppg, double raw) {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("ppg", ppg);
                            obj.put("raw", raw);

                            self.sendEvent("onSampleReady",obj.toString());

                        }catch(Exception e){
                            Log.e(TAG, e.toString());
                        }
                    }

                    @Override
                    public void onFingerDetected() {
                        self.sendEventWithoutData("onFingerDetected");
                    }

                    @Override
                    public void onFingerRemoved(double y, double v, double stdDevY) {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("y", y);
                            obj.put("v", v);
                            obj.put("stdDev", stdDevY);
                            self.sendEvent("onFingerRemoved", obj.toString());
                        } catch (JSONException e){
                            Log.e(TAG, e.toString());
                        }
                    }

                    @Override
                    public void onCalibrationReady() {
                        self.sendEventWithoutData("onCalibrationReady");
                    }

                    @Override
                    public void onHeartBeat(int value) {
                        self.sendEvent("onHeartBeat", Integer.toString(value));
                    }

                    @Override
                    public void onTimeRemaining(int seconds) {
                        // Choosing for `onTimeRemaining`, most consistent across Camera SDK's (iOS, React Native, Flutter)
                        self.sendEvent("onTimeRemaining", Integer.toString(seconds));
                    }

                    @Override
                    public void onMeasurementFinished() {
                        self.sendEventWithoutData("onMeasurementFinished");
                    }

                    @Override
                    public void onMeasurementStart() {
                        self.sendEventWithoutData("onMeasurementStart");
                    }

                    @Override
                    public void onFingerDetectionTimeExpired() {
                        self.sendEventWithoutData("onFingerDetectionTimeExpired");
                    }

                    @Override
                    public void onPulseDetected() {
                        self.sendEventWithoutData("onPulseDetected");
                    }

                    @Override
                    public void onPulseDetectionTimeExpired() {
                        self.sendEventWithoutData("onPulseDetectionTimeExpired");
                    }

                    @Override
                    public void onMovementDetected() {
                        self.sendEventWithoutData("onMovementDetected");
                    }

                    @Override
                    public void onMeasurementProcessed(MeasurementData measurementData) {
                        try {
                            Log.i(TAG, "Processed FibriCheck Measurement");
                            Gson gson = new Gson();
                            JSONObject jsonObject = new JSONObject(gson.toJson(measurementData));
                            String measurementJson = jsonObject.toString();

                            self.sendEvent("onMeasurementProcessed", measurementJson);

                        } catch(Exception e) {
                            Log.e(TAG, e.toString());
                        }
                    }

                    @Override
                    public void onMeasurementError(String message) {
                        try {
                            self.sendEvent("onMeasurementError", message);
                        } catch(Exception e) {
                            Log.e(TAG, e.toString());
                        }
                   }
                });

                callbackContext.success();
            }
        });
    }

    private void sendEventWithoutData(String eventName){
        if(callbacks.containsKey(eventName)){
            CallbackContext callback = callbacks.get(eventName);
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
            pluginResult.setKeepCallback(true);
            callback.sendPluginResult(pluginResult);
        }
    }

    private void sendEvent(String eventName, String data){
        if(callbacks.containsKey(eventName)){
            CallbackContext callback = callbacks.get(eventName);

            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, data);
            pluginResult.setKeepCallback(true);
            callback.sendPluginResult(pluginResult);
        }

    }

    private void registerEventHandler(String type, CallbackContext callbackContext){
        // Store callback in a hashtable for later usage
        callbacks.put(type, callbackContext);
    }

    private void startMeasurement(CallbackContext callbackContext) {

       cordova.getActivity().runOnUiThread(new Runnable() {
           @Override
           public void run() {
               try {
                   fibriChecker.start();
                   callbackContext.success();
               } catch (Exception e) {
                   Log.e(TAG, e.toString());
                   callbackContext.error("Err");
               }
           }
       });
    }

    private void stopMeasurement(CallbackContext callbackContext) {
        fibriChecker.stop();
        callbackContext.success();
    }

    private void updateConfiguration(CallbackContext callbackContext, String jsonConfigString) {

        try {
            JSONObject jsonConfig = new JSONObject(jsonConfigString);
            fibriChecker.sampleTime = jsonConfig.getInt("sampleTime");

            callbackContext.success();

        } catch (JSONException e){
            callbackContext.error(e.toString());
        }
    }
    }