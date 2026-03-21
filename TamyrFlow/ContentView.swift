//
//  ContentView.swift
//  TamyrFlow
//
//  Created by Macbook on 21.03.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            TFScreenBackground()
            RootTabView()
                .environmentObject(vm)
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.accent)
        .task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await vm.performLaunchWatchSyncIfPossible()
        }
        .onAppear {
            vm.handleAppForegroundActive(scenePhase == .active)
        }
        .onChange(of: scenePhase) { _, phase in
            vm.handleAppForegroundActive(phase == .active)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BluetoothViewModel())
}
