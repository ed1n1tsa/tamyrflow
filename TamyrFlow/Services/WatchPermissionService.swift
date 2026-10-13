import Combine
import CoreLocation
import Foundation
import HealthKit
import UserNotifications

/// Requests real iOS permissions used by the watch connect flow.
@MainActor
final class WatchPermissionService: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum Kind: String, CaseIterable, Identifiable {
        case bluetooth
        case notifications
        case health
        case location

        var id: String { rawValue }
    }

    enum Status {
        case pending
        case granted
        case denied
        case unavailable
    }

    @Published private(set) var statuses: [Kind: Status] = [
        .bluetooth: .pending,
        .notifications: .pending,
        .health: .pending,
        .location: .pending
    ]

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    var allGrantedOrUnavailable: Bool {
        Kind.allCases.allSatisfy { kind in
            let s = statuses[kind] ?? .pending
            return s == .granted || s == .unavailable
        }
    }

    func refreshBluetooth(isOn: Bool, sdkConfigured: Bool) {
        if !sdkConfigured {
            statuses[.bluetooth] = .pending
        } else {
            statuses[.bluetooth] = isOn ? .granted : .denied
        }
    }

    func requestAll(bleConfigured: () -> Void) async {
        bleConfigured()
        await requestNotifications()
        await requestHealth()
        await requestLocation()
    }

    func request(_ kind: Kind, bleConfigured: () -> Void) async {
        switch kind {
        case .bluetooth:
            bleConfigured()
        case .notifications:
            await requestNotifications()
        case .health:
            await requestHealth()
        case .location:
            await requestLocation()
        }
    }

    private func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            statuses[.notifications] = .granted
        case .denied:
            statuses[.notifications] = .denied
        case .notDetermined:
            let ok = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            statuses[.notifications] = ok ? .granted : .denied
        @unknown default:
            statuses[.notifications] = .pending
        }
    }

    private func requestHealth() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            statuses[.health] = .unavailable
            return
        }
        let store = HKHealthStore()
        var read: Set<HKObjectType> = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { read.insert(steps) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { read.insert(hr) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { read.insert(sleep) }

        do {
            try await store.requestAuthorization(toShare: [], read: read)
            statuses[.health] = .granted
        } catch {
            statuses[.health] = .denied
        }
    }

    private func requestLocation() async {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            statuses[.location] = .granted
            return
        case .denied, .restricted:
            statuses[.location] = .denied
            return
        case .notDetermined:
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                locationContinuation = cont
                locationManager.requestWhenInUseAuthorization()
            }
        @unknown default:
            statuses[.location] = .pending
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                statuses[.location] = .granted
            case .denied, .restricted:
                statuses[.location] = .denied
            case .notDetermined:
                statuses[.location] = .pending
            @unknown default:
                statuses[.location] = .pending
            }
            locationContinuation?.resume()
            locationContinuation = nil
        }
    }
}
