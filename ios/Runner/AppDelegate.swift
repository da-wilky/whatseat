import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Set from Dart while the app lock is on. iOS takes the app-switcher snapshot before Flutter can draw its own cover.
  private var privacyCoverEnabled = false
  private var privacyCover: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(showPrivacyCover), name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(hidePrivacyCover), name: UIApplication.didBecomeActiveNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WhatsEatWindow") else { return }
    FlutterMethodChannel(name: "whatseat/window", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { [weak self] call, result in
        guard call.method == "setSecure", let secure = call.arguments as? Bool else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.privacyCoverEnabled = secure
        result(nil)
      }
    FlutterMethodChannel(name: "whatseat/storage", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "excludeFromBackup", let paths = call.arguments as? [String] else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          for path in paths {
            var url = URL(fileURLWithPath: path)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
          }
          result(nil)
        } catch {
          result(FlutterError(code: "exclude", message: error.localizedDescription, details: nil))
        }
      }
  }

  @objc private func showPrivacyCover() {
    guard privacyCoverEnabled, privacyCover == nil,
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow })
    else { return }
    let cover = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    cover.frame = window.bounds
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    privacyCover = cover
  }

  @objc private func hidePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
