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
import org.maplibre.android.style.layers.Property
import org.maplibre.android.style.layers.PropertyFactory
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
                val points = parseLatLngArgumentList(call.argument("points"))
                val overview = call.argument<Boolean>("overview") ?: true
                val bottomInsetRatio = call.argument<Double>("bottomInsetRatio") ?: 0.12
                mapView.fitBounds(points, overview, bottomInsetRatio)
                result.success(null)
            }
            "updateRoute" -> {
                val segmentsRaw = call.argument<List<*>>("segments") ?: emptyList<Any>()
                val segments = segmentsRaw.mapNotNull { item ->
                    val map = item as? Map<*, *> ?: return@mapNotNull null
                    buildMap<String, Any> {
                        for ((k, v) in map) {
                            if (k != null && v != null) put(k.toString(), v)
                        }
                    }.takeIf { it.isNotEmpty() }
                }
                val traveled = parseLatLngArgumentMaps(call.argument("traveled"))
                val origin = parseLatLngArgumentMap(call.argument("origin"))
                val destination = parseLatLngArgumentMap(call.argument("destination"))
                @Suppress("UNCHECKED_CAST")
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

        private fun parseLatLngArgumentList(raw: Any?): List<LatLng> {
            val list = raw as? List<*> ?: return emptyList()
            return list.mapNotNull { parseLatLngArgument(it) }
        }

        private fun parseLatLngArgumentMaps(raw: Any?): List<Map<String, Double>> {
            val list = raw as? List<*> ?: return emptyList()
            return list.mapNotNull { item ->
                val map = item as? Map<*, *> ?: return@mapNotNull null
                val la = (map["lat"] as? Number)?.toDouble() ?: return@mapNotNull null
                val ln = (map["lng"] as? Number)?.toDouble() ?: return@mapNotNull null
                mapOf("lat" to la, "lng" to ln)
            }
        }

        private fun parseLatLngArgumentMap(raw: Any?): Map<String, Double>? {
            val map = raw as? Map<*, *> ?: return null
            val la = (map["lat"] as? Number)?.toDouble() ?: return null
            val ln = (map["lng"] as? Number)?.toDouble() ?: return null
            return mapOf("lat" to la, "lng" to ln)
        }

        private fun parseLatLngArgument(raw: Any?): LatLng? {
            val map = raw as? Map<*, *> ?: return null
            val la = (map["lat"] as? Number)?.toDouble() ?: return null
            val ln = (map["lng"] as? Number)?.toDouble() ?: return null
            return LatLng(la, ln)
        }
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
        m.setStyle(Style.Builder().fromUri(styleUri(dark))) { style ->
            enableLiveTrafficLayers(style)
            styleReady = true
            onReady?.invoke()
        }
    }

    /**
     * Keep Neshan basemap traffic layers hidden.
     *
     * Those vector tiles change which roads/colours appear at each zoom, so the
     * map looks like a different traffic model when pinching. Congestion is
     * shown only on the route line (live vs free-flow), which is zoom-stable.
     */
    private fun enableLiveTrafficLayers(style: Style) {
        for (id in TRAFFIC_LAYER_IDS) {
            style.getLayer(id)?.setProperties(
                PropertyFactory.visibility(Property.NONE),
            )
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
                            // Matches Dart [NeshanDriverMap._onMapEvent].
                            "type" to "userCameraGesture",
                            "viewId" to viewId,
                        ),
                    )
                } else if (overviewGesturesEnabled) {
                    NeshanMapRegistry.emitEvent(
                        mapOf(
                            "type" to "overviewCameraGesture",
                            "viewId" to viewId,
                        ),
                    )
                }
            }
        }
    }

    fun setNavigationFollowEnabled(enabled: Boolean) {
        navigationFollowEnabled = enabled
        if (enabled) {
            applyNavigationCameraChrome()
        } else if (!overviewGesturesEnabled) {
            clearNavigationCameraChrome()
        }
    }

    fun setOverviewGesturesEnabled(enabled: Boolean) {
        overviewGesturesEnabled = enabled
        map?.uiSettings?.isRotateGesturesEnabled = enabled
        map?.uiSettings?.isTiltGesturesEnabled = enabled
        if (enabled) {
            clearNavigationCameraChrome()
        }
    }

    /**
     * Puck in lower third + road ahead above (uzita NAV_FOCUS_OFFSET).
     *
     * MapLibre centers the camera in the *unpadded* region. Top padding pushes
     * the target down the screen — same effect as Carto
     * `setMapFocusPointOffset(0, -height * 0.30)`.
     */
    private fun applyNavigationCameraChrome() {
        val m = map ?: return
        val h = mapView.height.coerceAtLeast(1)
        val top = (h * NAV_FOCUS_OFFSET).toInt()
        m.setPadding(0, top, 0, 0)
        m.uiSettings.isRotateGesturesEnabled = false
        m.uiSettings.isTiltGesturesEnabled = false
    }

    private fun clearNavigationCameraChrome() {
        map?.setPadding(0, 0, 0, 0)
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
            val pitch = when {
                tilt != null -> cartoTiltToPitch(tilt)
                navigation -> NAV_PITCH
                else -> 0.0
            }
            if (navigation) {
                applyNavigationCameraChrome()
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
            applyNavigationCameraChrome()
            val cam = CameraPosition.Builder()
                .target(position)
                .zoom(NAV_ZOOM)
                .bearing(bearing.toDouble())
                .tilt(NAV_PITCH)
                .build()
            // Instant framing like uzita (animatePositionMs = 0).
            m.moveCamera(CameraUpdateFactory.newCameraPosition(cam))
        }
    }

    fun updateNavigationCamera(position: LatLng, bearing: Float) {
        if (!navigationFollowEnabled) return
        runWhenReady {
            val m = map ?: return@runWhenReady
            applyNavigationCameraChrome()
            val cam = CameraPosition.Builder()
                .target(position)
                .zoom(NAV_ZOOM)
                .bearing(bearing.toDouble())
                .tilt(NAV_PITCH)
                .build()
            // Instant heading-up updates — same feel as uzita NavigationCamera.
            m.moveCamera(CameraUpdateFactory.newCameraPosition(cam))
        }
    }

    fun fitBounds(points: List<LatLng>, overview: Boolean = true, bottomInsetRatio: Double = 0.12) {
        if (points.isEmpty()) return
        runWhenReady {
            val m = map ?: return@runWhenReady
            // Overview = top-down, north-up (uzita-style).
            if (overview) {
                clearNavigationCameraChrome()
                m.uiSettings.isRotateGesturesEnabled = true
                m.uiSettings.isTiltGesturesEnabled = true
            }
            if (points.size == 1) {
                m.animateCamera(
                    CameraUpdateFactory.newCameraPosition(
                        CameraPosition.Builder()
                            .target(points.first())
                            .zoom(14.0)
                            .tilt(0.0)
                            .bearing(0.0)
                            .build(),
                    ),
                    600,
                )
                return@runWhenReady
            }

            val minLat = points.minOf { it.latitude }
            val maxLat = points.maxOf { it.latitude }
            val minLng = points.minOf { it.longitude }
            val maxLng = points.maxOf { it.longitude }
            // Extra geographic padding so the full road path sits in a higher overview.
            val padFactor = if (overview) 0.32 else 0.18
            val minPad = if (overview) 0.012 else 0.004
            // Cap absolute padding so long Iran routes (Tehran↔Bandar Abbas)
            // don't zoom out across the whole Middle East.
            val maxPad = if (overview) 0.55 else 0.25
            val latPad = maxOf((maxLat - minLat) * padFactor, minPad).coerceAtMost(maxPad)
            val lngPad = maxOf((maxLng - minLng) * padFactor, minPad).coerceAtMost(maxPad)

            val builder = LatLngBounds.Builder()
            builder.include(LatLng(minLat - latPad, minLng - lngPad))
            builder.include(LatLng(maxLat + latPad, maxLng + lngPad))
            points.forEach { builder.include(it) }

            val view = mapView
            val bottomInset = (view.height * bottomInsetRatio.coerceIn(0.04, 0.45)).toInt()
            val edge = if (overview) 72 else 48
            // Reset to north-up / top-down before framing the full route.
            if (overview) {
                m.moveCamera(
                    CameraUpdateFactory.newCameraPosition(
                        CameraPosition.Builder(m.cameraPosition)
                            .tilt(0.0)
                            .bearing(0.0)
                            .build(),
                    ),
                )
            }
            m.animateCamera(
                CameraUpdateFactory.newLatLngBounds(
                    builder.build(),
                    edge,
                    edge,
                    edge,
                    edge + bottomInset,
                ),
                700,
            )
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
        originMarker?.let { m.removeMarker(it) }
        originMarker = null
        destinationMarker?.let { m.removeMarker(it) }
        destinationMarker = null

        val navigationMode = driver?.get("navigationMode") as? Boolean ?: !overviewMode
        val coreWidth = if (navigationMode) 12f else 9f
        val casingWidth = coreWidth + 4f

        // White casing under the full route.
        val allPoints = mutableListOf<LatLng>()
        for (seg in segments) {
            allPoints.addAll(parseLatLngList(seg["points"] ?: seg["coordinates"]))
        }
        if (allPoints.size >= 2) {
            routePolylines.add(
                m.addPolyline(
                    PolylineOptions()
                        .addAll(allPoints)
                        .color(Color.WHITE)
                        .width(casingWidth),
                ),
            )
        }

        // Zoom-stable congestion on the route only (آبی / نارنجی / قرمز).
        for (seg in segments) {
            val points = parseLatLngList(seg["points"] ?: seg["coordinates"])
            if (points.size < 2) continue
            routePolylines.add(
                m.addPolyline(
                    PolylineOptions()
                        .addAll(points)
                        .color(routeTrafficColor(seg["trafficLevel"]))
                        .width(coreWidth),
                ),
            )
        }

        val traveledPoints = parseLatLngList(traveled)
        if (traveledPoints.size >= 2) {
            traveledPolyline = m.addPolyline(
                PolylineOptions()
                    .addAll(traveledPoints)
                    .color(0xFF9CA3AF.toInt())
                    .width(7f),
            )
        }

        // Overview: always show cargo origin (blue) + destination (orange).
        // Navigation: show the current target pin (blue = pickup origin).
        val bluePin = 0xFF2563EB.toInt()
        val orangePin = 0xFFEA580C.toInt()
        val iconFactory = IconFactory.getInstance(context)

        if (overviewMode && !navigationMode) {
            parseLatLng(origin)?.let { pos ->
                originMarker = m.addMarker(
                    MarkerOptions()
                        .position(pos)
                        .title("مبدا بار")
                        .icon(iconFactory.fromBitmap(LocationPinBitmap.create(bluePin))),
                )
            }
            parseLatLng(destination)?.let { pos ->
                destinationMarker = m.addMarker(
                    MarkerOptions()
                        .position(pos)
                        .title("مقصد")
                        .icon(iconFactory.fromBitmap(LocationPinBitmap.create(orangePin))),
                )
            }
        } else if (navigationMode) {
            parseLatLng(destination)?.let { pos ->
                val color = if (pickupLeg) bluePin else orangePin
                val title = if (pickupLeg) "مبدا بار" else "مقصد"
                destinationMarker = m.addMarker(
                    MarkerOptions()
                        .position(pos)
                        .title(title)
                        .icon(iconFactory.fromBitmap(LocationPinBitmap.create(color))),
                )
            }
        }

        driver?.let { d ->
            val la = (d["lat"] as? Number)?.toDouble() ?: return@let
            val ln = (d["lng"] as? Number)?.toDouble() ?: return@let
            val bearing = (d["bearing"] as? Number)?.toFloat()
            val nav = d["navigationMode"] as? Boolean ?: true
            updateDriverMarker(la, ln, bearing, nav)
        }
    }

    /** Robust parse for Flutter StandardMessageCodec maps (Number, not Double). */
    private fun parseLatLngList(raw: Any?): List<LatLng> {
        val list = raw as? List<*> ?: return emptyList()
        return list.mapNotNull { parseLatLng(it) }
    }

    private fun parseLatLng(raw: Any?): LatLng? {
        val map = raw as? Map<*, *> ?: return null
        val la = (map["lat"] as? Number)?.toDouble() ?: return null
        val ln = (map["lng"] as? Number)?.toDouble() ?: return null
        return LatLng(la, ln)
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
                // Heading-up follow: map faces the route, puck points screen-up.
                // Detached: rotate puck relative to current map bearing (uzita).
                val absolute = bearing ?: m.cameraPosition.bearing.toFloat()
                val relative = if (!navigationFollowEnabled) {
                    normalizeBearingDegrees(absolute - m.cameraPosition.bearing.toFloat())
                } else {
                    0f
                }
                val bmp = NavArrowBitmap.create(relative)
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

    private fun normalizeBearingDegrees(degrees: Float): Float {
        var v = degrees % 360f
        if (v < 0f) v += 360f
        return v
    }

    /** آبی = روان، نارنجی = نیمه‌سنگین، قرمز = سنگین. */
    private fun routeTrafficColor(level: Any?): Int {
        return when (level?.toString()?.lowercase()) {
            "heavy", "3", "4" -> ROUTE_TRAFFIC_HEAVY
            "moderate", "2" -> ROUTE_TRAFFIC_MODERATE
            else -> ROUTE_NESHAN_BLUE
        }
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
        private val TRAFFIC_LAYER_IDS = listOf(
            "traffic-minor",
            "traffic-primary",
            "traffic-highway",
        )

        /** روان (`#250ECD`). */
        private const val ROUTE_NESHAN_BLUE = 0xFF250ECD.toInt()

        /** نیمه‌سنگین — matches Neshan traffic tile level 2. */
        private const val ROUTE_TRAFFIC_MODERATE = 0xFFF8830B.toInt()

        /** سنگین — matches Neshan traffic tile level 3. */
        private const val ROUTE_TRAFFIC_HEAVY = 0xFFFF0C00.toInt()

        /** Matches uzita NeshanMapPlugin.NAV_ZOOM. */
        private const val NAV_ZOOM = 17.5

        /**
         * Carto/Neshan tilt 54 (uzita NAV_TILT): 90=top-down, 0=horizon.
         * Converted to MapLibre pitch (0=top-down, 60=tilted).
         */
        private val NAV_PITCH = ((90.0 - 54.0) / 90.0 * 60.0).coerceIn(0.0, 60.0)

        /** Matches uzita NAV_FOCUS_OFFSET — puck in the lower third. */
        private const val NAV_FOCUS_OFFSET = 0.30
    }
}
