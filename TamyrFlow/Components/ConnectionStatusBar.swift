import SwiftUI
import VeepooBleSDK

/// Always-visible connection strip so users see watch + link state (not only the system BT icon).
struct ConnectionStatusBar: View {
    @ObservedObject var ble: BleService
    @ObservedObject var health: VeepooHealthService

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: phoneBtIconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(phoneBtIconTint)

            Image(systemName: "applewatch")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(connectedTint)

            VStack(alignment: .leading, spacing: 2) {
                Text(deviceLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(statusLine)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if health.operation != .idle {
                ProgressView()
                    .scaleEffect(0.85)
                    .tint(AppTheme.accent)
            }

            statusPill
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var phoneBtIconName: String {
        if ble.isBluetoothOn || ble.isPhoneBluetoothStatePending {
            return "antenna.radiowaves.left.and.right"
        }
        return "antenna.radiowaves.left.and.right.slash"
    }

    private var phoneBtIconTint: Color {
        if ble.isBluetoothOn || ble.isPhoneBluetoothStatePending {
            return AppTheme.accent
        }
        return .white.opacity(0.35)
    }

    private var deviceLine: String {
        if let name = ble.connectedDevice?.deviceName, !name.isEmpty {
            return name
        }
        return L10n.ConnBar.noDevice
    }

    private var statusLine: String {
        if !ble.isSDKConfigured {
            return L10n.ConnBar.sdkInit
        }
        if ble.isPhoneBluetoothStatePending {
            return L10n.ConnBar.btWarming
        }
        let phoneBt = ble.isBluetoothOn ? L10n.ConnBar.phoneBtOn : L10n.ConnBar.phoneBtOff
        if !ble.isBluetoothOn {
            return "\(phoneBt) · \(L10n.ConnBar.btOff)"
        }
        if ble.connectedDevice == nil {
            return "\(phoneBt) · \(L10n.ConnBar.notLinked)"
        }
        return "\(phoneBt) · \(ble.connectionStatus.localizedLabel)"
    }

    private var connectedTint: Color {
        switch ble.connectionStatus {
        case .verified, .connected:
            return AppTheme.accent
        case .connecting:
            return AppTheme.warning
        default:
            return .white.opacity(0.35)
        }
    }

    private var statusPill: some View {
        Text(ble.connectionStatus.localizedLabel)
            .font(.caption2.weight(.bold))
            .foregroundStyle(pillForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(pillBackground)
            }
    }

    private var pillForeground: Color {
        switch ble.connectionStatus {
        case .verified, .connected:
            return Color(red: 0.06, green: 0.08, blue: 0.14)
        case .connecting:
            return Color(red: 0.06, green: 0.08, blue: 0.14)
        default:
            return .white.opacity(0.85)
        }
    }

    private var pillBackground: Color {
        switch ble.connectionStatus {
        case .verified, .connected:
            return AppTheme.accent
        case .connecting:
            return AppTheme.warning
        default:
            return Color.white.opacity(0.12)
        }
    }
}
