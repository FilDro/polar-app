Pod::Spec.new do |s|
  s.name             = 'rust_lib_polar_app'
  s.version          = '0.0.1'
  s.summary          = 'Rust native library for Polar App (built by flutter_rust_bridge).'
  s.description      = 'Auto-built Rust static library for iOS.'
  s.homepage         = 'https://github.com/FilDro/polar-rs'
  s.license          = { :type => 'MIT' }
  s.author           = 'KINE'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.ios.deployment_target = '13.0'
  s.static_framework = true
  s.dependency 'Flutter'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'bash "${PODS_TARGET_SRCROOT}/../../rust/build-ios.sh" 2>&1',
    :execution_position => :before_compile,
    :input_files => ['${PODS_TARGET_SRCROOT}/../../rust/src/**/*.rs'],
    :output_files => ["${BUILT_PRODUCTS_DIR}/librust_lib_polar_app.a"],
  }

  s.frameworks = 'CoreBluetooth', 'CoreFoundation', 'Security'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/librust_lib_polar_app.a',
  }

  s.xcconfig = {
    'OTHER_LDFLAGS' => '-force_load ${PODS_CONFIGURATION_BUILD_DIR}/rust_lib_polar_app/librust_lib_polar_app.a',
    'DEAD_CODE_STRIPPING' => 'NO',
    'STRIP_INSTALLED_PRODUCT' => 'NO',
    'STRIP_STYLE' => 'debugging',
  }
end
