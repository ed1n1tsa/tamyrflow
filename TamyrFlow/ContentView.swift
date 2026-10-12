//
//  ContentView.swift
//  TamyrFlow
//
//  Created by Macbook on 21.03.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var auth: AuthService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if auth.isBootstrapping {
                ProfileSetupBackground()
                ProgressView()
                    .tint(.white)
            } else if !auth.isAuthenticated {
                OnboardingFlowView {
                    // Session is owned by AuthService; gate switches automatically.
                    OnboardingStorage.markCompleted()
                }
                .transition(.opacity)
            } else if auth.needsProfileSetup {
                ProfileSetupFlowView(
                    onFinished: {},
                    onCancelToAuth: {
                        Task { await auth.signOut() }
                    }
                )
                .transition(.opacity)
            } else {
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
                    syncBandPersonalFromProfile()
                }
                .onAppear {
                    vm.handleAppForegroundActive(scenePhase == .active)
                }
                .onChange(of: scenePhase) { _, phase in
                    vm.handleAppForegroundActive(phase == .active)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: auth.needsProfileSetup)
        .animation(.easeInOut(duration: 0.3), value: auth.isBootstrapping)
    }

    private func syncBandPersonalFromProfile() {
        guard let p = auth.profile else { return }
        if let h = p.heightCm { vm.height = "\(h)" }
        if let w = p.weightKg { vm.weight = "\(Int(w.rounded()))" }
        if let a = p.age { vm.age = "\(a)" }
        switch p.gender {
        case .female: vm.sex = 0
        case .male: vm.sex = 1
        default: break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BluetoothViewModel())
        .environmentObject(AuthService())
        .environmentObject(LanguageStore())
}
