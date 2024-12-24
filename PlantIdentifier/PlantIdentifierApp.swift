//
//  PlantIdentifierApp.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 23.12.2024.
//

import SwiftUI
import TPackage

@main
struct PlantIdentifierApp: App {
    @StateObject var premiumManager = TKPremiumManager.shared
    init() {
        TPackage.configure(withAPIKey: "appl_FVBGRgjvZaBXCZZgNduXIxsSWFR", entitlementIdentifier: "Premium")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(premiumManager)
        }
    }
}
