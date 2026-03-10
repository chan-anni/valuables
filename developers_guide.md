# Developer Guidelines
**Important:** The following set up instructions and development environment are intended strictly for iOS and Android mobile platforms. Desktop or web configurations are not supported for this specific project.
These guidelines are intended for developers who wish to contribute to the Valuables project. For easier navigation, use the table of contents below:

* [Setting Up](#setting-up)
    * [Directory Layout](#directory-layout)
    * [Environment Setup](#environment-setup)
* [Repo Setup](#repo-setup)
    * [iOS Configuration](#ios)
    * [Android Configuration](#android)
* [Running the App](#running-the-app)
* [Testing](#testing)
    * [Running Tests](#running-tests)
    * [Adding New Tests](#adding-tests)
* [Release Procedures](#release-procedures)
* [CI/CD & Coverage](#continuous-integration-ci)

      
## Setting Up
Install the following before cloning the repository.

Install Flutter from the official docs: https://docs.flutter.dev/get-started/install

This project requires:

|      Tool            | Required Version |
|----------------------|------------------|
|Dart SDK              |           ^3.10.7|
|Flutter               |               ---|
|XCode (ios/macOS)     |             15.0+|
|CocoaPods (ios/macOS) |           1.14.0+|
|Android Studio        |    Latest version|
|Android Emulator      |Android Virtual Device API 33+|

After installing flutter, you can verify your environment is healthy using
```
flutter doctor
```

The project is hosted in a single repository. Clone it and navigate to the application directory
```
git clone https://github.com/chan-anni/valuables.git
cd valuables/valuables-app
```
### Directory Layout
When developing you will mostly work in valuables-app/lib/
```
valuables/
├── .github/workflows/       # Automated CI/CD (Testing & Coverage)
├── Status-Reports/          # Project management & weekly updates
│
├── valuables-app/           # Root of the Flutter project
│   ├── lib/                 # MAIN SOURCE CODE
│   │    ├── screens/        # UI: Maps, Forms, Lists
│   │    ├── models/         # Data logic & Supabase structures
│   │    └── main.dart       # App entry point
│   ├── test/                # TEST SUITE (Mirrors 'lib' structure)
│   │    ├── screens/        # Widget tests for UI components
│   │    └── unit/           # Logic and helper tests
|   ├── ios/                 # iOS specific files -- AppDelegate goes in here
|   ├── android/             # Android specific files -- AndroidManifest goes in here
│   ├── pubspec.yaml         # Dependencies (Supabase, Dotenv, etc.)
│   └── .env                 # Local secrets (not tracked in Git)
│
└── README.md                # Entry point for documentation
```
All contributions should be made onto a new branch which later gets merged into the developing branch. Main holds release code only.
### Environment Setup

This project uses flutter_dotenv to manage secrets. **A .env file is required at the project root.**

Copy the .env.example, remove the ".example" from the name, and add the following keys (create your own):
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAP_KEY=ios_or_android_key
GOOGLE_CLIENT_ID=client_id
GOOGLE_SERVER_CLIENT_ID=server_client_id
```

#### Creating your own API keys:
- [Google Cloud Console - Maps](https://console.cloud.google.com/google/maps-apis/credentials)(If you don't have a project on Google Cloud Console, initialize one first and then use the link to navigate to the panel)
	- *GOOGLE_MAP_KEY*:
		- Create an API key with no App restriction (for the purpose of testing on multiple platform)
		- Include the following 3 APIs in the selection:
			1. Maps SDK for Android (or iOS, depending on your platform)
			2. Places API
			3. Places API (New)
		- Paste the API key generated to *GOOGLE_MAP_KEY* in **.env**
	- *GOOGLE_CLIENT_ID* and *GOOGLE_SERVER_CLIENT_ID*:
		- Create a OAuth 2.0 Client ID based on your platform
		- Follow the steps to filling the information
		- Paste the *GOOGLE_CLIENT_ID* and *GOOGLE_SERVER_CLIENT_ID* into **.env**
- [Supabase](https://supabase.com/dashboard/) (If you don't have a project on Supabase, initialize one first and then use the link to navigate to the panel)
	- *SUPABASE_URL*:
		- Get the *SUPABASE_URL* in the project panel and paste into **.env**
	- *SUPABASE_ANON_KEY*:
		- Get the *SUPABASE_ANON_KEY* in Project Settings -> API Keys -> Publishable key and paste into **.env**
#### Android
Add inside <application> in android/app/src/main/AndroidManifest.xml (you may have to make this file). Make sure the file has "${GOOGLE_MAP_KEY}" field. The build.gradle.kts will replace it automatically with the .env file's value.

```xml

<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="valuables"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <meta-data 
            android:name="com.google.android.geo.API_KEY"
            android:value="${GOOGLE_MAP_KEY}"
            />
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

### iOS
Add ios/Runner/AppDelegate.swift (you may have to make this file). Replace the API key where it says "Google Maps API Key here":
```swift

import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain 
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("Google Maps API Key here")
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```
DO NOT commit this file. It should already be in the .gitignore. 

## Building the Project

Run the following command fetch all packages needed from the pubspec.yaml.
```
flutter pub get
```
For iOS native setup (macOS only) you will also need to use 'pod' for running. Use the following commands
```
cd ios
pod install
```
### Running the App
Copy the following command into the terminal. Make sure you are in the valuables-app folder.
```
flutter run
```
Every time packages change, you should run the following to keep updated:
```
flutter clean
flutter pub get
```
There are two options to where you can run the app:

### Using an Emulator

**Android emulator**

Ensure you already have the Android SDK, with Android Studio and Android Emulator installed. For detailed instructions on how to set up, follow the [Flutter docs for Android development](https://docs.flutter.dev/platform-integration/android/setup). Make sure to choose your relevant development platform. When your setup is finished, you can run the following command:
```
flutter emulators && flutter devices
```
This validates the devices/emulators you can run the app on. You should have at least 1 output that is a platform marked as Android. Then, when running the Flutter project (using 'flutter run'), you should be able to choose the emulator and launch the program.

**iOS emulator**

Ensure you already have XCode installed on your computer and set up. For detailed instructions, we recommend you follow the [Flutter docs for iOS development](https://docs.flutter.dev/platform-integration/ios/setup). Then run the following command: 
```
open -a Simulator
```
This starts the simulator. From there, you should be able to pick which type of device you want to use. Then, when running the Flutter project (using 'flutter run'), you should be able to choose the emulator.

### Using Your Physical Device

To run the app on a physical device, you need a data transfer cable (USB) that connects to your phone and computer.

**Android:**
1. On your Android device, [enable developer options](https://stackoverflow.com/questions/54444538/how-do-i-run-test-my-flutter-app-on-a-real-device). This may vary slightly across Android versions, but should involve pressing the **Build Number** option seven times.
2. A "Developer Options" option should come up, allowing you to "enable USB Debugging.
3. Plug in your device to the computer using the USB cable. You may see a pop-up that tells you the device is connected.
4. Run the following command to check your devices for Flutter to run on:
```
   flutter devices
```
Then, when you run your app, it should allow you to select your specific Android app to run on. 

Another way you can configure your app is by installing Flutter, the Flutter extension for VS Code and Android SDK. 
**iOS**

Similarly to when running the iOS simulator, you want to have Xcode installed and set up. For detailed instructions, we recommend you follow the [Flutter docs for iOS development](https://docs.flutter.dev/platform-integration/ios/setup). You will need an Apple ID or sign up with a developer account. Once you have configured Xcode's iOS tooling, do the following.

In Xcode: 
1. Open ios/Runner .xcworkspace
2. Select the Runner project in the left sidebar and go to the Signing & Capabilities tab, and select a "Team" (select your Apple ID)

Then on your phone:
1. Connect your iOS device to the computer using a USB cable. This should cause a pop-up to appear asking to trust the computer. Click **Trust**.
2. Apple requires developer mode to run the app. Navigate to Settings > Privacy & Security > Developer Mode. 
3. Tap to toggle Developer Mode to On.
4. Restart the device
5. When the prompt to turn on developer mode appears, tap Turn On.


## Testing 
### Running Tests
All tests live in test/, mirroring the structure of lib/. Test files must end in _test.dart.

Run all tests
```
flutter test
```
Run a specific test file
```
flutter test test/auth_test/auth_service_test.dart
```
Run tests with code coverage
```
flutter test --coverage
```
This creates/overwrites coverage/lcov.info. 

### Adding Tests
All test files must end in _test.dart (e.g main_test.dart) for the runner to recognize them. 
The test folder should mirror the lib/ directory. 
In test files themselves, use test() for logic and testWidgets() for UI components. 
Tests requiring Supabase interaction may require a valid .env file or will use mocked responses defined in the test/ directory.

- For unit or widget testing, Flutter has integrated functions in *flutter_test* package that allows for checking UI elements, navigation, and testing functions.

- For integration testing or functions that depends on external APIs, use *Mocktail* to create mock responses to ensure the business logic is correct. 

- Finally, run 'flutter test --coverage' to generate a code coverage report. Use it with [Flutter Coverage](https://marketplace.visualstudio.com/items?itemName=Flutterando.flutter-coverage) to see the result of the test.

## Release Procedures
Update Versioning: Increment the version and build number in pubspec.yaml (e.g., version: 1.0.1+2) and tag the release as well in git. Update the README with the latest release and link to the release note if any.

Documentation: Ensure any new features are updated in the user-facing documentation. Include a list of bugs fixed or issues addressed and link them correctly.

Formatting: Run the following to ensure the code is formatted properly and readable:
```flutter format <you file path here>```

## Continuous Integration (CI)
We use GitHub Actions to automate the validation of every pull request and push to the main and developing branches.

**Automated Checks**

Whenever you submit a Pull Request, the following checks are triggered automatically:

Static Analysis: The pipeline runs Flutter analyze to catch potential bugs, style issues, and type mismatches.

Unit & Widget Tests: All tests in the test/ directory are executed using flutter test.

Test Coverage: A coverage report is generated to ensure that new code is adequately tested.
