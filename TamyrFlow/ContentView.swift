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

    /// Animated splash overlays the auth gate once per cold start of this view tree.
    @State private var showSplash = true

    var body: some View {
        ZStack {
            appRoot

            if showSplash {
                AnimatedSplashView {
                    withAnimation(.easeOut(duration: 0.35)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
    }

    @ViewBuilder
    private var appRoot: some View {
        ZStack {
            if auth.isBootstrapping {
                // Match splash navy while session restores (no white flash).
                Color("SplashNavy").ignoresSafeArea()
            } else if !auth.isAuthenticated {
                OnboardingFlowView {
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
