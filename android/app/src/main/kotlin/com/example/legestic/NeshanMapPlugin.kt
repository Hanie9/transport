package com.example.legestic

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.maplibre.android.annotations.IconFactory
import org.maplibre.android.annotations.Marker
import org.maplibre.android.annotations.MarkerOptions
import org.maplibre.android.annotations.Polyline
import org.maplibre.android.annotations.PolylineOptions
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style
import java.util.concurrent.ConcurrentHashMap

/// Neshan MapLibre MapView platform view
/// Docs: https://platform.neshan.org/docs/sdk/android/installation/
class NeshanMapPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.legestic/neshan_map")
        channel.setMethodCallHandler(this)

        EventChannel(binding.binaryMessenger, "com.example.legestic/neshan_map_events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NeshanMapRegistry.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    NeshanMapRegistry.eventSink = null
                }
            })

        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            NeshanMapViewFactory(),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        NeshanMapRegistry.clear()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val viewId = call.argument<Int>("viewId") ?: run {
            result.error("invalid_argument", "viewId is required", null)
            return
        }
        val mapView = NeshanMapRegistry.get(viewId) ?: run {
            result.error("not_found", "Map view $viewId not found", null)
            return
        }

        when (call.method) {
            "moveCamera" -> {
                val lat = call.argument<Double>("lat") ?: 0.0
                val lng = call.argument<Double>("lng") ?: 0.0
                val zoom = call.argument<Double>("zoom") ?: 14.0
                val bearing = call.argument<Double>("bearing")
                val navigation = call.argument<Boolean>("navigation") ?: false
                val tilt = call.argument<Double>("tilt")
                mapView.moveCamera(
                    LatLng(lat, lng),
                    zoom,
                    bearing,
                    navigation,
                    tilt,
                )
                result.success(null)
            }
            "beginNavigationCamera" -> {
                val lat = call.argument<Double>("lat") ?: 0.0
                val lng = call.argument<Double>("lng") ?: 0.0
                val bearing = call.argument<Double>("bearing") ?: 0.0
                mapView.beginNavigationCamera(LatLng(lat, lng), bearing.toFloat())
                result.success(null)
            }
            "updateNavigationCamera" -> {
                val lat = call.argument<Double>("lat") ?: 0.0
                val lng = call.argument<Double>("lng") ?: 0.0
                val bearing = call.argument<Double>("bearing") ?: 0.0
                mapView.updateNavigationCamera(LatLng(lat, lng), bearing.toFloat())
                result.success(null)
            }
            "setNavigationFollow" -> {
                mapView.setNavigationFollowEnabled(call.argument<Boolean>("enabled") ?: false)
                result.success(null)
            }
            "setOverviewGestures" -> {
                mapView.setOverviewGesturesEnabled(call.argument<Boolean>("enabled") ?: false)
                result.success(null)
            }
            "fitBounds" -> {
                @Suppress("UNCHECKED_CAST")
                val raw = call.argument<List<Map<String, Double>>>("points") ?: emptyList()
                val points = raw.mapNotNull { p ->
                    val la = p["lat"] ?: return@mapNotNull null
                    val ln = p["lng"] ?: return@mapNotNull null
                    LatLng(la, ln)
                }
                mapView.fitBounds(points)
                result.success(null)
            }
            "updateRoute" -> {
                @Suppress("UNCHECKED_CAST")
                val segments = call.argument<List<Map<String, Any>>>("segments") ?: emptyList()
                @Suppress("UNCHECKED_CAST")
                val traveled = call.argument<List<Map<String, Double>>>("traveled") ?: emptyList()
                val origin = call.argument<Map<String, Double>>("origin")
                val destination = call.argument<Map<String, Double>>("destination")
                val driver = call.argument<Map<String, Any>>("driver")
                val mapDark = call.argument<Boolean>("mapDark") ?: false
                val overviewMode = call.argument<Boolean>("overviewMode") ?: false
                val pickupLeg = call.argument<Boolean>("pickupLeg") ?: false
                mapView.updateRouteOverlay(
                    segments,
                    traveled,
                    origin,
                    destination,
                    driver,
                    mapDark,
                    overviewMode,
                    pickupLeg,
                )
                result.success(null)
            }
            "updateDriverMarker" -> {
                val lat = call.argument<Double>("lat") ?: 0.0
                val lng = call.argument<Double>("lng") ?: 0.0
                val bearing = call.argument<Double>("bearing")?.toFloat()
                val navigationMode = call.argument<Boolean>("navigationMode") ?: true
                mapView.updateDriverMarker(lat, lng, bearing, navigationMode)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val VIEW_TYPE = "com.example.legestic/neshan_map_view"
    }
}

private object NeshanMapRegistry {
    private val views = ConcurrentHashMap<Int, NeshanMapPlatformView>()
    var eventSink: EventChannel.EventSink? = null

    fun put(id: Int, view: NeshanMapPlatformView) {
        views[id] = view
    }

    fun remove(id: Int) {
        views.remove(id)
    }

    fun get(id: Int): NeshanMapPlatformView? = views[id]

    fun emitEvent(payload: Map<String, Any>) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(payload)
        }
    }

    fun clear() {
        views.clear()
        eventSink = null
    }
}

private class NeshanMapViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val isDark = params?.get("isDark") as? Boolean ?: false
        return NeshanMapPlatformView(context, viewId, isDark)
    }
}

private class NeshanMapPlatformView(
    private val context: Context,
    private val viewId: Int,
    isDark: Boolean,
) : PlatformView {
    private val container = FrameLayout(context)
    private val mapView = MapView(context)
    private var map: MapLibreMap? = null
    private var styleReady = false

    private val routePolylines = mutableListOf<Polyline>()
    private var traveledPolyline: Polyline? = null
    private var originMarker: Marker? = null
    private var destinationMarker: Marker? = null
    private var driverMarker: Marker? = null

    private var navigationFollowEnabled = false
    private var overviewGesturesEnabled = false
    private var mapDark = isDark
    private var pendingActions = mutableListOf<() -> Unit>()

    init {
        container.addView(
            mapView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        NeshanMapRegistry.put(viewId, this)

        mapView.onCreate(Bundle())
        mapView.onStart()
        mapView.onResume()

        mapView.getMapAsync { mapLibreMap ->
            map = mapLibreMap
            mapLibreMap.uiSettings.isAttributionEnabled = true
            mapLibreMap.uiSettings.isLogoEnabled = true
            applyStyle(mapDark) {
                mapLibreMap.cameraPosition = CameraPosition.Builder()
                    .target(LatLng(35.6892, 51.3890))
                    .zoom(11.0)
                    .tilt(0.0)
                    .build()
                setupGestures(mapLibreMap)
                styleReady = true
                pendingActions.toList().forEach { it.invoke() }
                pendingActions.clear()
            }
        }
    }

    private fun styleUri(dark: Boolean): String =
        if (dark) {
            "https://static.neshan.org/sdk/maplibre/styles/dark.json"
        } else {
            "https://static.neshan.org/sdk/maplibre/styles/light.json"
        }

    private fun applyStyle(dark: Boolean, onReady: (() -> Unit)? = null) {
        val m = map ?: return
        mapDark = dark
        styleReady = false
        m.setStyle(Style.Builder().fromUri(styleUri(dark))) {
            styleReady = true
            onReady?.invoke()
        }
    }

    private fun runWhenReady(action: () -> Unit) {
        if (styleReady && map != null) {
            action()
        } else {
            pendingActions.add(action)
        }
    }

    private fun setupGestures(mapLibreMap: MapLibreMap) {
        mapLibreMap.addOnCameraMoveStartedListener { reason ->
            if (reason == MapLibreMap.OnCameraMoveStartedListener.REASON_API_GESTURE) {
                if (navigationFollowEnabled) {
                    navigationFollowEnabled = false
                    NeshanMapRegistry.emitEvent(
                        mapOf(
                            "type" to "cameraDetached",
                            "viewId" to viewId,
                        ),
                    )
                } else if (overviewGesturesEnabled) {
                    NeshanMapRegistry.emitEvent(
                        mapOf(
                            "type" to "userGesture",
                            "viewId" to viewId,
                        ),
                    )
                }
            }
        }
    }

    fun setNavigationFollowEnabled(enabled: Boolean) {
        navigationFollowEnabled = enabled
    }

    fun setOverviewGesturesEnabled(enabled: Boolean) {
        overviewGesturesEnabled = enabled
        map?.uiSettings?.isRotateGesturesEnabled = enabled
        map?.uiSettings?.isTiltGesturesEnabled = enabled
    }

    fun moveCamera(
        position: LatLng,
        zoom: Double,
        bearing: Double?,
        navigation: Boolean,
        tilt: Double?,
    ) {
        runWhenReady {
            val m = map ?: return@runWhenReady
            // MapLibre: pitch 0 = top-down, ~50 = navigation tilt
            val pitch = when {
                tilt != null -> cartoTiltToPitch(tilt)
                navigation -> NAV_PITCH
                else -> 0.0
            }
            val builder = CameraPosition.Builder()
                .target(position)
                .zoom(zoom)
                .tilt(pitch)
            if (bearing != null) builder.bearing(bearing)
            m.animateCamera(CameraUpdateFactory.newCameraPosition(builder.build()), 450)
        }
    }

    fun beginNavigationCamera(position: LatLng, bearing: Float) {
        navigationFollowEnabled = true
        runWhenReady {
            val m = map ?: return@runWhenReady
            m.uiSettings.isRotateGesturesEnabled = false
            m.uiSettings.isTiltGesturesEnabled = false
            val cam = CameraPosition.Builder()
                .target(position)
                .zoom(NAV_ZOOM)
                .bearing(bearing.toDouble())
                .tilt(NAV_PITCH)
                .build()
            m.animateCamera(CameraUpdateFactory.newCameraPosition(cam), 600)
        }
    }

    fun updateNavigationCamera(position: LatLng, bearing: Float) {
        if (!navigationFollowEnabled) return
        runWhenReady {
            val m = map ?: return@runWhenReady
            val cam = CameraPosition.Builder()
                .target(position)
                .zoom(NAV_ZOOM)
                .bearing(bearing.toDouble())
                .tilt(NAV_PITCH)
                .build()
            m.animateCamera(CameraUpdateFactory.newCameraPosition(cam), 250)
        }
    }

    fun fitBounds(points: List<LatLng>) {
        if (points.isEmpty()) return
        runWhenReady {
            val m = map ?: return@runWhenReady
            if (points.size == 1) {
                m.animateCamera(CameraUpdateFactory.newLatLngZoom(points.first(), 14.0), 500)
                return@runWhenReady
            }
            val builder = LatLngBounds.Builder()
            points.forEach { builder.include(it) }
            m.animateCamera(CameraUpdateFactory.newLatLngBounds(builder.build(), 80), 600)
        }
    }

    fun updateRouteOverlay(
        segments: List<Map<String, Any>>,
        traveled: List<Map<String, Double>>,
        origin: Map<String, Double>?,
        destination: Map<String, Double>?,
        driver: Map<String, Any>?,
        mapDark: Boolean,
        overviewMode: Boolean,
        pickupLeg: Boolean,
    ) {
        runWhenReady {
            val m = map ?: return@runWhenReady
            if (this.mapDark != mapDark) {
                // Rebuild style then re-apply overlays
                applyStyle(mapDark) {
                    drawRoute(m, segments, traveled, origin, destination, driver, overviewMode, pickupLeg)
                }
            } else {
                drawRoute(m, segments, traveled, origin, destination, driver, overviewMode, pickupLeg)
            }
        }
    }

    private fun drawRoute(
        m: MapLibreMap,
        segments: List<Map<String, Any>>,
        traveled: List<Map<String, Double>>,
        origin: Map<String, Double>?,
        destination: Map<String, Double>?,
        driver: Map<String, Any>?,
        overviewMode: Boolean,
        pickupLeg: Boolean,
    ) {
        routePolylines.forEach { m.removePolyline(it) }
        routePolylines.clear()
        traveledPolyline?.let { m.removePolyline(it) }
        traveledPolyline = null

        // Casing
        val allPoints = mutableListOf<LatLng>()
        for (seg in segments) {
            @Suppress("UNCHECKED_CAST")
            val coords = seg["coordinates"] as? List<Map<String, Double>> ?: continue
            for (c in coords) {
                val la = c["lat"] ?: continue
                val ln = c["lng"] ?: continue
                allPoints.add(LatLng(la, ln))
            }
        }
        if (allPoints.size >= 2) {
            routePolylines.add(
                m.addPolyline(
                    PolylineOptions()
                        .addAll(allPoints)
                        .color(Color.WHITE)
                        .width(if (overviewMode) 10f else 12f),
                ),
            )
        }

        for (seg in segments) {
            @Suppress("UNCHECKED_CAST")
            val coords = seg["coordinates"] as? List<Map<String, Double>> ?: continue
            val level = (seg["trafficLevel"] as? Number)?.toInt() ?: 0
            val points = coords.mapNotNull { c ->
                val la = c["lat"] ?: return@mapNotNull null
                val ln = c["lng"] ?: return@mapNotNull null
                LatLng(la, ln)
            }
            if (points.size < 2) continue
            routePolylines.add(
                m.addPolyline(
                    PolylineOptions()
                        .addAll(points)
                        .color(trafficColor(level))
                        .width(if (overviewMode) 6f else 8f),
                ),
            )
        }

        val traveledPoints = traveled.mapNotNull { c ->
            val la = c["lat"] ?: return@mapNotNull null
            val ln = c["lng"] ?: return@mapNotNull null
            LatLng(la, ln)
        }
        if (traveledPoints.size >= 2) {
            traveledPolyline = m.addPolyline(
                PolylineOptions()
                    .addAll(traveledPoints)
                    .color(0xFF9CA3AF.toInt())
                    .width(if (overviewMode) 6f else 8f),
            )
        }

        origin?.let { o ->
            val la = o["lat"] ?: return@let
            val ln = o["lng"] ?: return@let
            originMarker?.let { m.removeMarker(it) }
            originMarker = m.addMarker(
                MarkerOptions()
                    .position(LatLng(la, ln))
                    .title(if (pickupLeg) "مبدا" else "بارگیری"),
            )
        }
        destination?.let { d ->
            val la = d["lat"] ?: return@let
            val ln = d["lng"] ?: return@let
            destinationMarker?.let { m.removeMarker(it) }
            destinationMarker = m.addMarker(
                MarkerOptions()
                    .position(LatLng(la, ln))
                    .title("مقصد"),
            )
        }

        driver?.let { d ->
            val la = (d["lat"] as? Number)?.toDouble() ?: return@let
            val ln = (d["lng"] as? Number)?.toDouble() ?: return@let
            val bearing = (d["bearing"] as? Number)?.toFloat()
            val nav = d["navigationMode"] as? Boolean ?: true
            updateDriverMarker(la, ln, bearing, nav)
        }
    }

    fun updateDriverMarker(
        lat: Double,
        lng: Double,
        bearing: Float?,
        navigationMode: Boolean,
    ) {
        runWhenReady {
            val m = map ?: return@runWhenReady
            driverMarker?.let { m.removeMarker(it) }
            val icon = if (navigationMode) {
                val bmp = NavArrowBitmap.create(bearing ?: 0f)
                IconFactory.getInstance(context).fromBitmap(bmp)
            } else {
                IconFactory.getInstance(context).defaultMarker()
            }
            driverMarker = m.addMarker(
                MarkerOptions()
                    .position(LatLng(lat, lng))
                    .icon(icon),
            )
        }
    }

    private fun trafficColor(level: Int): Int = when (level) {
        2 -> 0xFFFF9800.toInt()
        3, 4 -> 0xFFF44336.toInt()
        else -> 0xFF250ECD.toInt()
    }

    /** Old Carto tilt 90=top-down / 0=horizon → MapLibre pitch 0=top-down / 60=tilted. */
    private fun cartoTiltToPitch(cartoTilt: Double): Double {
        val clamped = cartoTilt.coerceIn(0.0, 90.0)
        return ((90.0 - clamped) / 90.0 * 60.0).coerceIn(0.0, 60.0)
    }

    override fun getView(): View = container

    override fun dispose() {
        NeshanMapRegistry.remove(viewId)
        try {
            mapView.onPause()
            mapView.onStop()
            mapView.onDestroy()
        } catch (_: Throwable) {
        }
        container.removeAllViews()
    }

    companion object {
        private const val NAV_ZOOM = 17.5
        private const val NAV_PITCH = 50.0
    }
}
