import Foundation
import CoreBluetooth
import Combine
import Supabase

@MainActor
final class BluetoothManager: NSObject, ObservableObject {

    // MARK: Public state
    @Published var isBluetoothOn = false
    @Published var isScanning = false
    @Published var discovered: [DiscoveredDevice] = []
    @Published var connected: CBPeripheral?

    @Published var logLines: [String] = []

    // Последние данные
    @Published var latestPulse: Int?
    @Published var latestBloodPressure: String?
    @Published var lastVitalsAt: Date?

    // Настройки пользователя (чтобы писать в БД)
    @Published var currentUserId: UUID?
    @Published var currentUsername: String?

    // MARK: Private
    private var central: CBCentralManager!
    private var seen: [UUID: DiscoveredDevice] = [:]

    // Каналы команд/ответа (под E900)
    private var cmdChar: CBCharacteristic?
    private var notifyChar: CBCharacteristic?

    // Таймер каждые 30 минут
    private var vitalsTimer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: Scan / Connect

    func startScan() {
        guard isBluetoothOn else { addLog("❌ Bluetooth OFF"); return }
        discovered.removeAll()
        seen.removeAll()
        isScanning = true
        addLog("🔎 Scan started…")
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        addLog("🛑 Scan stopped")
    }

    func connect(to device: DiscoveredDevice) {
        stopScan()
        device.peripheral.delegate = self
        addLog("🔌 Connecting to: \(device.name) \(device.id.uuidString)")
        central.connect(device.peripheral, options: nil)
    }

    func disconnect() {
        stopVitalsTimer()
        guard let p = connected else { return }
        addLog("🔌 Disconnecting: \(p.name ?? "Unknown")")
        central.cancelPeripheralConnection(p)
    }

    // MARK: - 30 min scheduler

    func startVitalsEvery30Minutes() {
        stopVitalsTimer()
        addLog("⏱️ Start vitals timer: every 30 min")

        // Первый замер — сразу (если подключено)
        Task { await requestVitalsAndUpload() }

        vitalsTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.requestVitalsAndUpload() }
        }
        RunLoop.main.add(vitalsTimer!, forMode: .common)
    }

    func stopVitalsTimer() {
        vitalsTimer?.invalidate()
        vitalsTimer = nil
    }

    // MARK: - Main action: request -> wait notify -> upload

    func requestVitalsAndUpload() async {
        guard let p = connected else { addLog("⚠️ Not connected"); return }
        guard let userId = currentUserId, let username = currentUsername else {
            addLog("⚠️ No user set for upload (userId/username)")
            return
        }
        guard let cmdChar, let notifyChar else {
            addLog("⚠️ No cmd/notify characteristic выбран (E900 протокол)")
            return
        }

        // 1) Убедимся, что notify включён
        if !notifyChar.isNotifying {
            p.setNotifyValue(true, for: notifyChar)
            addLog("🔔 setNotify(true) \(notifyChar.uuid.uuidString)")
        }

        // 2) Отправляем команду “дай пульс/давление” (БАЙТЫ ПОКА ПЛЕЙСХОЛДЕР)
        // !!! Тут мы подставим правильные байты, когда ты пришлёшь notify пакеты.
        let cmd = Data([0xA0, 0x01, 0x01]) // <- placeholder
        p.writeValue(cmd, for: cmdChar, type: cmdChar.properties.contains(.write) ? .withResponse : .withoutResponse)
        addLog("📤 requestVitals cmd: \(cmd.hexString) to \(cmdChar.uuid.uuidString)")

        // 3) Ждём немного, пока придут notify пакеты и обновят latestPulse/latestBloodPressure
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let pulse = latestPulse
        let bp = latestBloodPressure
        lastVitalsAt = Date()

        // Если данных нет — не пишем мусор
        if pulse == nil && bp == nil {
            addLog("⚠️ No vitals parsed yet (pulse/bp nil). Upload skipped.")
            return
        }

        // 4) Пишем в Supabase
        do {
            let payload = WatchHealthInsert(
                user_id: userId,
                username: username,
                watch_id: p.name ?? "E900",
                x_location: nil,
                y_location: nil,
                pulse: pulse,
                blood_pressure: bp
            )

            // В зависимости от версии SDK: execute() может вернуть Void/Response — нам ок, лишь бы не ошибка
            _ = try await SupabaseManager.client
                .from("watch_health_data")
                .insert(payload)
                .execute()

            addLog("✅ Uploaded vitals: pulse=\(pulse.map(String.init) ?? "nil") bp=\(bp ?? "nil")")

        } catch {
            addLog("❌ Upload error: \(error.localizedDescription)")
        }
    }

    // MARK: Utils

    func setCurrentUser(userId: UUID, username: String) {
        self.currentUserId = userId
        self.currentUsername = username
        addLog("👤 Upload user set: \(username) \(userId.uuidString)")
    }

    func clearLog() { logLines.removeAll() }

    private func addLog(_ s: String) {
        let ts = Self.timeString()
        logLines.insert("[\(ts)] \(s)", at: 0)
        print(s)
    }

    private static func timeString() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }

    private func updateDiscovered(_ peripheral: CBPeripheral, rssi: NSNumber, adv: [String: Any]) {
        let name = (peripheral.name ?? (adv[CBAdvertisementDataLocalNameKey] as? String) ?? "Unknown").trimmingCharacters(in: .whitespacesAndNewlines)
        let d = DiscoveredDevice(id: peripheral.identifier, name: name.isEmpty ? "Unknown" : name, rssi: rssi.intValue, peripheral: peripheral)
        seen[peripheral.identifier] = d
        discovered = Array(seen.values).sorted { $0.rssi > $1.rssi }
    }

    private func pickE900Channels(from services: [CBService]) {
        // По логу: самый вероятный канал: AE40 -> AE41(writeNR) + AE42(notify)
        // :contentReference[oaicite:1]{index=1}

        for s in services {
            guard let chars = s.characteristics else { continue }

            if s.uuid == CBUUID(string: "0000AE40-0000-1000-8000-00805F9B34FB") {
                for c in chars {
                    if c.uuid == CBUUID(string: "0000AE41-0000-1000-8000-00805F9B34FB") { cmdChar = c }
                    if c.uuid == CBUUID(string: "0000AE42-0000-1000-8000-00805F9B34FB") { notifyChar = c }
                }
            }

            // Фолбэк: если AE40 не сработает, потом переключим на F002/F003/F008/FEE7
        }

        if let cmdChar, let notifyChar {
            addLog("✅ E900 channel selected: cmd=\(cmdChar.uuid.uuidString), notify=\(notifyChar.uuid.uuidString)")
        } else {
            addLog("⚠️ E900 channel NOT selected yet (need another service/char pair)")
        }
    }
}

// MARK: - Central delegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothOn = (central.state == .poweredOn)
        addLog("📶 Bluetooth state: \(central.state.rawValue) \(isBluetoothOn ? "ON" : "OFF")")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        updateDiscovered(peripheral, rssi: RSSI, adv: advertisementData)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connected = peripheral
        addLog("✅ Connected: \(peripheral.name ?? "Unknown")")
        addLog("🔍 Discover services…")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        addLog("🔌 Disconnected: \(peripheral.name ?? "Unknown") err=\(error?.localizedDescription ?? "nil")")
        if connected?.identifier == peripheral.identifier {
            connected = nil
        }
        stopVitalsTimer()
    }
}

// MARK: - Peripheral delegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error { addLog("❌ Discover services error: \(error.localizedDescription)"); return }
        let svcs = peripheral.services ?? []
        addLog("📦 Services: \(svcs.count)")
        for s in svcs {
            addLog("   • \(s.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error { addLog("❌ Discover chars error: \(error.localizedDescription)"); return }
        let chars = service.characteristics ?? []
        addLog("🧩 Chars for \(service.uuid.uuidString): \(chars.count)")
        for c in chars {
            addLog("   ◦ \(c.uuid.uuidString) props=\(c.properties.pretty)")

            if c.properties.contains(.notify) || c.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: c)
                addLog("     🔔 notify ON \(c.uuid.uuidString)")
            }
            if c.properties.contains(.read) {
                peripheral.readValue(for: c)
                addLog("     📥 read \(c.uuid.uuidString)")
            }
        }

        // Когда сервисы/характеристики уже открыты — выбираем канал E900
        if let svcs = peripheral.services, svcs.allSatisfy({ $0.characteristics != nil }) {
            pickE900Channels(from: svcs)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error { addLog("❌ Value error: \(error.localizedDescription)"); return }
        guard let data = characteristic.value else { return }

        addLog("📨 \(characteristic.uuid.uuidString) (\(data.count)b): \(data.hexString)")

        // TODO: здесь будет парсер протокола E900.
        // Пока заглушка: пытаемся найти “пульс” как 1 байт 40..200 (это НЕ гарантировано)
        // Как только ты пришлёшь 2-3 пакета после команды — сделаю точный парсер.
        if let maybePulse = E900Parser.tryParsePulse(from: data) {
            latestPulse = maybePulse
            addLog("❤️ pulse parsed = \(maybePulse)")
        }
        if let maybeBP = E900Parser.tryParseBloodPressure(from: data) {
            latestBloodPressure = maybeBP
            addLog("🩸 bp parsed = \(maybeBP)")
        }
    }
}

// MARK: - Models / Helpers

struct DiscoveredDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension CBCharacteristicProperties {
    var pretty: String {
        var items: [String] = []
        if contains(.read) { items.append("read") }
        if contains(.write) { items.append("write") }
        if contains(.writeWithoutResponse) { items.append("writeNR") }
        if contains(.notify) { items.append("notify") }
        if contains(.indicate) { items.append("indicate") }
        return items.isEmpty ? "-" : items.joined(separator: "|")
    }
}

extension Data {
    var hexString: String { self.map { String(format: "%02X", $0) }.joined(separator: " ") }
}

enum E900Parser {
    static func tryParsePulse(from data: Data) -> Int? {
        // Заглушка: ищем байт похожий на bpm
        for b in data {
            let v = Int(b)
            if v >= 40 && v <= 200 { return v }
        }
        return nil
    }

    static func tryParseBloodPressure(from data: Data) -> String? {
        // Заглушка: если вдруг встречаются 2 значения 60..200 подряд (SYS/DIA)
        let bytes = Array(data)
        guard bytes.count >= 2 else { return nil }
        for i in 0..<(bytes.count - 1) {
            let s = Int(bytes[i])
            let d = Int(bytes[i+1])
            if s >= 90 && s <= 200 && d >= 50 && d <= 130 && s > d {
                return "\(s)/\(d)"
            }
        }
        return nil
    }
}
