//
//  Task3Client.swift
//  Task3
//
//  Created by f3223375 on 3/11/2026.
//

import Foundation
import Observation

struct Reading: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

@MainActor @Observable
final class Task3Client {

    // MARK: Settings — CHANGE THESE
    let negotiateURL = URL(string: "http://172.20.10.4:7071/api/negotiate")!
    let threshold = 50.0
    let windowSeconds: TimeInterval = 60

    // MARK: State used by the UI
    var readings: [Reading] = []
    var latest: Double = 0
    var hasData = false
    var status = "Idle"

    private var task: URLSessionWebSocketTask?
    private var running = false

    func start() async {
        guard !running else { return }
        running = true
        while running {
            await connectOnce()
            guard running else { break }
            status = "Reconnecting…"
            try? await Task.sleep(for: .seconds(3))
        }
    }

    func stop() {
        running = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func connectOnce() async {
        do {
            status = "Negotiating…"
            let (data, _) = try await URLSession.shared.data(from: negotiateURL)

            struct Negotiation: Decodable { let url: String }
            let negotiation = try JSONDecoder().decode(Negotiation.self, from: data)
            guard let wsURL = URL(string: negotiation.url) else {
                status = "Bad WebSocket URL"
                return
            }

            let socket = URLSession.shared.webSocketTask(with: wsURL)
            task = socket
            socket.resume()
            status = "Connected"

            while running {
                let message = try await socket.receive()
                switch message {
                case .string(let text):
                    handle(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) { handle(text) }
                @unknown default:
                    break
                }
            }
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        // Tutorial's messagehandler wraps the device payload in "IotData".
        let payload = (obj["IotData"] as? [String: Any]) ?? obj
        guard let value = (payload["moisture"] as? NSNumber)?.doubleValue else { return }

        latest = value
        hasData = true

        let now = Date()
        readings.append(Reading(time: now, value: value))
        let cutoff = now.addingTimeInterval(-windowSeconds)
        readings.removeAll { $0.time < cutoff }
    }
}
