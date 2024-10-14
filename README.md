# siltti_ios

## Rust
1. Put ios_build.sh in rust folder of siltti project
2. run `sh ios_build.sh` from it
3. It will create `SilttiUniffiFFI.xcframework` and `SilttiUniffi.swift`, add them into iOS project

## iOS
1. Run project on real device, supporting iOS 16+, allow camera permission
2. On first launch, open Manage Networks and add defaults (up to 3 networks)
3. On main screen scan QR code with payload or send blank payload
4. Use `Status/Read/Write` buttons for `NDEF Status/NDEF Message/Write APDU with payload`

## Links
https://metadata.parity.io/#/polkadot
https://polkadot.js.org/apps/#/accounts
