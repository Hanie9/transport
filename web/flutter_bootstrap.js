{{flutter_js}}
{{flutter_build_config}}

// Offline support is provided by pwa_service_worker.js. Do not pass Flutter's
// deprecated serviceWorkerSettings here, otherwise both workers compete for
// the same scope on every page load.
_flutter.loader.load();
