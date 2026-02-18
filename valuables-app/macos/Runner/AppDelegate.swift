// import Cocoa
import UIKit
import FlutterMacOS
import GoogleMaps

// @main
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  // override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
  //   return true
  // }

  // override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
  //   return true
  // }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: a[UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBrMGg702bW2vDiLOTNQa9M2mdXlWGrfHQ")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
