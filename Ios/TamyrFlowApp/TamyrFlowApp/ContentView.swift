import SwiftUI
internal import Auth
import CoreBluetooth

// MARK: - Root

struct ContentView: View {
    var body: some View {
        TabView {
            HealthView()
                .tabItem { Label("Здоровье", systemImage: "cross.case.fill") }

            DeviceView()
                .tabItem { Label("Устройство", systemImage: "applewatch") }

            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .tint(AppColors.orange)
    }
}

// MARK: - Colors / Helpers

enum AppColors {
    static let orange = Color(red: 0.96, green: 0.55, blue: 0.17)
    static let softBg = Color(red: 0.98, green: 0.96, blue: 0.94)
    static let cardBg = Color.white
    static let textSecondary = Color.black.opacity(0.55)
    static let divider = Color.black.opacity(0.08)
}

struct CardContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(AppColors.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }
}


// MARK: - Здоровье (Home)

struct HealthView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    CardContainer {
                        HStack(spacing: 12) {
                            Image(systemName: "burst.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColors.orange)

                            Text("Устройство отключено")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColors.orange)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.orange.opacity(0.8))
                        }
                        .padding(.vertical, 2)
                    }

                    CardContainer {
                        VStack(spacing: 14) {
                            StepsRingView(current: 0, goal: 8000)

                            HStack(spacing: 14) {
                                MetricMini(title: "Калории", value: "0.0", unit: "ккал", color: AppColors.orange)
                                MetricMini(title: "Общее количество сна", value: "0", unit: "м", color: Color.purple.opacity(0.9))
                                MetricMini(title: "Расстояние", value: "0.00", unit: "км", color: Color.cyan)
                            }
                        }
                    }

                    CardContainer {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().stroke(Color.cyan.opacity(0.35), lineWidth: 2)
                                Image(systemName: "figure.arms.open")
                                    .foregroundStyle(Color.cyan)
                            }
                            .frame(width: 44, height: 44)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Очень низкий уровень активности")
                                    .font(.system(size: 16, weight: .semibold))
                                HStack {
                                    Text("0 шаг")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppColors.textSecondary)
                                    Spacer()
                                    Text("Следующий уровень: 3000 шаги")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppColors.textSecondary)
                                }

                                ProgressView(value: 0.0)
                                    .tint(AppColors.orange)
                            }
                        }
                    }

                    CardContainer {
                        VStack(spacing: 14) {
                            HStack {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle().fill(AppColors.orange)
                                        Image(systemName: "figure.run")
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 34, height: 34)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Спортивный рекорд")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Недавняя активность")
                                            .font(.system(size: 13))
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(AppColors.orange)
                                    .font(.system(size: 18, weight: .semibold))
                            }

                            Divider().overlay(AppColors.divider)

                            HStack(spacing: 10) {
                                RecordMetric(icon: "clock.fill", title: "Активность", value: "00", unit: "минут")
                                RecordMetric(icon: "location.fill", title: "Расстояние", value: "0.00", unit: "км")
                                RecordMetric(icon: "flame.fill", title: "Калории", value: "0.0", unit: "ккал")
                            }

                            Button { } label: {
                                Text("Тренировка в приложении")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.orange.opacity(0.15))
                                    .foregroundStyle(AppColors.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        SmallTile(title: "Сон", icon: "bed.double.fill")
                        SmallTile(title: "Пульс", icon: "heart.fill")
                    }
                    .padding(.horizontal, 2)

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .background(AppColors.softBg)
        }
    }
}

struct StepsRingView: View {
    let current: Int
    let goal: Int
    var progress: Double { goal == 0 ? 0 : Double(current) / Double(goal) }

    var body: some View {
        ZStack {
            Circle().stroke(Color.black.opacity(0.08), lineWidth: 18)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppColors.orange.opacity(0.35), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text("\(current)").font(.system(size: 36, weight: .bold))
                Text("/\(goal)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Image(systemName: "shoeprints.fill")
                    .foregroundStyle(AppColors.orange.opacity(0.85))
                    .padding(.top, 4)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.top, 6)
    }
}

struct MetricMini: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle().fill(color).frame(width: 4, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(value).font(.system(size: 26, weight: .bold))
                Text(unit).font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecordMetric: View {
    let icon: String
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(AppColors.orange)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(value).font(.system(size: 22, weight: .bold))
                Text(unit).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmallTile: View {
    let title: String
    let icon: String

    var body: some View {
        CardContainer {
            HStack {
                Text(title).font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: icon).foregroundStyle(AppColors.orange)
            }
        }
    }
}

// MARK: - Device

struct DeviceView: View {
    @StateObject private var ble = BluetoothManager()
    @State private var selected: DiscoveredDevice? = nil
    @State private var showLogs = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // Статус
                HStack {
                    Circle()
                        .fill(ble.isBluetoothOn ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(ble.isBluetoothOn ? "Bluetooth включен" : "Bluetooth выключен")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Подключенное устройство
                if let p = ble.connected {
                    CardContainer {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(p.name ?? "Connected")
                                    .font(.system(size: 16, weight: .bold))
                                Text(p.identifier.uuidString)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                ble.disconnect()
                            } label: {
                                Text("Отключить")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.red.opacity(0.12))
                                    .foregroundStyle(.red)
                                    .clipShape(Capsule())
                            }
                        }

                        Divider().padding(.vertical, 8)

                        Button {
                            showLogs = true
                        } label: {
                            HStack {
                                Image(systemName: "terminal.fill")
                                Text("Открыть логи BLE")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.system(size: 15, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }

                // Список устройств
                List {
                    Section {
                        ForEach(ble.discovered) { d in
                            Button {
                                selected = d
                                ble.connect(to: d)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(d.name)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(d.id.uuidString)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("RSSI \(d.rssi)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text(ble.isScanning ? "Поиск устройств..." : "Найденные устройства")
                    }
                }
                .listStyle(.plain)

                // Кнопки снизу
                HStack(spacing: 12) {
                    Button {
                        if ble.isScanning { ble.stopScan() } else { ble.startScan() }
                    } label: {
                        Text(ble.isScanning ? "Стоп" : "Найти часы")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.85))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!ble.isBluetoothOn)

                    Button {
                        showLogs = true
                    } label: {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 54, height: 48)
                            .background(Color.black.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .navigationTitle("Устройство")
            .sheet(isPresented: $showLogs) {
                BLELogsView(ble: ble)
            }
        }
    }
}

struct BLELogsView: View {
    @ObservedObject var ble: BluetoothManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ble.logLines.indices, id: \.self) { i in
                    Text(ble.logLines[i])
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("BLE Логи")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Очистить") { ble.clearLog() }
                }
            }
        }
    }
}


// MARK: - Profile

struct ProfileView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            if authVM.session == nil {
                LoginView(auth: authVM)
                    .navigationTitle("Профиль")
                    .background(
                        LinearGradient(colors: [AppColors.softBg, Color.white],
                                       startPoint: .top, endPoint: .bottom)
                    )
            } else {
                loggedInProfile
                    .navigationTitle("Профиль")
                    .background(
                        LinearGradient(colors: [AppColors.softBg, Color.white],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
        }
        .alert("Удалить аккаунт?", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                Task { await authVM.deleteAccount() } // ✅ правильный вызов
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Аккаунт будет удалён навсегда вместе с профилем и данными здоровья.")
        }
    }

    private var loggedInProfile: some View {
        ScrollView {
            VStack(spacing: 14) {

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(AppColors.orange, lineWidth: 4)
                            .frame(width: 110, height: 110)

                        Circle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 96, height: 96)

                        Image(systemName: "person.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.95))
                    }

                    Text(authVM.profileUsername ?? authVM.session?.user.email ?? "Пользователь")
                        .font(.system(size: 20, weight: .bold))

                    if let err = authVM.errorText {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await authVM.signOut() }
                    } label: {
                        Text(authVM.loading ? "Выходим..." : "Выйти")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .disabled(authVM.loading)
                }
                .padding(.top, 12)

                CardContainer {
                    VStack(spacing: 0) {
                        ProfileRow(icon: "doc.text.fill", title: "Службы Данных")
                        Divider().overlay(AppColors.divider)
                        ProfileRow(icon: "location.fill", title: "Разрешения")
                        Divider().overlay(AppColors.divider)
                        ProfileRow(icon: "info.circle.fill", title: "О приложении")
                    }
                }

                CardContainer {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                            Text(authVM.loading ? "Удаляем..." : "Удалить аккаунт")
                                .foregroundStyle(.red)
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(authVM.loading)
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.orange)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 22)

                Text(title)
                    .foregroundStyle(.black)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColors.textSecondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
