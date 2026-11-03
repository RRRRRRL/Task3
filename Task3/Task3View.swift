//
//  Task3View.swift
//  Task3
//
//  Created by f3223375 on 3/11/2026.
//

import SwiftUI
import Charts

struct Task3View: View {
    var client: Task3Client

    private var isOK: Bool { client.latest >= client.threshold }

    private var message: String {
        guard client.hasData else { return "Waiting for data…" }
        return isOK ? "Plants are OK" : "Plants need water NOW!!!"
    }

    private var background: Color {
        guard client.hasData else { return Color.gray.opacity(0.3) }
        return isOK ? Color(red: 0.0, green: 0.85, blue: 0.2)
                    : Color(red: 1.0, green: 0.1, blue: 0.1)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(String(format: "%.1f", client.latest))
                .font(.system(size: 64, weight: .bold, design: .rounded))

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Chart {
                    ForEach(client.readings) { r in
                        LineMark(x: .value("Time", r.time),
                                 y: .value("Moisture", r.value))
                    }
                    RuleMark(y: .value("Threshold", client.threshold))
                        .foregroundStyle(.white)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
                .chartYScale(domain: 0...100)
                .chartXScale(domain: context.date.addingTimeInterval(-client.windowSeconds)...context.date)
            }
            .frame(height: 250)
            .padding()
            .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))

            Text(client.status).font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .animation(.easeInOut(duration: 0.3), value: isOK)
        .task { await client.start() }
    }
}
