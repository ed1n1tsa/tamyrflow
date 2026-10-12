//
//  TamyrFlowApp.swift
//  TamyrFlow
//
//  Created by Macbook on 21.03.2026.
//

import SwiftUI

@main
struct TamyrFlowApp: App {
    @StateObject private var vm = BluetoothViewModel()

    init() {
        AppFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
        }
    }
}
