package com.tamyrflow.tamyrflowapp.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val TamyrDarkScheme = darkColorScheme(
    primary = TamyrTeal,
    onPrimary = Color.Black,
    secondary = TamyrTealDark,
    onSecondary = Color.White,
    tertiary = TamyrSpo2Line,
    background = TamyrBlack,
    onBackground = Color.White,
    surface = TamyrSurface,
    onSurface = Color.White,
    surfaceVariant = TamyrNavPill,
    onSurfaceVariant = TamyrTextSecondary,
    outline = Color(0xFF3A3A3C)
)

@Composable
fun TamyrFlowTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = TamyrDarkScheme,
        content = content
    )
}
