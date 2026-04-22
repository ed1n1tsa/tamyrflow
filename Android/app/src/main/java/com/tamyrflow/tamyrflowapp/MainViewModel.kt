package com.tamyrflow.tamyrflowapp

import android.app.Application
import android.bluetooth.BluetoothAdapter
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import com.inuker.bluetooth.library.Code
import com.inuker.bluetooth.library.Constants
import com.inuker.bluetooth.library.connect.response.BleWriteResponse
import com.inuker.bluetooth.library.model.BleGattProfile
import com.inuker.bluetooth.library.search.SearchResult
import com.inuker.bluetooth.library.search.response.SearchResponse
import com.inuker.bluetooth.library.utils.BluetoothUtils
import com.orhanobut.logger.Logger
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IABleConnectStatusListener
import com.veepoo.protocol.listener.base.IABluetoothStateListener
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.base.IConnectResponse
import com.veepoo.protocol.listener.base.INotifyResponse
import com.veepoo.protocol.listener.data.ICustomSettingDataListener
import com.veepoo.protocol.listener.data.IBPDetectDataListener
import com.veepoo.protocol.listener.data.IECGDetectListener
import com.veepoo.protocol.listener.data.IDeviceFuctionDataListener
import com.veepoo.protocol.listener.data.IHeartDataListener
import com.veepoo.protocol.listener.data.IPersonInfoDataListener
import com.veepoo.protocol.listener.data.IPwdDataListener
import com.veepoo.protocol.listener.data.ISocialMsgDataListener
import com.veepoo.protocol.listener.data.ISpo2hDataListener
import com.veepoo.protocol.listener.data.ISleepDataListener
import com.veepoo.protocol.listener.data.ISportDataListener
import com.veepoo.protocol.listener.data.ITemptureDetectDataListener
import com.veepoo.protocol.listener.data.AbsBloodGlucoseChangeListener
import com.veepoo.protocol.model.datas.BpData
import com.veepoo.protocol.model.datas.DeviceFunctionPackage1
import com.veepoo.protocol.model.datas.DeviceFunctionPackage2
import com.veepoo.protocol.model.datas.DeviceFunctionPackage3
import com.veepoo.protocol.model.datas.DeviceFunctionPackage4
import com.veepoo.protocol.model.datas.DeviceFunctionPackage5
import com.veepoo.protocol.model.datas.FunctionDeviceSupportData
import com.veepoo.protocol.model.datas.FunctionSocailMsgData
import com.veepoo.protocol.model.datas.HeartData
import com.veepoo.protocol.model.datas.PersonInfoData
import com.veepoo.protocol.model.datas.PwdData
import com.veepoo.protocol.model.datas.SleepData
import com.veepoo.protocol.model.datas.Spo2hData
import com.veepoo.protocol.model.datas.SportData
import com.veepoo.protocol.model.datas.TemptureDetectData
import com.veepoo.protocol.model.datas.EcgDetectInfo
import com.veepoo.protocol.model.datas.EcgDetectResult
import com.veepoo.protocol.model.datas.EcgDetectState
import com.veepoo.protocol.model.datas.EcgDiagnosis
import com.veepoo.protocol.model.enums.EBPDetectModel
import com.veepoo.protocol.model.enums.EBloodGlucoseRiskLevel
import com.veepoo.protocol.model.enums.EBloodGlucoseStatus
import com.veepoo.protocol.model.enums.EOprateStauts
import com.veepoo.protocol.model.enums.EPwdStatus
import com.veepoo.protocol.model.enums.ESex
import com.veepoo.protocol.model.settings.CustomSettingData
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlin.math.roundToInt

data class ScannedDeviceUi(
    val address: String,
    val name: String,
    val rssi: Int
)

data class MainUiState(
    val bluetoothOn: Boolean = false,
    val sdkReady: Boolean = true,
    val scanning: Boolean = false,
    val devices: List<ScannedDeviceUi> = emptyList(),
    val connectedName: String? = null,
    val connectedAddress: String? = null,
    val handshakeOk: Boolean = false,
    val connectionMessage: String = "Найдите браслет и нажмите Подключить.",
    val debugLine: String = "",
    val pulseBpm: Int? = null,
    val pulseAvgBpm: Int? = null,
    val pulseSeries: List<Float> = emptyList(),
    val spo2Percent: Int? = null,
    val spo2Series: List<Float> = emptyList(),
    val spo2AvgPercent: Int? = null,
    val bpHigh: Int? = null,
    val bpLow: Int? = null,
    val bpAvgHigh: Int? = null,
    val bpAvgLow: Int? = null,
    val bpProgress: Int = 0,
    val measuringBp: Boolean = false,
    val glucoseMmolL: Float? = null,
    val glucoseAvgMmolL: Float? = null,
    val glucoseProgress: Int = 0,
    val measuringGlucose: Boolean = false,
    val ecgProgress: Int = 0,
    val ecgAvgHeart: Int? = null,
    /** Normalized ECG samples for UI (raw ADC units); capped in ViewModel. */
    val ecgWaveform: List<Float> = emptyList(),
    val measuringEcg: Boolean = false,
    val measuringPulse: Boolean = false,
    val measuringSpo2: Boolean = false,
    val measuringTemp: Boolean = false,
    val bodyTempC: Float? = null,
    val bodyTempAvgC: Float? = null,
    val skinTempC: Float? = null,
    val tempSeries: List<Float> = emptyList(),
    val stepsToday: Int = 0,
    /** Daily step goal for the ring (UI). */
    val stepsGoal: Int = 10_000,
    val distanceMetersToday: Int = 0,
    val caloriesKcalToday: Float = 0f,
    val sleepMinutesToday: Int = 0
)

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val mainHandler = Handler(Looper.getMainLooper())
    /** True after startDetectHeart write ack; retry logic must not use [MainUiState.debugLine] (other BLE writes overwrite it). */
    private var pulseSdkStartAcked: Boolean = false
    private var pulseStartSeq: Int = 0
    private var spo2StartSeq: Int = 0
    private var tempStartSeq: Int = 0
    private var bpStartSeq: Int = 0
    private var glucoseStartSeq: Int = 0
    private var ecgStartSeq: Int = 0
    /** Matches [ecgStartSeq] at session start; [finishEcgSession] increments only [ecgStartSeq] so stale ECG callbacks are ignored. */
    private var ecgSessionToken: Int = 0
    private val pulseSessionMaxMs = 60_000L
    private val measureSessionMaxMs = 60_000L
    /** Temperature: UI follows the watch; this is only a failsafe if the SDK never reports completion. */
    private val tempSessionFallbackMs = 120_000L
    /** BP / glucose / ECG: same — end from device callbacks; long failsafe if the SDK is silent. */
    private val measureSessionFallbackMs = 120_000L
    private val spo2SessionSamples = mutableListOf<Int>()
    private val tempSessionSamples = mutableListOf<Float>()
    private val bpSessionHighSamples = mutableListOf<Int>()
    private val bpSessionLowSamples = mutableListOf<Int>()
    private val glucoseSessionSamples = mutableListOf<Float>()
    private val ecgHeartSamples = mutableListOf<Int>()
    private var pulseSessionEnd: Runnable? = null
    private var spo2SessionEnd: Runnable? = null
    private var tempSessionEnd: Runnable? = null
    private var bpSessionEnd: Runnable? = null
    private var glucoseSessionEnd: Runnable? = null
    private var ecgSessionEnd: Runnable? = null
    private val watchDataDays = 3
    /** Veepoo SDK: after BLE notify, must run confirmDevicePwd (README 3.3.1) before other commands reliably. */
    private var pwdHandshakeConsumed: Boolean = false

    private val pwdSocialListener = object : ISocialMsgDataListener {
        override fun onSocialMsgSupportDataChange(data: FunctionSocailMsgData) {}
        override fun onSocialMsgSupportDataChange2(data: FunctionSocailMsgData) {}
    }

    private val pwdCustomSettingListener = object : ICustomSettingDataListener {
        override fun OnSettingDataChange(data: CustomSettingData) {}
    }

    private val pwdDeviceFunctionListener = object : IDeviceFuctionDataListener {
        override fun onFunctionSupportDataChange(data: FunctionDeviceSupportData) {}
        override fun onDeviceFunctionPackage1Report(p: DeviceFunctionPackage1) {}
        override fun onDeviceFunctionPackage2Report(p: DeviceFunctionPackage2) {}
        override fun onDeviceFunctionPackage3Report(p: DeviceFunctionPackage3) {}
        override fun onDeviceFunctionPackage4Report(p: DeviceFunctionPackage4) {}
        override fun onDeviceFunctionPackage5Report(p: DeviceFunctionPackage5) {}
    }
    private val noopWrite = object : IBleWriteResponse {
        override fun onResponse(code: Int) {}
    }
    /**
     * @param updateDebugLine If false, only logs — periodic step/sleep reads must not overwrite [MainUiState.debugLine]
     * (measurement UIs and diagnostics use it).
     */
    private fun writeResponse(tag: String, updateDebugLine: Boolean = true) = object : IBleWriteResponse {
        override fun onResponse(code: Int) {
            Logger.t("TamyrBLE").i("$tag writeCode=$code")
            if (!updateDebugLine) return
            post {
                _ui.update { s ->
                    s.copy(debugLine = "$tag code=$code")
                }
            }
        }
    }

    private fun cancelPulseSessionTimer() {
        pulseSessionEnd?.let { mainHandler.removeCallbacks(it) }
        pulseSessionEnd = null
    }

    private fun cancelSpo2SessionTimer() {
        spo2SessionEnd?.let { mainHandler.removeCallbacks(it) }
        spo2SessionEnd = null
    }

    private fun cancelTempSessionTimer() {
        tempSessionEnd?.let { mainHandler.removeCallbacks(it) }
        tempSessionEnd = null
    }

    private fun cancelBpSessionTimer() {
        bpSessionEnd?.let { mainHandler.removeCallbacks(it) }
        bpSessionEnd = null
    }

    private fun cancelGlucoseSessionTimer() {
        glucoseSessionEnd?.let { mainHandler.removeCallbacks(it) }
        glucoseSessionEnd = null
    }

    private fun cancelEcgSessionTimer() {
        ecgSessionEnd?.let { mainHandler.removeCallbacks(it) }
        ecgSessionEnd = null
    }

    /**
     * Veepoo [EcgDetectState]: [EcgDetectState.getCon] 2 = ECG closed; [EcgDetectState.getDataType]
     * 3 = test failed, 4 = test ended normally; [EcgDetectState.getProgress] reaches 100 when the watch finishes the phase.
     * (Some firmwares only update state / con without firing [onEcgDetectResultChange].)
     */
    private fun ecgWatchSignalsFinished(state: EcgDetectState): Boolean {
        if (state.getProgress() >= 100) return true
        if (state.getCon() == 2) return true
        val dt = state.getDataType()
        if (dt == 3 || dt == 4) return true
        return false
    }

    private val ecgDetectListener = object : IECGDetectListener {
        override fun onEcgDetectInfoChange(ecgDetectInfo: EcgDetectInfo) {}
        override fun onEcgDetectDiagnosisChange(ecgDiagnosis: EcgDiagnosis) {}

        override fun onEcgDetectStateChange(ecgDetectState: EcgDetectState) {
            if (ecgSessionToken != ecgStartSeq) return
            val h1 = ecgDetectState.getHr1()
            val h2 = ecgDetectState.getHr2()
            if (h1 > 0) ecgHeartSamples.add(h1)
            if (h2 > 0) ecgHeartSamples.add(h2)
            val avgHeart = ecgHeartSamples.takeIf { it.isNotEmpty() }?.average()?.roundToInt()
            val progress = ecgDetectState.getProgress()
            post {
                if (ecgSessionToken != ecgStartSeq) return@post
                _ui.update {
                    it.copy(
                        ecgProgress = progress,
                        ecgAvgHeart = avgHeart ?: it.ecgAvgHeart,
                        connectionMessage = "ЭКГ измерение... ${progress}%",
                        debugLine = "ecg p=$progress con=${ecgDetectState.getCon()} dt=${ecgDetectState.getDataType()}"
                    )
                }
                if (ecgSessionToken != ecgStartSeq) return@post
                if (_ui.value.measuringEcg && ecgWatchSignalsFinished(ecgDetectState)) {
                    finishEcgSession("ЭКГ: замер завершен на часах.", stopOnDevice = false)
                }
            }
        }

        override fun onEcgDetectResultChange(ecgDetectResult: EcgDetectResult) {
            post {
                if (ecgSessionToken != ecgStartSeq) return@post
                _ui.update {
                    it.copy(
                        ecgAvgHeart = ecgDetectResult.getAveHeart().takeIf { hr -> hr > 0 } ?: it.ecgAvgHeart,
                        ecgProgress = ecgDetectResult.getProgress(),
                        connectionMessage = "ЭКГ: результат получен."
                    )
                }
                if (ecgSessionToken != ecgStartSeq) return@post
                if (_ui.value.measuringEcg) {
                    finishEcgSession("ЭКГ: замер завершен.", stopOnDevice = false)
                }
            }
        }

        override fun onEcgADCChange(ecgData: IntArray, powerData: IntArray) {
            if (ecgSessionToken != ecgStartSeq) return
            val add = ArrayList<Float>(ecgData.size)
            for (v in ecgData) {
                if (v != Int.MAX_VALUE) add.add(v.toFloat())
            }
            if (add.isEmpty()) return
            post {
                if (ecgSessionToken != ecgStartSeq || !_ui.value.measuringEcg) return@post
                val merged = (_ui.value.ecgWaveform + add).takeLast(2400)
                _ui.update { it.copy(ecgWaveform = merged) }
            }
        }
    }

    private val _ui = MutableStateFlow(MainUiState())
    val ui: StateFlow<MainUiState> = _ui.asStateFlow()

    private val bluetoothStateListener = object : IABluetoothStateListener() {
        override fun onBluetoothStateChanged(openOrClosed: Boolean) {
            post { _ui.update { it.copy(bluetoothOn = openOrClosed) } }
        }
    }

    private val connectStatusListener = object : IABleConnectStatusListener() {
        override fun onConnectStatusChanged(mac: String, status: Int) {
            post {
                when (status) {
                    Constants.STATUS_CONNECTED ->
                        Logger.t("TamyrBLE").i("connected $mac")
                    Constants.STATUS_DISCONNECTED -> {
                        _ui.update {
                            it.copy(
                                connectedAddress = null,
                                connectedName = null,
                                handshakeOk = false,
                                connectionMessage = "Устройство отключено."
                            )
                        }
                    }
                }
            }
        }
    }

    private val searchResponse: SearchResponse = object : SearchResponse {
        override fun onSearchStarted() {
            post { _ui.update { it.copy(scanning = true, devices = emptyList()) } }
        }

        override fun onDeviceFounded(device: SearchResult) {
            post {
                _ui.update { state ->
                    val next = state.devices
                        .filter { it.address != device.address } +
                        ScannedDeviceUi(device.address, device.name ?: "Unknown", device.rssi)
                    state.copy(devices = next.sortedByDescending { it.rssi })
                }
            }
        }

        override fun onSearchStopped() {
            post { _ui.update { it.copy(scanning = false) } }
        }

        override fun onSearchCanceled() {
            post { _ui.update { it.copy(scanning = false) } }
        }
    }

    init {
        VPOperateManager.getInstance().registerBluetoothStateListener(bluetoothStateListener)
        refreshBluetoothFlag()
    }

    private fun post(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block()
        else mainHandler.post(block)
    }

    fun refreshBluetoothFlag() {
        val on = BluetoothUtils.isBluetoothEnabled()
        _ui.update { it.copy(bluetoothOn = on) }
    }

    fun startScan() {
        if (!BluetoothUtils.isBluetoothEnabled()) {
            _ui.update { it.copy(connectionMessage = "Включите Bluetooth на телефоне.") }
            return
        }
        try {
            VPOperateManager.getInstance().startScanDevice(searchResponse)
        } catch (e: SecurityException) {
            _ui.update { it.copy(connectionMessage = "Нет прав на Bluetooth. Разрешите доступ и повторите.") }
        } catch (t: Throwable) {
            _ui.update { it.copy(connectionMessage = "Не удалось начать поиск: ${t.localizedMessage ?: "ошибка"}") }
        }
    }

    fun stopScan() {
        try {
            VPOperateManager.getInstance().stopScanDevice()
        } catch (_: Throwable) { }
        _ui.update { it.copy(scanning = false) }
    }

    fun connect(device: ScannedDeviceUi) {
        stopScan()
        pwdHandshakeConsumed = false
        if (!BluetoothUtils.isBluetoothEnabled()) {
            _ui.update { it.copy(connectionMessage = "Bluetooth выключен. Сначала включите его.") }
            return
        }
        if (BluetoothAdapter.checkBluetoothAddress(device.address).not()) {
            _ui.update { it.copy(connectionMessage = "Некорректный MAC устройства.") }
            return
        }
        val mac = device.address
        val name = device.name
        try {
            VPOperateManager.getInstance().registerConnectStatusListener(mac, connectStatusListener)
        } catch (t: Throwable) {
            _ui.update { it.copy(connectionMessage = "Ошибка регистрации слушателя: ${t.localizedMessage ?: "ошибка"}") }
            return
        }
        _ui.update {
            it.copy(
                connectedAddress = mac,
                connectedName = name,
                handshakeOk = false,
                connectionMessage = "Подключение…",
                debugLine = ""
            )
        }
        try {
            VPOperateManager.getInstance().connectDevice(
                mac,
                name,
                object : IConnectResponse {
                override fun connectState(code: Int, profile: BleGattProfile?, isOadModel: Boolean) {
                    post {
                        if (code == Code.REQUEST_SUCCESS) {
                            _ui.update { s ->
                                s.copy(
                                    connectionMessage = "GATT готов, ждем notify...",
                                    handshakeOk = false,
                                    debugLine = "gatt=REQUEST_SUCCESS"
                                )
                            }
                        } else {
                            _ui.update { s ->
                                s.copy(
                                    connectionMessage = "Не удалось подключиться (code=$code).",
                                    connectedAddress = null,
                                    connectedName = null
                                )
                            }
                        }
                    }
                }
                },
                object : INotifyResponse {
                override fun notifyState(state: Int) {
                    post {
                        if (state == Code.REQUEST_SUCCESS) {
                            _ui.update { s ->
                                s.copy(
                                    handshakeOk = false,
                                    connectionMessage = "Проверка доступа к часам…",
                                    debugLine = "notify=REQUEST_SUCCESS"
                                )
                            }
                            runConfirmPwdChain()
                        } else {
                            _ui.update { s ->
                                s.copy(
                                    handshakeOk = false,
                                    connectionMessage = "Notify не готов (state=$state).",
                                    debugLine = "notify state=$state"
                                )
                            }
                        }
                    }
                }
                }
            )
        } catch (e: SecurityException) {
            _ui.update { it.copy(connectionMessage = "Нет доступа к Bluetooth CONNECT.") }
        } catch (t: Throwable) {
            _ui.update { it.copy(connectionMessage = "Ошибка подключения: ${t.localizedMessage ?: "unknown"}") }
        }
    }

    fun syncDailyMetrics() {
        if (!_ui.value.handshakeOk) return
        readTodaySteps()
        readTodaySleep()
    }

    private fun runConfirmPwdChain() {
        pwdHandshakeConsumed = false
        try {
            Log.i("TamyrFlow-TamyrBLE", "runConfirmPwdChain: confirmDevicePwd (Veepoo README 3.3.1)")
            VPOperateManager.getInstance().confirmDevicePwd(
                object : IBleWriteResponse {
                    override fun onResponse(code: Int) {
                        Logger.t("TamyrBLE").i("confirmDevicePwd writeCode=$code")
                        post {
                            if (code != Code.REQUEST_SUCCESS) {
                                _ui.update { s ->
                                    s.copy(
                                        handshakeOk = false,
                                        connectionMessage = "Часы не приняли авторизацию (code=$code).",
                                        debugLine = "confirmDevicePwd write code=$code"
                                    )
                                }
                            }
                        }
                    }
                },
                object : IPwdDataListener {
                    override fun onPwdDataChange(pwdData: PwdData) {
                        post {
                            if (pwdHandshakeConsumed) return@post
                            val st = pwdData.getmStatus()
                            Log.i("TamyrFlow-TamyrBLE", "PwdData status=$st device=${pwdData.deviceNumber}")
                            if (st == EPwdStatus.CHECK_FAIL) {
                                pwdHandshakeConsumed = true
                                _ui.update { s ->
                                    s.copy(
                                        handshakeOk = false,
                                        connectionMessage = "Неверный пароль устройства (по умолчанию 0000).",
                                        debugLine = "pwd CHECK_FAIL"
                                    )
                                }
                                return@post
                            }
                            pwdHandshakeConsumed = true
                            syncPersonInfoAfterPwdHandshake()
                        }
                    }

                    override fun onConnectionConfirmTimeout() {
                        post {
                            _ui.update { s ->
                                s.copy(
                                    handshakeOk = false,
                                    connectionMessage = "Таймаут подтверждения связи. Переподключите часы.",
                                    debugLine = "pwd confirm timeout"
                                )
                            }
                        }
                    }
                },
                pwdDeviceFunctionListener,
                pwdSocialListener,
                pwdCustomSettingListener,
                "0000",
                false
            )
        } catch (t: Throwable) {
            Log.e("TamyrFlow-TamyrBLE", "confirmDevicePwd failed", t)
            post {
                _ui.update {
                    it.copy(
                        handshakeOk = false,
                        connectionMessage = "Ошибка авторизации: ${t.localizedMessage ?: "unknown"}"
                    )
                }
            }
        }
    }

    private fun syncPersonInfoAfterPwdHandshake() {
        try {
            Log.i("TamyrFlow-TamyrBLE", "syncPersonInfo after pwd (README 3.3.2)")
            VPOperateManager.getInstance().syncPersonInfo(
                object : IBleWriteResponse {
                    override fun onResponse(code: Int) {
                        Logger.t("TamyrBLE").i("syncPersonInfo writeCode=$code")
                    }
                },
                object : IPersonInfoDataListener {
                    override fun OnPersoninfoDataChange(status: EOprateStauts) {
                        post {
                            Log.i("TamyrFlow-TamyrBLE", "syncPersonInfo result=$status")
                            val success = status == EOprateStauts.OPRATE_SUCCESS
                            _ui.update { s ->
                                s.copy(
                                    handshakeOk = true,
                                    connectionMessage = if (success) {
                                        "Подключено"
                                    } else {
                                        "Подключено (профиль: $status)"
                                    },
                                    debugLine = "person=$status"
                                )
                            }
                            syncDailyMetrics()
                        }
                    }
                },
                PersonInfoData(ESex.MAN, 175, 70, 30, 8000)
            )
        } catch (t: Throwable) {
            Log.e("TamyrFlow-TamyrBLE", "syncPersonInfo failed", t)
            post {
                _ui.update {
                    it.copy(
                        handshakeOk = true,
                        connectionMessage = "Подключено (без синхр. профиля)",
                        debugLine = "person sync exception"
                    )
                }
                syncDailyMetrics()
            }
        }
    }

    private fun readTodaySteps() {
        try {
            VPOperateManager.getInstance().readSportStep(
                writeResponse("readSportStep", updateDebugLine = false),
                object : ISportDataListener {
                    override fun onSportDataChange(sportData: SportData) {
                        val steps = sportData.getStep()
                        val meters = (sportData.getDis() * 1000.0).toInt().coerceAtLeast(0)
                        val kcal = sportData.getKcal().toFloat().coerceAtLeast(0f)
                        post {
                            _ui.update {
                                it.copy(
                                    stepsToday = steps,
                                    distanceMetersToday = meters,
                                    caloriesKcalToday = kcal,
                                    debugLine = "steps=$steps m=$meters kcal=$kcal"
                                )
                            }
                        }
                    }
                }
            )
        } catch (t: Throwable) {
            Log.w("TamyrFlow-TamyrBLE", "readSportStep failed", t)
        }
    }

    private fun readTodaySleep() {
        try {
            VPOperateManager.getInstance().readSleepData(
                writeResponse("readSleepData", updateDebugLine = false),
                object : ISleepDataListener {
                    private var maxSleep = 0

                    override fun onSleepDataChange(day: String, sleepData: SleepData) {
                        maxSleep = maxOf(maxSleep, sleepData.getAllSleepTime())
                        post { _ui.update { it.copy(sleepMinutesToday = maxSleep) } }
                    }

                    override fun onSleepProgress(progress: Float) {}

                    override fun onSleepProgressDetail(day: String, packageNumber: Int) {}

                    override fun onReadSleepComplete() {
                        post { _ui.update { it.copy(debugLine = "sleep=$maxSleep") } }
                    }
                },
                watchDataDays
            )
        } catch (t: Throwable) {
            Log.w("TamyrFlow-TamyrBLE", "readSleepData failed", t)
        }
    }

    fun disconnect() {
        cancelPulseSessionTimer()
        cancelSpo2SessionTimer()
        cancelTempSessionTimer()
        cancelBpSessionTimer()
        cancelGlucoseSessionTimer()
        cancelEcgSessionTimer()
        pwdHandshakeConsumed = false
        val mac = _ui.value.connectedAddress
        if (mac != null) {
            try {
                VPOperateManager.getInstance().unregisterConnectStatusListener(mac, connectStatusListener)
            } catch (_: Throwable) { }
        }
        try {
            VPOperateManager.getInstance().disconnectWatch(noopWrite)
        } catch (_: Throwable) { }
        _ui.update {
            it.copy(
                connectedAddress = null,
                connectedName = null,
                handshakeOk = false,
                measuringPulse = false,
                measuringSpo2 = false,
                measuringTemp = false,
                measuringBp = false,
                measuringGlucose = false,
                measuringEcg = false,
                ecgWaveform = emptyList(),
                stepsToday = 0,
                distanceMetersToday = 0,
                caloriesKcalToday = 0f,
                sleepMinutesToday = 0,
                connectionMessage = "Найдите браслет и нажмите Подключить."
            )
        }
    }

    fun startPulseMeasure() {
        Log.i("TamyrFlow-TamyrBLE", "VM startPulseMeasure called handshakeOk=${_ui.value.handshakeOk} connected=${_ui.value.connectedAddress != null}")
        if (!_ui.value.handshakeOk) {
            Log.w("TamyrFlow-TamyrBLE", "VM startPulseMeasure ignored: handshake not ready")
            return
        }
        if (hasOtherMeasurementRunning(allowPulse = true)) {
            _ui.update { it.copy(connectionMessage = "Сначала остановите другое измерение.") }
            return
        }
        cancelPulseSessionTimer()
        pulseStartSeq += 1
        pulseSdkStartAcked = false
        val seq = pulseStartSeq
        _ui.update {
            it.copy(
                measuringPulse = true,
                pulseAvgBpm = null,
                pulseSeries = emptyList(),
                debugLine = "",
                connectionMessage = "Запуск измерения пульса..."
            )
        }
        val heartListener = object : IHeartDataListener {
            override fun onDataChange(heart: HeartData) {
                val bpm = heart.getData()
                if (bpm <= 0) {
                    post {
                        _ui.update { s ->
                            s.copy(
                                connectionMessage = "Пульс: ожидание стабильного сигнала...",
                                debugLine = "heart=0"
                            )
                        }
                    }
                    return
                }
                val v = bpm.toFloat()
                post {
                    _ui.update { s ->
                        val series = (s.pulseSeries + v).takeLast(48)
                        s.copy(
                            pulseBpm = bpm,
                            pulseSeries = series,
                            measuringPulse = true,
                            connectionMessage = "Измерение идет...",
                            debugLine = "heart=$bpm"
                        )
                    }
                }
            }
        }
        val startWriteResponse = object : IBleWriteResponse {
            override fun onResponse(code: Int) {
                Logger.t("TamyrBLE").i("startDetectHeart writeCode=$code")
                post {
                    if (code == Code.REQUEST_SUCCESS) {
                        pulseSdkStartAcked = true
                        _ui.update { s ->
                            s.copy(
                                measuringPulse = true,
                                connectionMessage = "Измерение пульса запущено.",
                                debugLine = "startDetectHeart code=$code"
                            )
                        }
                    } else {
                        pulseSdkStartAcked = false
                        finishPulseSession(
                            "Часы не приняли старт пульса (code=$code).",
                            stopOnDevice = true
                        )
                    }
                }
            }
        }

        fun shouldRetry(currentSeq: Int): Boolean {
            if (currentSeq != pulseStartSeq) return false
            return !pulseSdkStartAcked
        }

        fun scheduleHeartRetry(currentSeq: Int, attempt: Int) {
            if (attempt > 3) {
                finishPulseSession(
                    "Пульс не запускается на ET488. Нажмите Старт еще раз.",
                    stopOnDevice = true
                )
                return
            }
            mainHandler.postDelayed(retryDelay@{
                if (!shouldRetry(currentSeq)) return@retryDelay
                Log.w("TamyrFlow-TamyrBLE", "No heart start callback; retry attempt=$attempt")
                _ui.update { it.copy(connectionMessage = "Повторный запуск пульса ($attempt/3)...") }
                try {
                    VPOperateManager.getInstance().stopDetectHeart(noopWrite)
                    mainHandler.postDelayed(retryStart@{
                        if (!shouldRetry(currentSeq)) return@retryStart
                        try {
                            VPOperateManager.getInstance().startDetectHeart(startWriteResponse, heartListener)
                            scheduleHeartRetry(currentSeq, attempt + 1)
                        } catch (inner: Throwable) {
                            Log.e("TamyrFlow-TamyrBLE", "Heart retry start failed", inner)
                            finishPulseSession(
                                "Ошибка повтора старта пульса: ${inner.localizedMessage ?: "unknown"}",
                                stopOnDevice = true
                            )
                        }
                    }, 350L)
                } catch (retryError: Throwable) {
                    Log.e("TamyrFlow-TamyrBLE", "Heart retry stop failed", retryError)
                    finishPulseSession(
                        "Пульс не запустился. Переподключите часы.",
                        stopOnDevice = true
                    )
                }
            }, 2200L)
        }
        try {
            Log.i("TamyrFlow-TamyrBLE", "VM startPulseMeasure invoking SDK startDetectHeart")
            VPOperateManager.getInstance().stopDetectHeart(noopWrite)
            mainHandler.postDelayed({
                if (seq != pulseStartSeq) return@postDelayed
                try {
                    VPOperateManager.getInstance().startDetectHeart(startWriteResponse, heartListener)
                    scheduleHeartRetry(seq, 1)
                    cancelPulseSessionTimer()
                    val end = Runnable {
                        if (seq != pulseStartSeq) return@Runnable
                        finishPulseSession("Замер завершен (60 сек).", stopOnDevice = true)
                    }
                    pulseSessionEnd = end
                    mainHandler.postDelayed(end, pulseSessionMaxMs)
                } catch (inner: Throwable) {
                    Log.e("TamyrFlow-TamyrBLE", "Initial heart start failed", inner)
                    finishPulseSession(
                        "Ошибка старта пульса: ${inner.localizedMessage ?: "unknown"}",
                        stopOnDevice = true
                    )
                }
            }, 250L)
        } catch (t: Throwable) {
            Log.e("TamyrFlow-TamyrBLE", "VM startPulseMeasure exception", t)
            finishPulseSession(
                "Ошибка старта пульса: ${t.localizedMessage ?: "unknown"}",
                stopOnDevice = true
            )
        }
    }

    fun stopPulseMeasure() {
        finishPulseSession("Замер остановлен.", stopOnDevice = true)
    }

    private fun hasOtherMeasurementRunning(
        allowPulse: Boolean = false,
        allowSpo2: Boolean = false,
        allowTemp: Boolean = false,
        allowBp: Boolean = false,
        allowGlucose: Boolean = false,
        allowEcg: Boolean = false
    ): Boolean {
        val s = _ui.value
        return (s.measuringPulse && !allowPulse) ||
            (s.measuringSpo2 && !allowSpo2) ||
            (s.measuringTemp && !allowTemp) ||
            (s.measuringBp && !allowBp) ||
            (s.measuringGlucose && !allowGlucose) ||
            (s.measuringEcg && !allowEcg)
    }

    private fun finishPulseSession(baseMessage: String, stopOnDevice: Boolean) {
        cancelPulseSessionTimer()
        pulseStartSeq += 1
        if (stopOnDevice) {
            try {
                VPOperateManager.getInstance().stopDetectHeart(writeResponse("stopDetectHeart"))
            } catch (_: Throwable) { }
        }
        val state = _ui.value
        val avg = state.pulseSeries
            .filter { it > 0f }
            .takeIf { it.isNotEmpty() }
            ?.average()
            ?.roundToInt()
        _ui.update {
            it.copy(
                measuringPulse = false,
                pulseAvgBpm = avg,
                connectionMessage = if (avg != null) "$baseMessage Средний пульс: $avg bpm." else baseMessage
            )
        }
    }

    fun startSpo2Measure() {
        if (!_ui.value.handshakeOk) return
        if (hasOtherMeasurementRunning(allowSpo2 = true)) {
            _ui.update { it.copy(connectionMessage = "Сначала остановите другое измерение.") }
            return
        }
        cancelSpo2SessionTimer()
        spo2StartSeq += 1
        val sessionSeq = spo2StartSeq
        spo2SessionSamples.clear()
        _ui.update { it.copy(measuringSpo2 = true, spo2Series = emptyList(), spo2AvgPercent = null) }
        try {
            VPOperateManager.getInstance().startDetectSPO2H(
                writeResponse("startDetectSPO2H"),
                object : ISpo2hDataListener {
                    override fun onSpO2HADataChange(spo2HData: Spo2hData) {
                        if (sessionSeq != spo2StartSeq) return
                        val pct = spo2HData.getValue()
                        if (pct <= 0) return
                        spo2SessionSamples.add(pct)
                        val v = pct.toFloat()
                        post {
                            if (sessionSeq != spo2StartSeq) return@post
                            _ui.update { s ->
                                val series = (s.spo2Series + v).takeLast(48)
                                s.copy(spo2Percent = pct, spo2Series = series, debugLine = "spo2=$pct")
                            }
                        }
                    }
                }
            )
            val end = Runnable {
                if (sessionSeq != spo2StartSeq) return@Runnable
                finishSpo2Session("SpO2 замер завершен (60 сек).", stopOnDevice = true)
            }
            spo2SessionEnd = end
            mainHandler.postDelayed(end, measureSessionMaxMs)
        } catch (t: Throwable) {
            finishSpo2Session(
                "Ошибка старта SpO2: ${t.localizedMessage ?: "unknown"}",
                stopOnDevice = true
            )
        }
    }

    fun stopSpo2Measure() {
        finishSpo2Session("SpO2 замер остановлен.", stopOnDevice = true)
    }

    private fun finishSpo2Session(baseMessage: String, stopOnDevice: Boolean) {
        cancelSpo2SessionTimer()
        spo2StartSeq += 1
        try {
            if (stopOnDevice) {
                VPOperateManager.getInstance().stopDetectSPO2H(
                    writeResponse("stopDetectSPO2H"),
                    object : ISpo2hDataListener {
                        override fun onSpO2HADataChange(spo2HData: Spo2hData) {}
                    }
                )
            }
        } catch (_: Throwable) { }
        val avg = spo2SessionSamples
            .takeIf { it.isNotEmpty() }
            ?.average()
            ?.roundToInt()
        _ui.update {
            it.copy(
                measuringSpo2 = false,
                spo2AvgPercent = avg,
                connectionMessage = if (avg != null) "$baseMessage Средний SpO2: $avg%." else baseMessage
            )
        }
    }

    fun startBpMeasure() {
        if (!_ui.value.handshakeOk) return
        if (hasOtherMeasurementRunning(allowBp = true)) {
            _ui.update { it.copy(connectionMessage = "Сначала остановите другое измерение.") }
            return
        }
        cancelBpSessionTimer()
        bpStartSeq += 1
        val sessionSeq = bpStartSeq
        bpSessionHighSamples.clear()
        bpSessionLowSamples.clear()
        _ui.update {
            it.copy(
                measuringBp = true,
                bpProgress = 0,
                bpAvgHigh = null,
                bpAvgLow = null,
                connectionMessage = "Запуск измерения давления..."
            )
        }
        try {
            VPOperateManager.getInstance().startDetectBP(
                writeResponse("startDetectBP"),
                object : IBPDetectDataListener {
                    override fun onDataChange(bpData: BpData) {
                        if (sessionSeq != bpStartSeq) return
                        val hi = bpData.getHighPressure()
                        val lo = bpData.getLowPressure()
                        if (hi > 0 && lo > 0) {
                            bpSessionHighSamples.add(hi)
                            bpSessionLowSamples.add(lo)
                        }
                        post {
                            if (sessionSeq != bpStartSeq) return@post
                            val p = bpData.getProgress()
                            _ui.update { s ->
                                s.copy(
                                    bpHigh = hi.takeIf { it > 0 } ?: s.bpHigh,
                                    bpLow = lo.takeIf { it > 0 } ?: s.bpLow,
                                    bpProgress = p,
                                    debugLine = "bp=$hi/$lo p=$p",
                                    connectionMessage = if (hi > 0 && lo > 0) {
                                        "Давление измерено."
                                    } else {
                                        "Измерение давления... $p%"
                                    }
                                )
                            }
                            if (sessionSeq != bpStartSeq) return@post
                            if (p >= 100 && _ui.value.measuringBp) {
                                finishBpSession("Замер давления завершен на часах.", stopOnDevice = false)
                            }
                        }
                    }
                },
                EBPDetectModel.DETECT_MODEL_PUBLIC
            )
            val end = Runnable {
                if (sessionSeq != bpStartSeq) return@Runnable
                finishBpSession(
                    "Замер давления: нет сигнала завершения с часов (таймаут).",
                    stopOnDevice = true
                )
            }
            bpSessionEnd = end
            mainHandler.postDelayed(end, measureSessionFallbackMs)
        } catch (t: Throwable) {
            finishBpSession(
                "Ошибка старта давления: ${t.localizedMessage ?: "unknown"}",
                stopOnDevice = true
            )
        }
    }

    fun stopBpMeasure() {
        finishBpSession("Замер давления остановлен.", stopOnDevice = true)
    }

    private fun finishBpSession(baseMessage: String, stopOnDevice: Boolean) {
        cancelBpSessionTimer()
        if (!_ui.value.measuringBp) return
        bpStartSeq += 1
        try {
            if (stopOnDevice) {
                VPOperateManager.getInstance().stopDetectBP(
                    writeResponse("stopDetectBP"),
                    EBPDetectModel.DETECT_MODEL_PUBLIC
                )
            }
        } catch (_: Throwable) { }
        val avgHi = bpSessionHighSamples.takeIf { it.isNotEmpty() }?.average()?.roundToInt()
        val avgLo = bpSessionLowSamples.takeIf { it.isNotEmpty() }?.average()?.roundToInt()
        _ui.update {
            it.copy(
                measuringBp = false,
                bpAvgHigh = avgHi,
                bpAvgLow = avgLo,
                connectionMessage = if (avgHi != null && avgLo != null) {
                    "$baseMessage Среднее давление: $avgHi/$avgLo."
                } else {
                    baseMessage
                }
            )
        }
    }

    fun startGlucoseMeasure() {
        if (!_ui.value.handshakeOk) return
        if (hasOtherMeasurementRunning(allowGlucose = true)) {
            _ui.update { it.copy(connectionMessage = "Сначала остановите другое измерение.") }
            return
        }
        cancelGlucoseSessionTimer()
        glucoseStartSeq += 1
        val sessionSeq = glucoseStartSeq
        glucoseSessionSamples.clear()
        _ui.update {
            it.copy(
                measuringGlucose = true,
                glucoseProgress = 0,
                glucoseAvgMmolL = null,
                connectionMessage = "Запуск измерения сахара..."
            )
        }
        try {
            VPOperateManager.getInstance().startBloodGlucoseDetect(
                writeResponse("startBloodGlucoseDetect"),
                object : AbsBloodGlucoseChangeListener() {
                    override fun onDetectError(opt: Int, status: EBloodGlucoseStatus) {
                        post {
                            if (sessionSeq != glucoseStartSeq) return@post
                            finishGlucoseSession(
                                "Сахар: ошибка измерения ($status).",
                                stopOnDevice = true
                            )
                        }
                    }

                    override fun onBloodGlucoseDetect(
                        progress: Int,
                        bloodGlucose: Float,
                        riskLevel: EBloodGlucoseRiskLevel
                    ) {
                        if (sessionSeq != glucoseStartSeq) return
                        if (bloodGlucose > 0f) glucoseSessionSamples.add(bloodGlucose)
                        post {
                            if (sessionSeq != glucoseStartSeq) return@post
                            _ui.update {
                                it.copy(
                                    glucoseProgress = progress,
                                    glucoseMmolL = bloodGlucose.takeIf { v -> v > 0f } ?: it.glucoseMmolL,
                                    debugLine = "glucose=$bloodGlucose p=$progress",
                                    connectionMessage = if (progress >= 100) {
                                        "Сахар измерен: ${"%.1f".format(bloodGlucose)} mmol/L."
                                    } else {
                                        "Измерение сахара... $progress%"
                                    }
                                )
                            }
                            if (sessionSeq != glucoseStartSeq) return@post
                            if (progress >= 100 && _ui.value.measuringGlucose) {
                                finishGlucoseSession("Сахар: замер завершен на часах.", stopOnDevice = false)
                            }
                        }
                    }

                    override fun onBloodGlucoseStopDetect() {
                        post {
                            if (sessionSeq != glucoseStartSeq) return@post
                            finishGlucoseSession("Сахар: замер завершен.", stopOnDevice = false)
                        }
                    }
                }
            )
            val end = Runnable {
                if (sessionSeq != glucoseStartSeq) return@Runnable
                finishGlucoseSession(
                    "Сахар: нет сигнала завершения с часов (таймаут).",
                    stopOnDevice = true
                )
            }
            glucoseSessionEnd = end
            mainHandler.postDelayed(end, measureSessionFallbackMs)
        } catch (t: Throwable) {
            finishGlucoseSession(
                "Ошибка старта сахара: ${t.localizedMessage ?: "unknown"}",
                stopOnDevice = true
            )
        }
    }

    fun stopGlucoseMeasure() {
        finishGlucoseSession("Сахар: замер остановлен.", stopOnDevice = true)
    }

    private fun finishGlucoseSession(baseMessage: String, stopOnDevice: Boolean) {
        cancelGlucoseSessionTimer()
        if (!_ui.value.measuringGlucose) return
        glucoseStartSeq += 1
        try {
            if (stopOnDevice) {
                VPOperateManager.getInstance().stopBloodGlucoseDetect(
                    writeResponse("stopBloodGlucoseDetect"),
                    object : AbsBloodGlucoseChangeListener() {}
                )
            }
        } catch (_: Throwable) { }
        val avg = glucoseSessionSamples.takeIf { it.isNotEmpty() }?.average()?.toFloat()
        _ui.update {
            it.copy(
                measuringGlucose = false,
                glucoseAvgMmolL = avg,
                connectionMessage = if (avg != null) {
                    "$baseMessage Средний сахар: ${"%.1f".format(avg)} mmol/L."
                } else {
                    baseMessage
                }
            )
        }
    }

    fun startEcgMeasure() {
        if (!_ui.value.handshakeOk) return
        if (hasOtherMeasurementRunning(allowEcg = true)) {
            _ui.update { it.copy(connectionMessage = "Сначала остановите другое измерение.") }
            return
        }
        cancelEcgSessionTimer()
        ecgStartSeq += 1
        val sessionSeq = ecgStartSeq
        ecgSessionToken = sessionSeq
        ecgHeartSamples.clear()
        _ui.update {
            it.copy(
                measuringEcg = true,
                ecgProgress = 0,
                ecgAvgHeart = null,
                ecgWaveform = emptyList(),
                connectionMessage = "Запуск ЭКГ..."
            )
        }
        try {
            VPOperateManager.getInstance().startDetectECG(
                object : BleWriteResponse {
                    override fun onResponse(code: Int) {
                        Logger.t("TamyrBLE").i("startDetectECG writeCode=$code")
                    }
                },
                true,
                ecgDetectListener
            )
            val end = Runnable {
                if (sessionSeq != ecgStartSeq) return@Runnable
                finishEcgSession(
                    "ЭКГ: нет сигнала завершения с часов (таймаут).",
                    stopOnDevice = true
                )
            }
            ecgSessionEnd = end
            mainHandler.postDelayed(end, measureSessionFallbackMs)
        } catch (t: Throwable) {
            finishEcgSession(
                "Ошибка старта ЭКГ: ${t.localizedMessage ?: "unknown"}",
                stopOnDevice = true
            )
        }
    }

    fun stopEcgMeasure() {
        finishEcgSession("ЭКГ замер остановлен.", stopOnDevice = true)
    }

    private fun finishEcgSession(baseMessage: String, stopOnDevice: Boolean) {
        cancelEcgSessionTimer()
        if (!_ui.value.measuringEcg) return
        ecgStartSeq += 1
        try {
            if (stopOnDevice) {
                VPOperateManager.getInstance().stopDetectECG(
                    object : BleWriteResponse {
                        override fun onResponse(code: Int) {
                            Logger.t("TamyrBLE").i("stopDetectECG writeCode=$code")
                        }
                    },
                    true,
                    ecgDetectListener
                )
            }
        } catch (_: Throwable) { }
        val avg = ecgHeartSamples.takeIf { it.isNotEmpty() }?.average()?.roundToInt()
        _ui.update {
            it.copy(
                measuringEcg = false,
                ecgAvgHeart = avg ?: it.ecgAvgHeart,
                connectionMessage = if (avg != null) "$baseMessage Средний пульс ЭКГ: $avg bpm." else baseMessage
            )
        }
    }

    fun startTempMeasure() {
        if (!_ui.value.handshakeOk) return
        if (hasOtherMeasurementRunning(allowTemp = true)) {
            _ui.update { it.copy(connectionMessage = "Сначала остановите другое измерение.") }
            return
        }
        cancelTempSessionTimer()
        tempStartSeq += 1
        val sessionSeq = tempStartSeq
        tempSessionSamples.clear()
        _ui.update { it.copy(measuringTemp = true, tempSeries = emptyList(), bodyTempAvgC = null) }
        try {
            VPOperateManager.getInstance().startDetectTempture(
                writeResponse("startDetectTemp"),
                object : ITemptureDetectDataListener {
                    override fun onDataChange(data: TemptureDetectData) {
                        if (sessionSeq != tempStartSeq) return
                        post {
                            if (sessionSeq != tempStartSeq) return@post
                            _ui.update { s ->
                                val t = data.getTempture()
                                val base = data.getTemptureBase()
                                if (t > 0f) tempSessionSamples.add(t)
                                val series = (s.tempSeries + t).takeLast(48)
                                s.copy(
                                    bodyTempC = t,
                                    skinTempC = base,
                                    tempSeries = series,
                                    debugLine = "temp=$t p=${data.getProgress()} op=0x${data.getOprate().toString(16)}"
                                )
                            }
                            if (sessionSeq != tempStartSeq) return@post
                            // Veepoo SDK: progress is read progress (0–100); when the watch ends the measure, progress reaches 100.
                            if (data.getProgress() >= 100 && _ui.value.measuringTemp) {
                                finishTempSession("Температура: замер завершен на часах.", stopOnDevice = false)
                            }
                        }
                    }
                }
            )
            val end = Runnable {
                if (sessionSeq != tempStartSeq) return@Runnable
                finishTempSession(
                    "Температура: нет сигнала завершения с часов (таймаут).",
                    stopOnDevice = true
                )
            }
            tempSessionEnd = end
            mainHandler.postDelayed(end, tempSessionFallbackMs)
        } catch (t: Throwable) {
            finishTempSession(
                "Ошибка старта температуры: ${t.localizedMessage ?: "unknown"}",
                stopOnDevice = true
            )
        }
    }

    fun stopTempMeasure() {
        finishTempSession("Температура: замер остановлен.", stopOnDevice = true)
    }

    private fun finishTempSession(baseMessage: String, stopOnDevice: Boolean) {
        cancelTempSessionTimer()
        if (!_ui.value.measuringTemp) return
        tempStartSeq += 1
        try {
            if (stopOnDevice) {
                VPOperateManager.getInstance().stopDetectTempture(
                    writeResponse("stopDetectTemp"),
                    object : ITemptureDetectDataListener {
                        override fun onDataChange(data: TemptureDetectData) {}
                    }
                )
            }
        } catch (_: Throwable) { }
        val avg = tempSessionSamples.takeIf { it.isNotEmpty() }?.average()?.toFloat()
        _ui.update {
            it.copy(
                measuringTemp = false,
                bodyTempAvgC = avg,
                connectionMessage = if (avg != null) "$baseMessage Средняя температура: ${"%.1f".format(avg)}°C." else baseMessage
            )
        }
    }

    override fun onCleared() {
        super.onCleared()
        stopPulseMeasure()
        stopSpo2Measure()
        stopTempMeasure()
        stopBpMeasure()
        stopGlucoseMeasure()
        stopEcgMeasure()
        stopScan()
        disconnect()
    }
}
