package com.tamyrflow.tamyrflowapp.ui

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.BluetoothSearching
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.tamyrflow.tamyrflowapp.MainTab
import com.tamyrflow.tamyrflowapp.MainUiState
import com.tamyrflow.tamyrflowapp.MainViewModel
import com.tamyrflow.tamyrflowapp.ScannedDeviceUi
import com.tamyrflow.tamyrflowapp.ui.components.DeviceStatusCard
import com.tamyrflow.tamyrflowapp.ui.components.FloatingBottomNavigation
import com.tamyrflow.tamyrflowapp.ui.components.SimpleLineChart
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrBlack
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrHeart
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrSpo2Line
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrTeal
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrTealDark
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrTempBody
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrTempGraph
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrTempSkin
import com.tamyrflow.tamyrflowapp.ui.theme.TamyrTextSecondary
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.PI
import kotlin.math.sin

@Composable
fun TamyrShell(vm: MainViewModel) {
    val ui by vm.ui.collectAsStateWithLifecycle()
    var tab by remember { mutableStateOf(MainTab.Home) }
    var overlay by remember { mutableStateOf<OverlayRoute?>(null) }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { vm.refreshBluetoothFlag() }

    val enableBluetoothLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        vm.refreshBluetoothFlag()
        if (ui.bluetoothOn) vm.startScan()
    }

    LaunchedEffect(Unit) {
        val permissions = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add(Manifest.permission.BLUETOOTH_SCAN)
                add(Manifest.permission.BLUETOOTH_CONNECT)
            } else {
                add(Manifest.permission.ACCESS_FINE_LOCATION)
                add(Manifest.permission.ACCESS_COARSE_LOCATION)
            }
        }.toTypedArray()
        permissionLauncher.launch(permissions)
    }

    fun scanClick() {
        if (ui.bluetoothOn) {
            vm.startScan()
        } else {
            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            enableBluetoothLauncher.launch(intent)
        }
    }

    Scaffold(
        containerColor = TamyrBlack,
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            FloatingBottomNavigation(
                selected = if (overlay != null) MainTab.More else tab,
                onSelect = {
                    overlay = null
                    tab = it
                }
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(TamyrBlack)
                .padding(padding)
                .statusBarsPadding()
        ) {
            when (overlay) {
                OverlayRoute.Temperature -> TemperatureRoute(vm, ui) { overlay = null }
                OverlayRoute.BloodPressure -> BloodPressureRoute(vm, ui) { overlay = null }
                OverlayRoute.Ecg -> EcgRoute(vm, ui) { overlay = null }
                OverlayRoute.Settings -> SettingsRoute(ui) { overlay = null }
                null -> when (tab) {
                    MainTab.Search -> SearchRoute(vm, ui, ::scanClick)
                    MainTab.Home -> HomeRoute(
                        vm = vm,
                        ui = ui,
                        onOpenTab = { tab = it },
                        onOpenHealthOverlay = { overlay = it },
                        onConnectWatch = {
                            tab = MainTab.Search
                            if (ui.bluetoothOn) vm.startScan()
                        }
                    )
                    MainTab.Pulse -> PulseRoute(vm, ui)
                    MainTab.SpO2 -> Spo2Route(vm, ui)
                    MainTab.More -> MoreRoute(ui) { overlay = it }
                }
            }

            if (!ui.bluetoothOn) {
                BluetoothWarningBanner(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .navigationBarsPadding()
                        .padding(bottom = 88.dp)
                )
            }

            val measureOverlay = when {
                ui.measuringPulse -> Icons.Default.Favorite to "Измерение пульса"
                ui.measuringSpo2 -> Icons.Default.Air to "Измерение кислорода"
                ui.measuringTemp -> Icons.Default.Thermostat to "Измерение температуры"
                ui.measuringBp -> Icons.Default.LocalHospital to "Измерение давления"
                ui.measuringGlucose -> Icons.Default.LocalHospital to "Измерение глюкозы"
                ui.measuringEcg -> Icons.Default.Favorite to "ЭКГ"
                else -> null
            }
            measureOverlay?.let { (icon, title) ->
                MeasuringOverlay(title = title, icon = icon)
            }
        }
    }
}

private enum class OverlayRoute { Temperature, BloodPressure, Ecg, Settings }

@Composable
private fun SearchRoute(vm: MainViewModel, ui: MainUiState, onScan: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
            // Keep manual measurement buttons above floating bottom navigation.
            .padding(bottom = 100.dp)
    ) {
        DeviceStatusCard(
            deviceName = ui.connectedName ?: "Нет часов",
            bluetoothOn = ui.bluetoothOn,
            verified = ui.handshakeOk
        )
        Spacer(Modifier.height(14.dp))
        TitleText("Поиск")
        Spacer(Modifier.height(10.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
            StatusMiniCard(Modifier.weight(1f), "Bluetooth", if (ui.bluetoothOn) "Вкл" else "Выкл", ui.bluetoothOn)
            StatusMiniCard(Modifier.weight(1f), "SDK", "Готов", true)
        }
        Spacer(Modifier.height(10.dp))

        Surface(shape = RoundedCornerShape(24.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("Подключение", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                Text(ui.connectionMessage, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 16.sp)
            }
        }
        Spacer(Modifier.height(12.dp))

        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            GradientPill("Сканировать", onScan, true, Modifier.weight(1f))
            GrayPill("Стоп", { vm.stopScan() }, ui.scanning, Modifier.weight(1f))
        }
        Spacer(Modifier.height(10.dp))
        if (ui.scanning) {
            Spacer(Modifier.height(12.dp))
            ScanningCard()
        }

        Spacer(Modifier.height(12.dp))
        if (ui.devices.isEmpty()) {
            Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
                Column(Modifier.padding(16.dp)) {
                    Text("Устройства", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 20.sp)
                    Text("Пока нет устройств", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            ui.devices.forEach { d ->
                DeviceRow(d, vm, ui)
                Spacer(Modifier.height(10.dp))
            }
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun HomeRoute(
    vm: MainViewModel,
    ui: MainUiState,
    onOpenTab: (MainTab) -> Unit,
    onOpenHealthOverlay: (OverlayRoute) -> Unit,
    onConnectWatch: () -> Unit
) {
    LaunchedEffect(ui.handshakeOk) {
        if (ui.handshakeOk) vm.syncDailyMetrics()
    }

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
            .padding(bottom = 100.dp)
    ) {
        TitleText("Главная")
        Spacer(Modifier.height(6.dp))
        Text(
            text = if (ui.handshakeOk) "Сегодня • ${ui.connectedName ?: "Часы"}" else "Подключите часы, чтобы подтянуть шаги и пульс",
            color = TamyrTextSecondary,
            fontSize = 14.sp
        )
        Spacer(Modifier.height(18.dp))

        StepsHeroSection(
            steps = ui.stepsToday,
            goal = ui.stepsGoal,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(Modifier.height(20.dp))
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            HomeStatColumn(
                label = "Расстояние",
                value = "${ui.distanceMetersToday}",
                unit = "м",
                modifier = Modifier.weight(1f)
            )
            HomeStatColumn(
                label = "Калории",
                value = if (ui.caloriesKcalToday > 0f) String.format(Locale.US, "%.0f", ui.caloriesKcalToday) else "—",
                unit = "ккал",
                modifier = Modifier.weight(1f)
            )
            HomeStatColumn(
                label = "Пульс",
                value = ui.pulseBpm?.toString() ?: "—",
                unit = "уд/мин",
                modifier = Modifier.weight(1f)
            )
            HomeStatColumn(
                label = "SpO₂",
                value = ui.spo2Percent?.toString() ?: "—",
                unit = "%",
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(Modifier.height(10.dp))
        GrayPill("Обновить данные", vm::syncDailyMetrics, ui.handshakeOk, Modifier.fillMaxWidth())

        Spacer(Modifier.height(22.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Здоровье", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 26.sp)
            Text(
                "Перейти к метрике",
                color = TamyrTeal,
                fontSize = 15.sp,
                modifier = Modifier.clickable { onOpenTab(MainTab.Pulse) }
            )
        }
        Spacer(Modifier.height(10.dp))

        val tiles = listOf(
            Triple("Пульс", Icons.Default.Favorite) { onOpenTab(MainTab.Pulse) },
            Triple("SpO2", Icons.Default.Air) { onOpenTab(MainTab.SpO2) },
            Triple("Темп.", Icons.Default.Thermostat) { onOpenHealthOverlay(OverlayRoute.Temperature) },
            Triple("ЭКГ", Icons.Default.Favorite) { onOpenHealthOverlay(OverlayRoute.Ecg) },
            Triple("Давление и сахар", Icons.Default.LocalHospital) { onOpenHealthOverlay(OverlayRoute.BloodPressure) }
        )
        tiles.chunked(2).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { (title, icon, onClick) ->
                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .height(108.dp)
                            .clickable { onClick() },
                        shape = RoundedCornerShape(20.dp),
                        color = MaterialTheme.colorScheme.surface
                    ) {
                        Column(Modifier.padding(14.dp)) {
                            Icon(icon, null, tint = TamyrTeal, modifier = Modifier.size(26.dp))
                            Spacer(Modifier.height(8.dp))
                            Text(title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                        }
                    }
                }
            }
            Spacer(Modifier.height(10.dp))
        }

        Spacer(Modifier.height(20.dp))
        GradientPill(
            text = if (ui.handshakeOk) "Подключение и поиск" else "Подключить часы",
            onClick = onConnectWatch,
            enabled = true,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun StepsHeroSection(steps: Int, goal: Int, modifier: Modifier = Modifier) {
    val fmt = remember { NumberFormat.getNumberInstance(Locale.forLanguageTag("ru-RU")) }
    val goalSafe = goal.coerceAtLeast(1)
    val progress = (steps.toFloat() / goalSafe.toFloat()).coerceIn(0f, 1f)
    val sweep = 360f * progress
    val inf = rememberInfiniteTransition(label = "stepsAura")
    val phase by inf.animateFloat(
        initialValue = 0f,
        targetValue = (2.0 * PI).toFloat(),
        animationSpec = infiniteRepeatable(animation = tween(7000, easing = LinearEasing)),
        label = "auraPhase"
    )
    Box(modifier.height(300.dp).fillMaxWidth(), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val cx = size.width / 2f
            val cy = size.height / 2f
            val baseR = size.minDimension * 0.42f
            val n = 96
            for (i in 0 until n) {
                val t = i / n.toFloat()
                val ang = (t * 2f * PI + phase).toFloat()
                val pulseH = baseR * (0.22f + 0.18f * sin(t * 12f * PI.toFloat() + phase * 0.9f))
                val ox = sin(ang) * baseR * 0.35f
                val x = cx + ox
                val alpha = (0.06f + 0.14f * ((sin(i * 0.31f + phase) + 1f) / 2f)).coerceIn(0.04f, 0.22f)
                val cTop = TamyrTeal.copy(alpha = alpha)
                val cBot = TamyrTealDark.copy(alpha = alpha * 0.6f)
                drawLine(
                    brush = Brush.verticalGradient(listOf(cTop, cBot)),
                    start = Offset(x, cy - pulseH),
                    end = Offset(x, cy + pulseH),
                    strokeWidth = 2.2f
                )
            }
            for (ring in 0 until 3) {
                val r = baseR * (0.55f + ring * 0.12f)
                val a = (0.035f - ring * 0.008f).coerceAtLeast(0.012f)
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(TamyrTeal.copy(alpha = a), Color.Transparent),
                        center = Offset(cx, cy),
                        radius = r
                    ),
                    radius = r,
                    center = Offset(cx, cy)
                )
            }
        }

        Box(Modifier.size(228.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                val stroke = 17.dp.toPx()
                val side = size.minDimension - stroke
                val topLeft = Offset((size.width - side) / 2f, (size.height - side) / 2f)
                val arcSize = Size(side, side)
                drawArc(
                    color = Color.White.copy(alpha = 0.09f),
                    startAngle = -90f,
                    sweepAngle = 360f,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = stroke, cap = StrokeCap.Round)
                )
                if (sweep > 0.5f) {
                    drawArc(
                        brush = Brush.sweepGradient(
                            colors = listOf(TamyrTealDark, TamyrTeal, TamyrHeart, TamyrTeal),
                            center = Offset(size.width / 2f, size.height / 2f)
                        ),
                        startAngle = -90f,
                        sweepAngle = sweep,
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = stroke, cap = StrokeCap.Round)
                    )
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Цель дня", color = TamyrTextSecondary, fontSize = 13.sp)
                Text(
                    fmt.format(steps.toLong()),
                    color = Color.White,
                    fontSize = 40.sp,
                    fontWeight = FontWeight.Bold
                )
                Text("шагов", color = Color.White.copy(alpha = 0.92f), fontSize = 16.sp)
                Text(
                    "${fmt.format(goalSafe.toLong())} цель • ${(progress * 100f).toInt()}%",
                    color = TamyrTextSecondary,
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
private fun HomeStatColumn(label: String, value: String, unit: String, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, color = TamyrTextSecondary, fontSize = 12.sp)
        Spacer(Modifier.height(4.dp))
        Text(value, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Text(unit, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
    }
}

@Composable
private fun PulseRoute(vm: MainViewModel, ui: MainUiState) {
    MetricRoute(
        title = "Пульс",
        valueText = "${ui.pulseBpm ?: 0} bpm",
        subtitle = if (ui.pulseAvgBpm != null && !ui.measuringPulse) {
            "Средний за замер: ${ui.pulseAvgBpm} bpm"
        } else {
            "Текущий пульс"
        },
        graphLabel = "Уд/мин по времени",
        lineColor = TamyrHeart,
        values = ui.pulseSeries,
        connected = ui.handshakeOk,
        measuring = ui.measuringPulse,
        onStart = vm::startPulseMeasure,
        onStop = vm::stopPulseMeasure,
        ui = ui
    )
}

@Composable
private fun Spo2Route(vm: MainViewModel, ui: MainUiState) {
    MetricRoute(
        title = "Кислород в крови",
        valueText = "${ui.spo2Percent ?: 0}%",
        subtitle = if (ui.spo2AvgPercent != null && !ui.measuringSpo2) {
            "Средний за замер: ${ui.spo2AvgPercent}%"
        } else {
            "SpO2"
        },
        graphLabel = "Кислород %",
        lineColor = TamyrSpo2Line,
        values = ui.spo2Series,
        connected = ui.handshakeOk,
        measuring = ui.measuringSpo2,
        onStart = vm::startSpo2Measure,
        onStop = vm::stopSpo2Measure,
        ui = ui
    )
}

@Composable
private fun MetricRoute(
    title: String,
    valueText: String,
    subtitle: String,
    graphLabel: String,
    lineColor: Color,
    values: List<Float>,
    connected: Boolean,
    measuring: Boolean,
    onStart: () -> Unit,
    onStop: () -> Unit,
    ui: MainUiState
) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        DeviceStatusCard(
            deviceName = ui.connectedName ?: "Нет часов",
            bluetoothOn = ui.bluetoothOn,
            verified = connected
        )
        Spacer(Modifier.height(14.dp))
        TitleText(title)
        Spacer(Modifier.height(10.dp))

        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(valueText, color = lineColor, fontSize = 38.sp, fontWeight = FontWeight.Bold)
                Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        Spacer(Modifier.height(10.dp))
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("График", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Text(if (values.isEmpty()) "Ожидание" else "Измерение", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(6.dp))
                Text(graphLabel, color = MaterialTheme.colorScheme.onSurfaceVariant, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(10.dp))
                if (values.isEmpty()) {
                    Text(
                        "Запустите измерение, чтобы увидеть график",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(vertical = 44.dp)
                    )
                } else {
                    val min = values.minOrNull()?.minus(3f) ?: 0f
                    val max = values.maxOrNull()?.plus(3f) ?: 100f
                    SimpleLineChart(values, lineColor, lineColor, minY = min, maxY = max)
                }
            }
        }

        Spacer(Modifier.height(10.dp))
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("Ручной замер", color = Color.White, fontWeight = FontWeight.Bold)
                Text("По окончании нажмите Стоп", color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (!connected) {
                    Spacer(Modifier.height(6.dp))
                    Text("Сначала подключите часы на вкладке Поиск", color = Color(0xFFFFC857), fontSize = 13.sp)
                }
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    GradientPill(
                        "Старт",
                        {
                            Log.i("TamyrFlow-TamyrBLE", "UI start tapped title=$title connected=$connected measuring=$measuring")
                            onStart()
                        },
                        connected && !measuring,
                        Modifier.weight(1f)
                    )
                    GrayPill("Стоп", onStop, measuring, Modifier.weight(1f))
                }
            }
        }

        Spacer(Modifier.height(140.dp))
    }
}

@Composable
private fun MoreRoute(ui: MainUiState, onOpenOverlay: (OverlayRoute) -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        DeviceStatusCard(
            deviceName = ui.connectedName ?: "Нет часов",
            bluetoothOn = ui.bluetoothOn,
            verified = ui.handshakeOk
        )
        Spacer(Modifier.height(14.dp))
        TitleText("Еще")
        Spacer(Modifier.height(8.dp))

        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column {
                MoreRow(Icons.Default.Thermostat, "Темп.") { onOpenOverlay(OverlayRoute.Temperature) }
                HorizontalDivider(color = Color(0x22FFFFFF))
                MoreRow(Icons.Default.LocalHospital, "Давление / сахар") { onOpenOverlay(OverlayRoute.BloodPressure) }
                HorizontalDivider(color = Color(0x22FFFFFF))
                MoreRow(Icons.Default.Favorite, "ЭКГ") { onOpenOverlay(OverlayRoute.Ecg) }
                HorizontalDivider(color = Color(0x22FFFFFF))
                MoreRow(Icons.Default.Settings, "Настройки") { onOpenOverlay(OverlayRoute.Settings) }
            }
        }

        Spacer(Modifier.height(140.dp))
    }
}

@Composable
private fun TemperatureRoute(vm: MainViewModel, ui: MainUiState, onBack: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Text("‹ Назад", color = TamyrTeal, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable { onBack() })
        Spacer(Modifier.height(8.dp))
        DeviceStatusCard(deviceName = ui.connectedName ?: "Нет часов", bluetoothOn = ui.bluetoothOn, verified = ui.handshakeOk)
        Spacer(Modifier.height(14.dp))
        TitleText("Температура")
        Spacer(Modifier.height(10.dp))

        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Row(Modifier.fillMaxWidth().padding(16.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text(ui.bodyTempC?.let { String.format("%.1f°C", it) } ?: "—", color = TamyrTempBody, fontWeight = FontWeight.Bold, fontSize = 34.sp)
                    Text("Тело", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        ui.bodyTempAvgC?.let { "Средняя: ${String.format("%.1f°C", it)}" } ?: "Средняя: —",
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(ui.skinTempC?.let { String.format("%.1f°C", it) } ?: "—", color = TamyrTempSkin, fontWeight = FontWeight.Bold, fontSize = 34.sp)
                    Text("Кожа", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }

        Spacer(Modifier.height(10.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("Динамика температуры", color = Color.White, fontWeight = FontWeight.Bold)
                Text("Прогресс 100%", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(8.dp))
                if (ui.tempSeries.isEmpty()) {
                    Spacer(Modifier.height(140.dp))
                } else {
                    val min = ui.tempSeries.minOrNull()?.minus(0.5f) ?: 35f
                    val max = ui.tempSeries.maxOrNull()?.plus(0.5f) ?: 39f
                    SimpleLineChart(ui.tempSeries, TamyrTempGraph, TamyrTempGraph, minY = min, maxY = max)
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("Ручной замер", color = Color.White, fontWeight = FontWeight.Bold)
                Text("Носите устройство плотнее", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    GradientPill("Старт", vm::startTempMeasure, ui.handshakeOk && !ui.measuringTemp, Modifier.weight(1f))
                    GrayPill("Стоп", vm::stopTempMeasure, ui.measuringTemp, Modifier.weight(1f))
                }
            }
        }
        Spacer(Modifier.height(140.dp))
    }
}

@Composable
private fun BloodPressureRoute(vm: MainViewModel, ui: MainUiState, onBack: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Text("‹ Назад", color = TamyrTeal, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable { onBack() })
        Spacer(Modifier.height(8.dp))
        DeviceStatusCard(deviceName = ui.connectedName ?: "Нет часов", bluetoothOn = ui.bluetoothOn, verified = ui.handshakeOk)
        Spacer(Modifier.height(14.dp))
        TitleText("Давление и глюкоза")
        Spacer(Modifier.height(10.dp))
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("Кровяное давление", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text("Ручное измерение с браслета", color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (!ui.handshakeOk) {
                    Spacer(Modifier.height(4.dp))
                    Text("Подключите часы для запуска измерения", color = Color(0xFFFFC857), fontSize = 13.sp)
                }
                Spacer(Modifier.height(8.dp))
                Text("Последнее значение", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    if (ui.bpHigh != null && ui.bpLow != null) "${ui.bpHigh}/${ui.bpLow}" else "—",
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 28.sp
                )
                Text(
                    if (ui.bpAvgHigh != null && ui.bpAvgLow != null) "Среднее: ${ui.bpAvgHigh}/${ui.bpAvgLow}" else "Среднее: —",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text("Прогресс: ${ui.bpProgress}%", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(10.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    GradientPill("Старт", vm::startBpMeasure, ui.handshakeOk && !ui.measuringBp, Modifier.weight(1f))
                    GrayPill("Стоп", vm::stopBpMeasure, ui.measuringBp, Modifier.weight(1f))
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("Сахар в крови", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text("По правилам калибровки устройства", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(8.dp))
                Text("Последнее значение", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    ui.glucoseMmolL?.let { String.format("%.1f mmol/L", it) } ?: "—",
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 28.sp
                )
                Text(
                    ui.glucoseAvgMmolL?.let { "Среднее: ${String.format("%.1f mmol/L", it)}" } ?: "Среднее: —",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text("Прогресс: ${ui.glucoseProgress}%", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(10.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    GradientPill("Старт", vm::startGlucoseMeasure, ui.handshakeOk && !ui.measuringGlucose, Modifier.weight(1f))
                    GrayPill("Стоп", vm::stopGlucoseMeasure, ui.measuringGlucose, Modifier.weight(1f))
                }
            }
        }
        Spacer(Modifier.height(140.dp))
    }
}

@Composable
private fun EcgRoute(vm: MainViewModel, ui: MainUiState, onBack: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Text("‹ Назад", color = TamyrTeal, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable { onBack() })
        Spacer(Modifier.height(8.dp))
        DeviceStatusCard(deviceName = ui.connectedName ?: "Нет часов", bluetoothOn = ui.bluetoothOn, verified = ui.handshakeOk)
        Spacer(Modifier.height(14.dp))
        TitleText("ЭКГ")
        Spacer(Modifier.height(10.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("ЭКГ", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text("Ручной замер до 60 секунд", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(12.dp))
                Text("Прогресс ${ui.ecgProgress}%", color = TamyrTeal, fontWeight = FontWeight.Bold, fontSize = 28.sp)
                Text(
                    ui.ecgAvgHeart?.let { "Средний пульс по ЭКГ: $it bpm" } ?: "Средний пульс: —",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(10.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    GradientPill("Старт", vm::startEcgMeasure, ui.handshakeOk && !ui.measuringEcg, Modifier.weight(1f))
                    GrayPill("Стоп", vm::stopEcgMeasure, ui.measuringEcg, Modifier.weight(1f))
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("Кривая записи", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text(
                    if (ui.ecgWaveform.isEmpty()) "Запустите замер — кривая появится в реальном времени."
                    else "Точки: ${ui.ecgWaveform.size}",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 13.sp
                )
                Spacer(Modifier.height(12.dp))
                if (ui.ecgWaveform.isEmpty()) {
                    Spacer(Modifier.height(140.dp))
                } else {
                    val vals = ui.ecgWaveform
                    val minV = vals.minOrNull() ?: 0f
                    val maxV = vals.maxOrNull() ?: 1f
                    val pad = (maxV - minV).coerceAtLeast(1f) * 0.12f
                    SimpleLineChart(
                        values = vals,
                        lineColor = TamyrTeal,
                        fillColor = TamyrTeal.copy(alpha = 0.35f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp),
                        minY = minV - pad,
                        maxY = maxV + pad
                    )
                }
            }
        }
        Spacer(Modifier.height(140.dp))
    }
}

@Composable
private fun SettingsRoute(ui: MainUiState, onBack: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        Text("‹ Назад", color = TamyrTeal, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable { onBack() })
        Spacer(Modifier.height(8.dp))
        DeviceStatusCard(deviceName = ui.connectedName ?: "Нет часов", bluetoothOn = ui.bluetoothOn, verified = ui.handshakeOk)
        Spacer(Modifier.height(14.dp))
        TitleText("Настройки")
        Spacer(Modifier.height(10.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("Профиль", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text("Рост 175 • Вес 70 • Возраст 30", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(10.dp))
                GradientPill("Синхронизировать профиль", {}, ui.handshakeOk, Modifier.fillMaxWidth())
            }
        }
        Spacer(Modifier.height(10.dp))
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
            Column(Modifier.padding(16.dp)) {
                Text("Данные за сегодня", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text("Шаги: ${ui.stepsToday}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Сон: ${ui.sleepMinutesToday} мин", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Spacer(Modifier.height(140.dp))
    }
}

@Composable
private fun TitleText(text: String) {
    Text(
        text = text,
        color = Color.White,
        fontSize = 34.sp,
        lineHeight = 36.sp,
        fontWeight = FontWeight.ExtraBold
    )
}

@Composable
private fun StatusMiniCard(modifier: Modifier, title: String, value: String, ok: Boolean) {
    Surface(modifier = modifier.height(84.dp), shape = RoundedCornerShape(20.dp), color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.SpaceBetween) {
            Text(title, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier
                        .size(9.dp)
                        .clip(RoundedCornerShape(5.dp))
                        .background(if (ok) TamyrTeal else Color(0xFFD45C65))
                )
                Spacer(Modifier.width(8.dp))
                Text(value, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            }
        }
    }
}

@Composable
private fun DeviceRow(device: ScannedDeviceUi, vm: MainViewModel, ui: MainUiState) {
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(16.dp)) {
            Text(device.name, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 24.sp)
            Text(device.address, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
            Text("${device.rssi} dBm", color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                GradientPill("Подключить", { vm.connect(device) }, ui.bluetoothOn, Modifier.weight(1f))
                GrayPill("Отключить", vm::disconnect, ui.connectedAddress != null, Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun ScanningCard() {
    val pulse = rememberInfiniteTransition(label = "scan")
    val p by pulse.animateFloat(0f, 1f, infiniteRepeatable(tween(1800, easing = LinearEasing), RepeatMode.Restart), label = "p")

    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(contentAlignment = Alignment.Center, modifier = Modifier.size(110.dp)) {
                repeat(3) { idx ->
                    val alpha = (1f - ((p + idx * 0.28f) % 1f)).coerceIn(0f, 1f)
                    Canvas(Modifier.size((50 + idx * 18).dp)) {
                        drawCircle(TamyrTeal.copy(alpha = alpha * 0.45f), style = androidx.compose.ui.graphics.drawscope.Stroke(2.6f))
                    }
                }
                Icon(Icons.Default.BluetoothSearching, null, tint = TamyrTeal, modifier = Modifier.size(40.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column {
                Text("Идёт поиск…", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 32.sp)
                Text(
                    "Разбудите браслет и держите его рядом — устройства появятся ниже.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    lineHeight = 21.sp
                )
            }
        }
    }
}

@Composable
private fun MeasuringOverlay(title: String, icon: ImageVector) {
    val t = rememberInfiniteTransition(label = "measure")
    val progress by t.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(2300, easing = LinearEasing), RepeatMode.Restart),
        label = "progress"
    )
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.62f)),
        contentAlignment = Alignment.Center
    ) {
        Surface(shape = RoundedCornerShape(28.dp), color = Color(0xDD1C1C1E), modifier = Modifier.padding(22.dp)) {
            Column(Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    icon,
                    null,
                    tint = Color.White,
                    modifier = Modifier.size(54.dp)
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    title,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 32.sp
                )
                Text(
                    "Не двигайтесь — идёт приём данных с браслета.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 15.sp
                )
                Spacer(Modifier.height(12.dp))
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(Color(0xFF3A3A3C))
                ) {
                    Box(
                        Modifier
                            .fillMaxWidth(progress)
                            .height(8.dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(Brush.horizontalGradient(listOf(TamyrTeal, TamyrSpo2Line)))
                    )
                }
            }
        }
    }
}

@Composable
private fun BluetoothWarningBanner(modifier: Modifier = Modifier) {
    Surface(modifier = modifier.padding(horizontal = 16.dp), color = Color(0xAA6E2430), shape = RoundedCornerShape(16.dp)) {
        Row(Modifier.padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Error, null, tint = Color(0xFFFFD166))
            Spacer(Modifier.width(8.dp))
            Text(
                "Bluetooth выключен. Включите в Пункте управления или Настройках.",
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                lineHeight = 18.sp
            )
        }
    }
}

@Composable
private fun MoreRow(icon: ImageVector, title: String, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, tint = TamyrTeal, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(12.dp))
        Text(title, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun GradientPill(text: String, onClick: () -> Unit, enabled: Boolean, modifier: Modifier = Modifier) {
    val brush = Brush.horizontalGradient(listOf(TamyrTeal, Color(0xFF5DE4E6)))
    Box(
        Modifier
            .then(modifier)
            .height(56.dp)
            .clip(RoundedCornerShape(17.dp))
            .background(
                if (enabled) brush
                else Brush.horizontalGradient(listOf(Color(0xFF3A3A3C), Color(0xFF454548)))
            )
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = if (enabled) Color.Black else Color(0xFFC9C9C9), fontWeight = FontWeight.Bold, fontSize = 18.sp)
    }
}

@Composable
private fun GrayPill(text: String, onClick: () -> Unit, enabled: Boolean, modifier: Modifier = Modifier) {
    Box(
        Modifier
            .then(modifier)
            .height(56.dp)
            .clip(RoundedCornerShape(17.dp))
            .background(if (enabled) Color(0xFF2D2D2F) else Color(0xFF3A3A3C))
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = if (enabled) Color.White else Color(0xFF9A9A9A), fontWeight = FontWeight.Bold, fontSize = 18.sp)
    }
}
