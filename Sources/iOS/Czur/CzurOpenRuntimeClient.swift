import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Errors thrown by the local CZUR Open SDK Runtime client.
enum CzurOpenError: Error {
    case runtimeNotRunning
    case notAuthorized
    case deviceNotFound
    case scanFailed(String)
    case conversionFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .runtimeNotRunning:
            return "The local CZUR scanner runtime is not running. Install and start it from the CZUR Open Platform, then retry."
        case .notAuthorized:
            return "The CZUR scanner runtime is not authorized. Complete authorization in the CZUR Open Platform, then retry."
        case .deviceNotFound:
            return "No CZUR scanner was found by the local runtime."
        case .scanFailed(let message):
            return "The CZUR scan failed: \(message)"
        case .conversionFailed(let message):
            return "The CZUR file conversion failed: \(message)"
        case .cancelled:
            return "The CZUR scan was cancelled."
        }
    }
}

/// A scanner device exposed by the local CZUR Open SDK Runtime.
struct CzurOpenDevice: Sendable, Codable {
    let deviceId: String
    let name: String?

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case name = "device_name"
    }
}

/// Snapshot of a capture task, as returned by `capture.get`.
struct CzurOpenCaptureTask: Sendable {
    let taskId: String
    let status: String
    let assets: [String]
}

/// OCR text extracted from a scanned image via the local runtime.
struct CzurOpenOcrText: Sendable {
    let recognized: Bool
    let text: String
}

/// A barcode / QR code detected from a static image via the local runtime.
struct CzurOpenBarcode: Sendable {
    let detected: Bool
    let barcodes: [CzurOpenBarcodeInfo]
}

struct CzurOpenBarcodeInfo: Sendable, Codable {
    let type: String?
    let value: String?
}

/// Response envelope returned by CZUR Open Runtime command methods.
struct CzurOpenCommandResponse: Sendable {
    let requestId: String?
    let status: String?
    let taskId: String?
    let error: String?
    let data: [String: String]?
    let assets: [String]?
}

/// Local runtime connection details. Defaults point at the loopback ports used
/// by a runtime running on the same Mac; iOS devices should override the host
/// with the Mac's LAN address before use.
final class CzurOpenRuntimeClient: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {

    static let shared = CzurOpenRuntimeClient()
    private override init() { super.init() }

    // MARK: - State

    private let stateLock = NSLock()
    private var webSocketTask: URLSessionWebSocketTask?
    private var pendingResponses: [String: CheckedContinuation<CzurOpenCommandResponse, Error>] = [:]
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private var sessionTokenValue: String?
    private var connectionSession: URLSession?
    private var isRunningValue = false
    /// Raw image bytes of the latest video frame. Kept as `Data` (not a
    /// platform image type) so the frame stream works on both UIKit and
    /// AppKit; views decode for their platform.
    private var videoFrameHandler: (@Sendable (Data?) -> Void)?

    nonisolated(unsafe) static var commandWebSocketBaseURL: URL = URL(string: "ws://127.0.0.1:17090") ?? URL(fileURLWithPath: "/")
    nonisolated(unsafe) static var assetBaseURL: URL = URL(string: "http://127.0.0.1:17082") ?? URL(fileURLWithPath: "/")

    /// Configures the local CZUR Open SDK Runtime endpoints.
    ///
    /// iOS/iPadOS cannot host the runtime themselves, so iPhone/iPad "alone"
    /// operation points this client at a runtime host running elsewhere (e.g. a
    /// Linux runtime host on the local network) over Command WS + Local HTTP.
    /// Defaults remain loopback for a runtime on the same device.
    static func configure(commandWebSocketURL: URL, assetBaseURL: URL) {
        CzurOpenRuntimeClient.commandWebSocketBaseURL = commandWebSocketURL
        CzurOpenRuntimeClient.assetBaseURL = assetBaseURL
    }

    // MARK: - State helpers (synchronous; must not be called from async context)

    private func currentIsRunning() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return isRunningValue
    }

    private func setRunning(_ value: Bool) {
        stateLock.lock()
        isRunningValue = value
        stateLock.unlock()
    }

    private func currentTask() -> URLSessionWebSocketTask? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return webSocketTask
    }

    private func setTask(_ task: URLSessionWebSocketTask?) {
        stateLock.lock()
        webSocketTask = task
        stateLock.unlock()
    }

    private func storeConnectionContinuation(_ continuation: CheckedContinuation<Void, Error>) {
        stateLock.lock()
        connectionContinuation = continuation
        stateLock.unlock()
    }

    private func takeConnectionContinuation() -> CheckedContinuation<Void, Error>? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return connectionContinuation
    }

    private func storePendingResponse(_ key: String, _ continuation: CheckedContinuation<CzurOpenCommandResponse, Error>) {
        stateLock.lock()
        pendingResponses[key] = continuation
        stateLock.unlock()
    }

    private func removePendingResponse(forKey key: String) -> CheckedContinuation<CzurOpenCommandResponse, Error>? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return pendingResponses.removeValue(forKey: key)
    }

    private func drainPendingResponses() -> [CheckedContinuation<CzurOpenCommandResponse, Error>] {
        stateLock.lock()
        defer { stateLock.unlock() }
        let values = Array(pendingResponses.values)
        let keys = Array(pendingResponses.keys)
        for key in keys {
            pendingResponses.removeValue(forKey: key)
        }
        return values
    }

    // MARK: - Video frame handling

    private func currentVideoFrameHandler() -> (@Sendable (Data?) -> Void)? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return videoFrameHandler
    }

    private func setVideoFrameHandler(_ handler: @escaping @Sendable (Data?) -> Void) {
        stateLock.lock()
        videoFrameHandler = handler
        stateLock.unlock()
    }

    private func takeVideoFrameHandler() -> (@Sendable (Data?) -> Void)? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return videoFrameHandler
    }

    // MARK: - Lifecycle

    func start() async throws -> Bool {
        await stop()
        let url = CzurOpenRuntimeClient.commandWebSocketBaseURL
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        connectionSession = session
        let task = session.webSocketTask(with: url)
        setTask(task)
        task.resume()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storeConnectionContinuation(continuation)
        }
        return true
    }

    func stop() async {
        setRunning(false)
        setTask(nil)
        let continuations = drainPendingResponses()
        let connection = takeConnectionContinuation()
        connection?.resume(returning: ())
        continuations.forEach { continuation in
            continuation.resume(returning: CzurOpenCommandResponse(requestId: UUID().uuidString, status: nil, taskId: nil, error: "cancelled", data: nil, assets: nil))
        }
    }

    func isRunning() -> Bool {
        currentIsRunning()
    }

    // MARK: - Reachability / session

    func checkRuntimeReachable() async -> Bool {
        if !currentIsRunning() { return false }
        do {
            let response = try await send("system.ping", params: [:])
            return response.error == nil
        } catch {
            return false
        }
    }

    @discardableResult
    func createSession() async throws -> String {
        let response = try await send("auth.create_session", params: [:])
        guard response.error == nil, let token = response.data?["session_token"] else {
            throw CzurOpenError.notAuthorized
        }
        sessionTokenValue = token
        return token
    }

    // MARK: - Devices

    func listDevices() async throws -> [CzurOpenDevice] {
        let response = try await send("device.list", params: [:])
        guard response.error == nil else { return [] }
        if let raw = response.data?["devices"],
           let jsonData = raw.data(using: .utf8),
           let devices = try? JSONDecoder().decode([CzurOpenDevice].self, from: jsonData) {
            return devices
        }
        return []
    }

    @discardableResult
    func openDevice(deviceId: String) async throws -> Bool {
        let response = try await send("device.open", params: ["device_id": deviceId])
        guard response.error == nil else { throw CzurOpenError.deviceNotFound }
        return true
    }

    func closeDevice(deviceId: String) async {
        _ = try? await send("device.close", params: ["device_id": deviceId])
    }

    // MARK: - Capture

    @discardableResult
    func takeCapture(deviceId: String, outputDir: String?, pipeline: [String: String]? = nil) async throws -> String {
        var params: [String: String] = [
            "device_id": deviceId,
        ]
        if let outputDir {
            params["capture.output_dir"] = outputDir
        }
        if let pipeline {
            for (key, value) in pipeline.sorted(by: { $0.key < $1.key }) {
                params["capture.\(key)"] = value
            }
        }
        let response = try await send("capture.take", params: params)
        guard response.error == nil, let taskId = response.taskId else {
            throw CzurOpenError.scanFailed(response.error ?? "capture.take did not return a task id")
        }
        return taskId
    }

    func getCapture(taskId: String) async throws -> CzurOpenCaptureTask {
        let response = try await send("capture.get", params: ["task_id": taskId])
        return CzurOpenCaptureTask(taskId: taskId, status: response.status ?? "unknown", assets: response.assets ?? [])
    }

    /// Enables / disables page-turn detection and (when `autoCapture` is true)
    /// lets the runtime trigger captures by itself.
    @discardableResult
    func setTurnDetect(deviceId: String, enabled: Bool, autoCapture: Bool, cooldownMs: Int) async throws -> Bool {
        let response = try await send(
            "capture.set_turn_detect",
            params: [
                "device_id": deviceId,
                "enabled": enabled ? "true" : "false",
                "auto_capture": autoCapture ? "true" : "false",
                "cooldown_ms": String(cooldownMs),
            ]
        )
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "capture.set_turn_detect failed")
        }
        return true
    }

    // MARK: - OCR

    func ocrExtractText(inputUploadId: String, language: String? = nil) async throws -> CzurOpenOcrText {
        var params: [String: String] = ["input_upload_id": inputUploadId]
        if let language { params["language"] = language }
        let response = try await send("ocr.extract_text", params: params)
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "ocr.extract_text failed")
        }
        let data = response.data ?? [:]
        let recognized = data["recognized"] == "true"
        let text = data["text"] ?? ""
        return CzurOpenOcrText(recognized: recognized, text: text)
    }

    /// Detects barcode / QR content from a static image via the local runtime.
    func detectBarcodes(inputUploadId: String, formats: [String]) async throws -> CzurOpenBarcode {
        var params: [String: String] = ["input_upload_id": inputUploadId]
        params["formats"] = formats.joined(separator: ",")
        let response = try await send("recognition.barcode_detect", params: params)
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "recognition.barcode_detect failed")
        }
        let data = response.data ?? [:]
        let detected = data["detected"] == "true"
        var barcodes: [CzurOpenBarcodeInfo] = []
        if let raw = data["barcodes"],
           let jsonData = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([CzurOpenBarcodeInfo].self, from: jsonData) {
            barcodes = decoded
        }
        return CzurOpenBarcode(detected: detected, barcodes: barcodes)
    }

    // MARK: - File conversion

    /// Converts / exports a file through the runtime `file.convert` capability.
    /// Supported hops include images → PDF (multi-page), PDF → images, and
    /// image → jpg/png/tiff. Cross-document conversions do not preserve
    /// text/vector semantics, so OCR should run on the source images.
    ///
    /// - Parameters:
    ///   - inputUploadId: Upload / asset id feeding the conversion (e.g. a capture asset).
    ///   - exportType: Output type such as `"pdf"`, `"jpg"`, `"png"`, `"tiff"`, or `"image"`.
    ///   - renderDpi: Optional render resolution; `nil` leaves the runtime default (144).
    /// - Returns: The conversion task id; poll with `getFileConversion(taskId:)`.
    func convertFile(inputUploadId: String, exportType: String, renderDpi: Int? = nil) async throws -> String {
        var params: [String: String] = [
            "input_upload_id": inputUploadId,
            "export_type": exportType,
        ]
        if let renderDpi { params["render_dpi"] = String(renderDpi) }
        let response = try await send("file.convert", params: params)
        guard response.error == nil, let taskId = response.taskId else {
            throw CzurOpenError.conversionFailed(response.error ?? "file.convert did not return a task id")
        }
        return taskId
    }

    /// Polls a file-conversion task snapshot via the runtime task model.
    func getFileConversion(taskId: String) async throws -> CzurOpenCaptureTask {
        let response = try await send("file.get", params: ["task_id": taskId])
        return CzurOpenCaptureTask(taskId: taskId, status: response.status ?? "unknown", assets: response.assets ?? [])
    }

    /// Converts the artifacts of a capture task via `file.convert` (images →
    /// PDF multi-page, PDF → images, image → jpg/png/tiff).
    func convertCapture(taskId: String, exportType: String, renderDpi: Int? = nil) async throws -> String {
        var params: [String: String] = [
            "task_id": taskId,
            "export_type": exportType,
        ]
        if let renderDpi { params["render_dpi"] = String(renderDpi) }
        let response = try await send("file.convert", params: params)
        guard response.error == nil, let taskId = response.taskId else {
            throw CzurOpenError.conversionFailed(response.error ?? "file.convert did not return a task id")
        }
        return taskId
    }

    // MARK: - Video preview

    /// Starts a video preview stream for the given device via `video.start`.
    @discardableResult
    func startVideo(deviceId: String, format: String? = nil, profile: String? = nil) async throws -> Bool {
        var params: [String: String] = ["device_id": deviceId]
        if let format { params["format"] = format }
        if let profile { params["profile"] = profile }
        let response = try await send("video.start", params: params)
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "video.start failed")
        }
        return true
    }

    /// Stops the active video preview stream via `video.stop`.
    @discardableResult
    func stopVideo(deviceId: String) async throws -> Bool {
        let response = try await send("video.stop", params: ["device_id": deviceId])
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "video.stop failed")
        }
        return true
    }

    /// Sets the preview stream format via `video.set_format`.
    func setVideoFormat(deviceId: String, format: String) async throws -> Bool {
        let response = try await send("video.set_format", params: ["device_id": deviceId, "format": format])
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "video.set_format failed")
        }
        return true
    }

    /// Sets the realtime preview profile via `video.set_profile`.
    func setVideoProfile(deviceId: String, profile: String) async throws -> Bool {
        let response = try await send("video.set_profile", params: ["device_id": deviceId, "profile": profile])
        guard response.error == nil else {
            throw CzurOpenError.scanFailed(response.error ?? "video.set_profile failed")
        }
        return true
    }

    /// Registers the handler invoked with each decoded video frame (raw
    /// image bytes) while a preview stream is active.
    func registerVideoFrameHandler(_ handler: @escaping @Sendable (Data?) -> Void) {
        setVideoFrameHandler(handler)
    }

    /// Clears the registered video frame handler.
    func clearVideoFrameHandler() {
        _ = takeVideoFrameHandler()
    }

    // MARK: - Asset download

    func downloadAsset(taskId: String, assetId: String) async throws -> Data {
        guard let token = sessionTokenValue else { throw CzurOpenError.notAuthorized }
        let path = "/api/assets/\(taskId)/\(assetId)/download"
        let full = CzurOpenRuntimeClient.assetBaseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: full)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CzurOpenError.runtimeNotRunning
        }
        return data
    }

    // MARK: - Command sending / receiving

    func send(_ method: String, params: [String: String]) async throws -> CzurOpenCommandResponse {
        let task = currentTask()
        guard task != nil else { throw CzurOpenError.runtimeNotRunning }

        let requestId = UUID().uuidString
        let body = makeJsonBody(method: method, params: params, requestId: requestId)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CzurOpenCommandResponse, Error>) in
            storePendingResponse(requestId, continuation)
            task?.send(.string(body)) { error in
                if let error {
                    if let pending = self.removePendingResponse(forKey: requestId) {
                        pending.resume(returning: CzurOpenCommandResponse(
                            requestId: requestId,
                            status: nil,
                            taskId: nil,
                            error: error.localizedDescription,
                            data: nil,
                            assets: nil
                        ))
                    }
                }
            }
        }
    }

    private func makeJsonBody(method: String, params: [String: String], requestId: String) -> String {
        let payload: [String: Any] = [
            "request_id": requestId,
            "method": method,
            "params": params,
            "client": [
                "source": "NurseVault",
                "protocol_version": "2.0.0",
                "trace_id": requestId,
            ],
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else { return "{}" }
        guard let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private func stringArray(from value: Any?) -> [String]? {
        guard let array = value as? [Any] else { return nil }
        var result: [String] = []
        for item in array {
            if let dict = item as? [String: String], let id = dict["asset_id"] {
                result.append(id)
            } else if let str = item as? String {
                result.append(str)
            }
        }
        return result
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            guard let text = String(data: data, encoding: .utf8) else { return }
            handleTextMessage(text)
        case .string(let text):
            handleTextMessage(text)
        default:
            break
        }
    }

    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let eventName = json["event"] as? String {
            handleVideoEvent(eventName: eventName, json: json)
            return
        }

        guard let requestId = json["request_id"] as? String else { return }

        let continuation = removePendingResponse(forKey: requestId)
        guard let pending = continuation else { return }
        let response = CzurOpenCommandResponse(
            requestId: requestId,
            status: json["status"] as? String,
            taskId: (json["data"] as? [String: String])?["task_id"] as? String,
            error: json["error"] as? String,
            data: (json["data"] as? [String: String]),
            assets: self.stringArray(from: json["assets"])
        )
        pending.resume(returning: response)
    }

    // MARK: - Video events

    private func handleVideoEvent(eventName: String, json: [String: Any]) {
        if eventName == "video.frame" {
            deliverVideoFrame(json: json)
        }
        // Frame streaming is client-driven via `video.start` / `video.stop`;
        // terminal video events simply clear the frame handler downstream.
    }

    private func deliverVideoFrame(json: [String: Any]) {
        var data: Data? = nil
        for key in ["data", "frame", "jpeg", "image", "asset"] {
            if let value = json[key] as? String, let decoded = Self.base64Decode(value) {
                data = decoded
                break
            }
        }
        guard let data else { return }
        let handler = takeVideoFrameHandler()
        Task { @MainActor in
            handler?(data)
        }
    }

    private static func base64Decode(_ value: String) -> Data? {
        guard let data = Data(base64Encoded: value), !data.isEmpty else { return nil }
        return data
    }
}
