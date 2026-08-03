package com.example.legestic

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import org.maplibre.android.MapLibre

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Required before any MapView (Neshan MapLibre SDK).
        MapLibre.getInstance(this)
        MapLibre.setApiKey(BuildConfig.NESHAN_MAP_KEY)
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NeshanServicesPlugin())
        flutterEngine.plugins.add(NeshanMapPlugin())
    }
}
