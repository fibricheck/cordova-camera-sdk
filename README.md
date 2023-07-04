# FibriCheck Cordova Camera SDK
The FibriCheck Cordova Camera SDK is a plugin for the Cordova platform. Using this plugin you can integrate the FibriCheck heart rhythm detection technology in your Cordova application. This plugin supports iOS and Android.

## Install - Access to dependencies
This plugin is a wrapper around the FibriCheck native SDK's for iOS and Android. To use this plugin, your project also needs access to these native SDK's. Setting up access differs for each platform.

### Android
The [Android SDK](https://github.com/fibricheck/android-camera-sdk) is hosted on GPR (GitHub Package Registry) and requires authentication using GitHub credentials. See ["Creating a personal access token"](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) in the GitHub documentation for more information. To supply these credentials to the build process of your Android project, there are two options: 

**Environment variables:**
You can make the credentials available through environment variables.
```
export GITHUB_USERNAME=
export GITHUB_TOKEN=
```

**Gradle properties:**
You can store your GitHub credentials locally in a gradle properties file, e.g. `~/.gradle/gradle.properties`:

```
gpr.user=
gpr.key=
```  

### iOS
Cordova fetches iOS dependencies via [CocoaPods](https://cocoapods.org/). Your project environment should have access to the [native iOS SDK](https://github.com/fibricheck/ios-camera-sdk). 

## Install - Include the plugin in your cordova project 

**Important!** iOS requires the following usage description to be added and filled for your app in `Info.plist`:
* `NSCameraUsageDescription (Privacy - Camera Usage Description)`

<!-- x-release-please-start-version -->
### Using Ionic Capacitor
```
npm i --save github:fibricheck/cordova-camera-sdk#v0.2.0
```

### Using Cordova
```
cordova plugin add https://github.com/fibricheck/cordova-camera-sdk#v0.2.0
```
<!-- x-release-please-end -->

## How to use 
Once installed The plugin is available in the cordova environment under `cordova.plugins.FibriCheckCordovaSDK`.


```javascript
const { FibriCheckCordovaSDK: fc } = cordova.plugins;


async function startMeasurement {
    await fc.initialise();

    // Optional: update configuration parameters. Should not be needed.
    await fc.updateConfiguration({
      flashEnabled: true,
      sampleTime: 60
    })

    fc.onMeasurementStart(() => {
      console.log("Measurement Started");

    });

    fc.onSampleReady((ppg, raw) => {
        // Function is called on every ppg sample
        // Can be used to draw a graph
    })

    fc.onHeartBeat((hr) => {
      
    })

    fc.onTimeRemaining((sec: number) => {
        // Return Time remaining for measurement
    })

    fc.onMeasurementProcessed(async (measurementData) => {
        // Measurement data
        await fc.stopMeasurement();
    })

    await fc.startMeasurement();
  }
```

## Examples

The `examples` folder contains an example Ionic project


## Contributing 
This repository uses [release please](https://github.com/googleapis/release-please) to manage releases and changelog documentation automatically. It parses the commit messages to determine the version bump (patch, minor, major). 

Please use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messaging.