//
//  SwiftUITaskApp.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import SwiftUI
import SwiftData

@main
struct SwiftUITaskApp: App {
    var body: some Scene {
        WindowGroup {
            SplashScreen()
        }
        .modelContainer(for: Species.self)
    }
}
