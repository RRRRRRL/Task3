//
//  Task3App.swift
//  Task3
//
//  Created by f3223375 on 3/11/2026.
//

import SwiftUI

@main
struct Task3App: App {
    @State private var client = Task3Client()

    var body: some Scene {
        WindowGroup {
            Task3View(client: client)
        }
    }
}
