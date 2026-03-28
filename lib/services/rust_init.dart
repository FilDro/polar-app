import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import '../src/rust/frb_generated.dart';

Future<void> initRustBridge() async {
  if (Platform.isIOS) {
    await RustLib.init(
      externalLibrary: ExternalLibrary.process(iKnowHowToUseIt: true),
    );
  } else {
    await RustLib.init();
  }
  debugPrint('Polar App: Rust bridge initialized');
}
