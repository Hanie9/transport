package com.example.legestic

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path

/// Classic location pin. Tip sits at the vertical center so MapLibre's
/// center-anchored markers place the tip on the LatLng.
internal object LocationPinBitmap {
    private const val WIDTH_PX = 84
    private const val HEIGHT_PX = 120

    fun create(colorArgb: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(WIDTH_PX, HEIGHT_PX, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val w = WIDTH_PX.toFloat()
        val h = HEIGHT_PX.toFloat()
        val cx = w / 2f
        // Tip at vertical center → aligns with map coordinate.
        val tipY = h * 0.50f
        val ballR = w * 0.30f
        val ballCy = tipY - ballR * 1.55f

        canvas.drawOval(
            cx - w * 0.16f,
            tipY - 2f,
            cx + w * 0.16f,
            tipY + 8f,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x40000000 },
        )

        val pin = Path().apply {
            moveTo(cx, tipY)
            cubicTo(
                cx + ballR * 1.15f, ballCy + ballR * 0.85f,
                cx + ballR, ballCy - ballR * 0.15f,
                cx, ballCy - ballR,
            )
            cubicTo(
                cx - ballR, ballCy - ballR * 0.15f,
                cx - ballR * 1.15f, ballCy + ballR * 0.85f,
                cx, tipY,
            )
            close()
        }

        canvas.drawPath(
            pin,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colorArgb
                style = Paint.Style.FILL
            },
        )
        canvas.drawPath(
            pin,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFFFFFFF.toInt()
                style = Paint.Style.STROKE
                strokeWidth = 4f
            },
        )
        canvas.drawCircle(
            cx,
            ballCy,
            ballR * 0.38f,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFFFFFFF.toInt()
                style = Paint.Style.FILL
            },
        )
        return bitmap
    }
}
