import Flutter
import UIKit

/// Taptic Engine helpers for BARAV QUIZ (iPhone).
enum BaravHaptics {
  private static let light = UIImpactFeedbackGenerator(style: .light)
  private static let medium = UIImpactFeedbackGenerator(style: .medium)
  private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
  private static let notify = UINotificationFeedbackGenerator()

  static func prepare() {
    light.prepare()
    medium.prepare()
    heavy.prepare()
    notify.prepare()
  }

  static func quizStart() {
    prepare()
    notify.notificationOccurred(.success)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
      heavy.impactOccurred(intensity: 1.0)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
      medium.impactOccurred(intensity: 0.9)
      prepare()
    }
  }

  static func nextQuestion() {
    prepare()
    medium.impactOccurred(intensity: 1.0)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
      light.impactOccurred(intensity: 0.8)
      prepare()
    }
  }
}

/// Screenshot / screen-recording protection for live quiz.
final class BaravScreenSecurity {
  static let shared = BaravScreenSecurity()

  private var secureField: UITextField?
  private var blurOverlay: UIView?
  private var captureObserver: NSObjectProtocol?
  private var eventSink: FlutterEventSink?

  private init() {}

  func setEventSink(_ sink: FlutterEventSink?) {
    eventSink = sink
    sink?(UIScreen.main.isCaptured)
  }

  func enable() {
    DispatchQueue.main.async {
      self.attachSecureLayer()
      self.attachCaptureObserver()
      self.updateAppSwitcherProtection(isCaptured: UIScreen.main.isCaptured)
      self.eventSink?(UIScreen.main.isCaptured)
    }
  }

  func disable() {
    DispatchQueue.main.async {
      self.detachSecureLayer()
      self.detachCaptureObserver()
      self.blurOverlay?.removeFromSuperview()
      self.blurOverlay = nil
    }
  }

  func isRecording() -> Bool {
    UIScreen.main.isCaptured
  }

  private func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func attachSecureLayer() {
    guard secureField == nil, let window = keyWindow() else { return }

    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    field.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(field)
    // Make the secure layer cover the window hierarchy so screenshots go black.
    window.layer.superlayer?.addSublayer(field.layer)
    if let secureLayer = field.layer.sublayers?.last {
      secureLayer.addSublayer(window.layer)
    }
    secureField = field
  }

  private func detachSecureLayer() {
    secureField?.removeFromSuperview()
    secureField = nil
  }

  private func attachCaptureObserver() {
    guard captureObserver == nil else { return }
    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      let captured = UIScreen.main.isCaptured
      self.updateAppSwitcherProtection(isCaptured: captured)
      self.eventSink?(captured)
    }
  }

  private func detachCaptureObserver() {
    if let captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
    }
    captureObserver = nil
  }

  private func updateAppSwitcherProtection(isCaptured: Bool) {
    guard let window = keyWindow() else { return }
    if isCaptured {
      if blurOverlay == nil {
        let overlay = UIView(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = UIColor(red: 16 / 255, green: 23 / 255, blue: 42 / 255, alpha: 1)
        overlay.isUserInteractionEnabled = true
        window.addSubview(overlay)
        blurOverlay = overlay
      }
    } else {
      blurOverlay?.removeFromSuperview()
      blurOverlay = nil
    }
  }
}

final class ScreenSecurityStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    BaravScreenSecurity.shared.setEventSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    BaravScreenSecurity.shared.setEventSink(nil)
    return nil
  }
}

/// Root / jailbreak / simulator detection for quiz integrity.
enum BaravDeviceIntegrity {
  static func check() -> [String: Any] {
    let simulator = isSimulator()
    let jailbroken = isJailbroken()
    return [
      "compromised": jailbroken || simulator,
      "rooted": jailbroken,
      "emulator": simulator,
      "realDevice": !simulator,
    ]
  }

  private static func isSimulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
  }

  private static func isJailbroken() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    let paths = [
      "/Applications/Cydia.app",
      "/Applications/Sileo.app",
      "/Applications/Zebra.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt",
      "/private/var/lib/cydia",
      "/var/jb/.installed_palera1n",
      "/var/jb",
      "/usr/lib/libhooker.dylib",
      "/usr/lib/substrate",
    ]
    if paths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
      return true
    }

    if UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
      || UIApplication.shared.canOpenURL(URL(string: "sileo://")!) {
      return true
    }

    let probe = "/private/" + UUID().uuidString
    do {
      try "barav".write(toFile: probe, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: probe)
      return true
    } catch {
      return false
    }
#endif
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let screenSecurityStreamHandler = ScreenSecurityStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    let haptics = FlutterMethodChannel(
      name: "barav_quiz/haptics",
      binaryMessenger: messenger
    )
    haptics.setMethodCallHandler { call, result in
      switch call.method {
      case "prepare":
        BaravHaptics.prepare()
        result(nil)
      case "quizStart":
        BaravHaptics.quizStart()
        result(nil)
      case "nextQuestion":
        BaravHaptics.nextQuestion()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let security = FlutterMethodChannel(
      name: "barav_quiz/screen_security",
      binaryMessenger: messenger
    )
    security.setMethodCallHandler { call, result in
      switch call.method {
      case "enable":
        BaravScreenSecurity.shared.enable()
        result(nil)
      case "disable":
        BaravScreenSecurity.shared.disable()
        result(nil)
      case "isRecording":
        result(BaravScreenSecurity.shared.isRecording())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(
      name: "barav_quiz/screen_security_events",
      binaryMessenger: messenger
    )
    events.setStreamHandler(screenSecurityStreamHandler)

    let integrity = FlutterMethodChannel(
      name: "barav_quiz/device_integrity",
      binaryMessenger: messenger
    )
    integrity.setMethodCallHandler { call, result in
      switch call.method {
      case "check":
        result(BaravDeviceIntegrity.check())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
