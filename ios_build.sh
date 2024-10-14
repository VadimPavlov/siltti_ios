cargo build
cargo run --bin uniffi-bindgen generate --library ./target/debug/libsiltti.dylib --language swift --out-dir ./bindings
rustup target add aarch64-apple-ios
cargo build --release --target=aarch64-apple-ios
mv bindings/SilttiUniffiFFI.modulemap bindings/module.modulemap
xcodebuild -create-xcframework -library ./target/aarch64-apple-ios/release/libsiltti.a -headers ./bindings -output "ios/SilttiUniffiFFI.xcframework"
mv bindings/SilttiUniffi.swift ios/SilttiUniffi.swift
rm -rf bindings
# add ios/SilttiUniffi.swift into your project
# add ios/SilttiUniffiFFI.xcframework into your project
