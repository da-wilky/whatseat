import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  // Set from Dart while the app lock is on. iOS takes the app-switcher snapshot before Flutter can draw its own cover.
  private var privacyCoverEnabled = false
  private var privacyCover: UIView?
  private var pendingPick: FlutterResult?

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
    FlutterMethodChannel(name: "whatseat/clipboard", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "copySensitive", let text = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        // Kept off Universal Clipboard and cleared after two minutes, like on Android.
        UIPasteboard.general.setItems(
          [[UTType.utf8PlainText.identifier: text]],
          options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(2 * 60)])
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
    FlutterMethodChannel(name: "whatseat/folder", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { [weak self] call, result in
        if call.method == "pick" {
          self?.pickFolder(result)
          return
        }
        // Bookmarks hold no system-wide grant; dropping the stored bookmark is all it takes.
        if call.method == "release" {
          result(nil)
          return
        }
        guard let args = call.arguments as? [String: Any],
          let bookmark = (args["uri"] as? String).flatMap({ Data(base64Encoded: $0) })
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        let name = args["name"] as? String
        let bytes = (args["bytes"] as? FlutterStandardTypedData)?.data
        // Provider extensions may go to the network, so the work stays off the main thread.
        DispatchQueue.global(qos: .utility).async {
          let reply: Any?
          do {
            reply = try AppDelegate.folderOperation(call.method, bookmark: bookmark, name: name, bytes: bytes)
          } catch {
            reply = FlutterError(code: "folder", message: error.localizedDescription, details: nil)
          }
          DispatchQueue.main.async { result(reply) }
        }
      }
  }

  private var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })
  }

  private func pickFolder(_ result: @escaping FlutterResult) {
    guard pendingPick == nil, let root = keyWindow?.rootViewController else {
      result(FlutterError(code: "folder", message: "Folder picker unavailable", details: nil))
      return
    }
    pendingPick = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    (root.presentedViewController ?? root).present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pendingPick else { return }
    pendingPick = nil
    guard let url = urls.first else {
      result(nil)
      return
    }
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
    do {
      // The bookmark keeps access across launches; the URL alone is only valid until the app quits.
      let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      result(["uri": bookmark.base64EncodedString(), "name": url.lastPathComponent])
    } catch {
      result(FlutterError(code: "folder", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPick?(nil)
    pendingPick = nil
  }

  private static func folderOperation(_ method: String, bookmark: Data, name: String?, bytes: Data?) throws -> Any? {
    var stale = false
    let folder = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale)
    guard folder.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
    defer { folder.stopAccessingSecurityScopedResource() }
    let coordinator = NSFileCoordinator()
    var coordinationError: NSError?
    var operationError: Error?
    var reply: Any?
    switch method {
    case "list":
      coordinator.coordinate(readingItemAt: folder, options: [], error: &coordinationError) { url in
        do {
          // Files not downloaded from iCloud show up as ".<name>.icloud" placeholders.
          reply = try FileManager.default.contentsOfDirectory(atPath: url.path).map { entry in
            entry.hasPrefix(".") && entry.hasSuffix(".icloud") ? String(entry.dropFirst().dropLast(7)) : entry
          }
        } catch {
          operationError = error
        }
      }
    case "read":
      coordinator.coordinate(
        readingItemAt: folder.appendingPathComponent(name!), options: [], error: &coordinationError
      ) { url in
        do {
          // The folder may belong to a cloud app; a far larger file than any backup would only exhaust memory.
          if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 64 * 1024 * 1024 {
            throw CocoaError(.fileReadTooLarge)
          }
          reply = FlutterStandardTypedData(bytes: try Data(contentsOf: url))
        } catch {
          operationError = error
        }
      }
    case "write":
      coordinator.coordinate(
        writingItemAt: folder.appendingPathComponent(name!), options: .forReplacing, error: &coordinationError
      ) { url in
        do {
          try bytes!.write(to: url, options: .atomic)
        } catch {
          operationError = error
        }
      }
    case "delete":
      coordinator.coordinate(
        writingItemAt: folder.appendingPathComponent(name!), options: .forDeleting, error: &coordinationError
      ) { url in
        do {
          if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        } catch {
          operationError = error
        }
      }
    default:
      return FlutterMethodNotImplemented
    }
    if let error = coordinationError ?? operationError { throw error }
    return reply
  }

  @objc private func showPrivacyCover() {
    guard privacyCoverEnabled, privacyCover == nil, let window = keyWindow else { return }
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
