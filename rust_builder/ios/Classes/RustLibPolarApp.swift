import Flutter

public class RustLibPolarAppPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No-op: Rust library loaded via FFI, not platform channels
    }
}
