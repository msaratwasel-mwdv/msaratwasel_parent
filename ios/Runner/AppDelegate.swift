import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins (required for method channel-based plugins like path_provider).
    GeneratedPluginRegistrant.register(with: self)

    if
      let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !apiKey.isEmpty
    {
      GMSServices.provideAPIKey(apiKey)
    } else {
      NSLog("Google Maps API key is missing. Add GMSApiKey to Info.plist.")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
