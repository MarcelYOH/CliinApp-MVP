package com.example.cliinapp

import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
