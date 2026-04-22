package com.tamyrflow.tamyrflowapp.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun SimpleLineChart(
    values: List<Float>,
    lineColor: Color,
    fillColor: Color,
    modifier: Modifier = Modifier,
    minY: Float,
    maxY: Float
) {
    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(160.dp)
    ) {
        if (values.isEmpty()) return@Canvas
        val w = size.width
        val h = size.height
        val pad = 8f
        val range = (maxY - minY).coerceAtLeast(1f)
        fun xAt(i: Int): Float {
            if (values.size == 1) return w / 2f
            return pad + (w - 2 * pad) * i / (values.size - 1).toFloat()
        }
        fun yAt(v: Float): Float {
            val t = ((v - minY) / range).coerceIn(0f, 1f)
            return h - pad - (h - 2 * pad) * t
        }
        val path = Path()
        values.forEachIndexed { i, v ->
            val x = xAt(i)
            val y = yAt(v)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        val fillPath = Path().apply {
            addPath(path)
            lineTo(xAt(values.lastIndex), h)
            lineTo(xAt(0), h)
            close()
        }
        drawPath(
            path = fillPath,
            brush = Brush.verticalGradient(
                colors = listOf(fillColor.copy(alpha = 0.45f), Color.Transparent),
                startY = 0f,
                endY = h
            )
        )
        drawPath(
            path = path,
            color = lineColor,
            style = Stroke(width = 3f, cap = StrokeCap.Round)
        )
    }
}
