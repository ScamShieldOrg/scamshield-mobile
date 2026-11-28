import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var pickerResult: FlutterResult?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ReportEvidencePicker") else {
      return
    }
    FlutterMethodChannel(
      name: "scamshield/guest_session",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      let key = "scamshield.guestSession"
      switch call.method {
      case "read":
        result(UserDefaults.standard.string(forKey: key))
      case "write":
        UserDefaults.standard.set(call.arguments as? String, forKey: key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    FlutterMethodChannel(
      name: "scamshield/privacy_reference",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      guard call.method == "open",
        let url = URL(string: "https://csrc.nist.gov/pubs/sp/800/122/final") else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.open(url) { opened in result(opened) }
    }
    FlutterMethodChannel(
      name: "scamshield/evidence_ocr",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      guard call.method == "scan" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let bytes = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(code: "ocr", message: "Missing image", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        do {
          let tokens = try NSRegularExpression(pattern: #"\S+"#)
          try VNImageRequestHandler(data: bytes.data, options: [:]).perform([request])
          let lines = (request.results as? [VNRecognizedTextObservation] ?? []).compactMap { observation -> [[Any]]? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let text = candidate.string
            return tokens.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)).compactMap { token -> [Any]? in
              guard let range = Range(token.range, in: text),
                    let box = try? candidate.boundingBox(for: range)?.boundingBox else { return nil }
              return [String(text[range]), Double(box.minX), Double(1 - box.maxY),
                      Double(box.maxX), Double(1 - box.minY)]
            }
          }
          DispatchQueue.main.async { result(lines) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "ocr", message: "Text recognition failed", details: nil))
          }
        }
      }
    }
    let channel = FlutterMethodChannel(
      name: "scamshield/report_evidence",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pick" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self, self.pickerResult == nil,
        let root = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .flatMap({ $0.windows })
          .first(where: { $0.isKeyWindow })?.rootViewController else {
        result(FlutterError(code: "picker", message: "Không mở được trình chọn tệp.", details: nil))
        return
      }
      let picker = UIDocumentPickerViewController(
        documentTypes: ["public.png", "public.jpeg", "com.adobe.pdf"],
        in: .import
      )
      self.pickerResult = result
      picker.delegate = self
      root.present(picker, animated: true)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pickerResult
    pickerResult = nil
    result?(nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let result = pickerResult
    pickerResult = nil
    guard let url = urls.first else {
      result?(nil)
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let maxBytes = 5 * 1024 * 1024
        let bytes: Data
        if #available(iOS 13.4, *) {
          bytes = try file.read(upToCount: maxBytes + 1) ?? Data()
        } else {
          bytes = file.readData(ofLength: maxBytes + 1)
        }
        guard bytes.count <= maxBytes else {
          DispatchQueue.main.async {
            result?(FlutterError(code: "file", message: "Tệp vượt quá 5 MB.", details: nil))
          }
          return
        }
        DispatchQueue.main.async {
          result?(["name": url.lastPathComponent, "bytes": FlutterStandardTypedData(bytes: bytes)])
        }
      } catch {
        DispatchQueue.main.async {
          result?(FlutterError(code: "file", message: "Không đọc được tệp minh chứng.", details: nil))
        }
      }
    }
  }
}
