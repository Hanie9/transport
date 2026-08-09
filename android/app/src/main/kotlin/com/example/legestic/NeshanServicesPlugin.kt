package com.example.legestic

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import org.neshan.common.model.LatLng
import org.neshan.servicessdk.direction.NeshanDirection
import org.neshan.servicessdk.direction.model.DirectionResultLeg
import org.neshan.servicessdk.direction.model.DirectionStep
import org.neshan.servicessdk.direction.model.NeshanDirectionResult
import org.neshan.servicessdk.search.NeshanSearch
import org.neshan.servicessdk.search.model.NeshanSearchResult
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import java.util.ArrayList
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/// Neshan routing/search via package-scoped service key.
///
/// Long domestic routes (e.g. Tehran → Bandar Abbas) often exceed the legacy
/// SDK's default ~10s timeout, so [getRoute] prefers OkHttp `v4/direction`
/// with a longer timeout and falls back to the AAR SDK.
class NeshanServicesPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newCachedThreadPool()

    private val httpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(45, TimeUnit.SECONDS)
            .writeTimeout(20, TimeUnit.SECONDS)
            .callTimeout(55, TimeUnit.SECONDS)
            .build()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.legestic/neshan_services")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "geocodeAddress" -> searchAddress(call, result)
            "searchAddress" -> searchAddress(call, result)
            "getRoute" -> getRoute(call, result)
            else -> result.notImplemented()
        }
    }

    private fun searchAddress(call: MethodCall, result: MethodChannel.Result) {
        val term = (
            call.argument<String>("term")
                ?: call.argument<String>("address")
            )?.trim().orEmpty()
        if (term.isEmpty()) {
            result.error("invalid_argument", "address is required", null)
            return
        }

        // NeshanSearch requires a non-null location (SDK NPE otherwise).
        val centerLat = call.argument<Double>("centerLat") ?: 35.6892
        val centerLng = call.argument<Double>("centerLng") ?: 51.3890

        val search = NeshanSearch.Builder(term)
            .setLocation(LatLng(centerLat, centerLng))
            .build()
        search.call(object : Callback<NeshanSearchResult> {
            override fun onResponse(
                call: Call<NeshanSearchResult>,
                response: Response<NeshanSearchResult>,
            ) {
                mainHandler.post {
                    if (!response.isSuccessful) {
                        result.error(
                            "neshan_error",
                            "Geocoding failed (${response.code()})",
                            null,
                        )
                        return@post
                    }

                    val items = response.body()?.items
                    if (items.isNullOrEmpty()) {
                        result.error("not_found", "No location found for address", null)
                        return@post
                    }

                    val mapped = items.mapNotNull { item ->
                        val location = item.location ?: return@mapNotNull null
                        mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                            "title" to (item.title ?: ""),
                            "address" to (item.address ?: ""),
                            "neighbourhood" to (item.neighbourhood ?: ""),
                            "city" to cityFromRegion(item.region),
                        )
                    }

                    if (mapped.isEmpty()) {
                        result.error("invalid_response", "Invalid geocoding location", null)
                        return@post
                    }

                    result.success(mapOf("items" to mapped))
                }
            }

            override fun onFailure(call: Call<NeshanSearchResult>, t: Throwable) {
                mainHandler.post {
                    result.error("neshan_error", t.message ?: "Geocoding failed", null)
                }
            }
        })
    }

    private fun cityFromRegion(region: String?): String {
        if (region.isNullOrBlank()) return ""
        return region.split("،").firstOrNull()?.trim().orEmpty()
    }

    private fun getRoute(call: MethodCall, result: MethodChannel.Result) {
        var apiKey = call.argument<String>("apiKey")?.trim().orEmpty()
        if (apiKey.isEmpty()) {
            apiKey = BuildConfig.NESHAN_SERVICE_KEY.trim()
        }
        if (apiKey.isEmpty()) {
            result.error("invalid_argument", "apiKey is required", null)
            return
        }

        val originLat = call.argument<Double>("originLat")
        val originLng = call.argument<Double>("originLng")
        val destLat = call.argument<Double>("destinationLat")
        val destLng = call.argument<Double>("destinationLng")
        val alternative = call.argument<Boolean>("alternative") ?: false
        val avoidTrafficZone = call.argument<Boolean>("avoidTrafficZone") ?: false
        val avoidOddEvenZone = call.argument<Boolean>("avoidOddEvenZone") ?: false
        val vehicleType = call.argument<String>("vehicleType") ?: "car"

        if (originLat == null || originLng == null || destLat == null || destLng == null) {
            result.error("invalid_argument", "origin and destination are required", null)
            return
        }

        @Suppress("UNCHECKED_CAST")
        val waypointsRaw = call.argument<List<Map<String, Any>>>("waypoints")
        val waypoints = waypointsRaw?.mapNotNull { point ->
            val lat = (point["lat"] as? Number)?.toDouble()
            val lng = (point["lng"] as? Number)?.toDouble()
            if (lat != null && lng != null) LatLng(lat, lng) else null
        }.orEmpty()

        // Prefer v4 HTTP for long domestic routes (SDK default timeout is too short).
        ioExecutor.execute {
            try {
                val mapped = fetchRouteV4Http(
                    apiKey = apiKey,
                    originLat = originLat,
                    originLng = originLng,
                    destLat = destLat,
                    destLng = destLng,
                    vehicleType = vehicleType,
                    alternative = alternative,
                    avoidTrafficZone = avoidTrafficZone,
                    avoidOddEvenZone = avoidOddEvenZone,
                    waypoints = waypoints,
                )
                mainHandler.post { result.success(mapped) }
            } catch (httpError: Throwable) {
                // Fall back to legacy AAR SDK (v2/direction).
                fetchRouteViaSdk(
                    apiKey = apiKey,
                    origin = LatLng(originLat, originLng),
                    destination = LatLng(destLat, destLng),
                    alternative = alternative,
                    avoidTrafficZone = avoidTrafficZone,
                    avoidOddEvenZone = avoidOddEvenZone,
                    waypoints = waypoints,
                    result = result,
                    priorError = httpError.message,
                )
            }
        }
    }

    private fun fetchRouteV4Http(
        apiKey: String,
        originLat: Double,
        originLng: Double,
        destLat: Double,
        destLng: Double,
        vehicleType: String,
        alternative: Boolean,
        avoidTrafficZone: Boolean,
        avoidOddEvenZone: Boolean,
        waypoints: List<LatLng>,
    ): Map<String, Any?> {
        val urlBuilder = "https://api.neshan.org/v4/direction".toHttpUrl().newBuilder()
            .addQueryParameter("type", vehicleType)
            .addQueryParameter("origin", "$originLat,$originLng")
            .addQueryParameter("destination", "$destLat,$destLng")
            .addQueryParameter("alternative", alternative.toString())
            .addQueryParameter("avoidTrafficZone", avoidTrafficZone.toString())
            .addQueryParameter("avoidOddEvenZone", avoidOddEvenZone.toString())

        if (waypoints.isNotEmpty()) {
            val joined = waypoints.joinToString("|") { "${it.latitude},${it.longitude}" }
            urlBuilder.addQueryParameter("waypoints", joined)
        }

        val request = Request.Builder()
            .url(urlBuilder.build())
            .header("Api-Key", apiKey)
            .get()
            .build()

        httpClient.newCall(request).execute().use { response ->
            val body = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                throw IllegalStateException(
                    "Routing failed (${response.code})${if (body.isNotBlank()) ": $body" else ""}",
                )
            }
            return parseDirectionJson(body)
        }
    }

    private fun parseDirectionJson(body: String): Map<String, Any?> {
        val root = JSONObject(body)
        val routes = root.optJSONArray("routes")
        if (routes == null || routes.length() == 0) {
            throw IllegalStateException("No route found")
        }
        val route = routes.getJSONObject(0)
        val overview = route.optJSONObject("overview_polyline")
        val polyline = overview?.optString("points").orEmpty()

        val legsJson = route.optJSONArray("legs") ?: JSONArray()
        val legs = ArrayList<Map<String, Any?>>(legsJson.length())
        for (i in 0 until legsJson.length()) {
            legs.add(legJsonToMap(legsJson.getJSONObject(i)))
        }
        if (legs.isEmpty()) {
            throw IllegalStateException("Route has no legs")
        }

        return mapOf(
            "overviewPolyline" to polyline,
            "legs" to legs,
        )
    }

    private fun legJsonToMap(leg: JSONObject): Map<String, Any?> {
        val distance = leg.optJSONObject("distance")
        val duration = leg.optJSONObject("duration")
        val stepsJson = leg.optJSONArray("steps") ?: JSONArray()
        val steps = ArrayList<Map<String, Any?>>(stepsJson.length())
        for (i in 0 until stepsJson.length()) {
            steps.add(stepJsonToMap(stepsJson.getJSONObject(i)))
        }
        return mapOf(
            "summary" to leg.optString("summary"),
            "distanceText" to (distance?.optString("text") ?: ""),
            "distanceMeters" to (distance?.optDouble("value") ?: 0.0),
            "durationText" to (duration?.optString("text") ?: ""),
            "durationSeconds" to (duration?.optDouble("value") ?: 0.0),
            "steps" to steps,
        )
    }

    private fun stepJsonToMap(step: JSONObject): Map<String, Any?> {
        val distance = step.optJSONObject("distance")
        val duration = step.optJSONObject("duration")
        val start = step.optJSONArray("start_location")
        var startLat: Double? = null
        var startLng: Double? = null
        if (start != null && start.length() >= 2) {
            // Neshan returns [lng, lat] for start_location.
            startLng = start.optDouble(0)
            startLat = start.optDouble(1)
        }
        val maneuver = step.optString("maneuver").ifBlank {
            step.optJSONObject("maneuver")?.optString("name").orEmpty()
        }
        return mapOf(
            "instruction" to step.optString("instruction"),
            "name" to step.optString("name"),
            "distanceText" to (distance?.optString("text") ?: ""),
            "durationText" to (duration?.optString("text") ?: ""),
            "distanceMeters" to (distance?.optDouble("value") ?: 0.0),
            "durationSeconds" to (duration?.optDouble("value") ?: 0.0),
            "type" to maneuver,
            "polyline" to step.optString("polyline"),
            "startLat" to startLat,
            "startLng" to startLng,
        )
    }

    private fun fetchRouteViaSdk(
        apiKey: String,
        origin: LatLng,
        destination: LatLng,
        alternative: Boolean,
        avoidTrafficZone: Boolean,
        avoidOddEvenZone: Boolean,
        waypoints: List<LatLng>,
        result: MethodChannel.Result,
        priorError: String?,
    ) {
        val direction = NeshanDirection.Builder(apiKey, origin, destination)
            .setAlternative(alternative)
            .setAvoidTrafficZone(avoidTrafficZone)
            .setAvoidOddEvenZone(avoidOddEvenZone)
            .build()

        if (waypoints.isNotEmpty()) {
            direction.setWaypoints(ArrayList(waypoints))
        }

        direction.call(object : Callback<NeshanDirectionResult> {
            override fun onResponse(
                call: Call<NeshanDirectionResult>,
                response: Response<NeshanDirectionResult>,
            ) {
                mainHandler.post {
                    if (!response.isSuccessful) {
                        val errBody = try {
                            response.errorBody()?.string()
                        } catch (_: Throwable) {
                            null
                        }
                        val detail = buildString {
                            append("Routing failed (${response.code()})")
                            if (!errBody.isNullOrBlank()) append(": $errBody")
                            if (!priorError.isNullOrBlank()) append(" | http: $priorError")
                        }
                        result.error("neshan_error", detail, null)
                        return@post
                    }

                    val routes = response.body()?.routes
                    if (routes.isNullOrEmpty()) {
                        result.error("not_found", "No route found", null)
                        return@post
                    }

                    val route = routes.first()
                    val legs = route.legs?.map { leg -> legToMap(leg) } ?: emptyList()

                    result.success(
                        mapOf(
                            "overviewPolyline" to (route.overviewPolyline?.encodedPolyline ?: ""),
                            "legs" to legs,
                        ),
                    )
                }
            }

            override fun onFailure(call: Call<NeshanDirectionResult>, t: Throwable) {
                mainHandler.post {
                    val detail = buildString {
                        append(t.message ?: "Routing failed")
                        if (!priorError.isNullOrBlank()) append(" | http: $priorError")
                    }
                    result.error("neshan_error", detail, null)
                }
            }
        })
    }

    private fun legToMap(leg: DirectionResultLeg): Map<String, Any?> {
        val steps = leg.directionSteps?.map { step -> stepToMap(step) } ?: emptyList()
        return mapOf(
            "summary" to (leg.summary ?: ""),
            "distanceText" to (leg.distance?.text ?: ""),
            "distanceMeters" to (leg.distance?.value ?: 0),
            "durationText" to (leg.duration?.text ?: ""),
            "durationSeconds" to (leg.duration?.value ?: 0),
            "steps" to steps,
        )
    }

    private fun stepToMap(step: DirectionStep): Map<String, Any?> {
        val maneuver = step.maneuver
        return mapOf(
            "instruction" to (step.instruction ?: ""),
            "name" to (step.name ?: ""),
            "distanceText" to (step.distance?.text ?: ""),
            "durationText" to (step.duration?.text ?: ""),
            "distanceMeters" to (step.distance?.value ?: 0),
            "durationSeconds" to (step.duration?.value ?: 0),
            "type" to (maneuver?.name ?: ""),
            "polyline" to (step.encodedPolyline ?: ""),
            "startLat" to step.startLocation?.latitude,
            "startLng" to step.startLocation?.longitude,
        )
    }
}
