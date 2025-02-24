# siltti_ios

## GIT LFS
If compiled SilttiUnifiFFI.xcframework is too large (>200MB), it should be tracked with Git Large File Storage (install `git-lfs` tool).
The `.gitattributes` manages list of files to be stored separetly (currently `*.a`), default `git push` will do the job 
To pull such files use `git-lfs fetch` command

## Rust
1. Make sure `uniffi.toml` contains:
```[bindings.swift]
module_name = "SilttiUniffi"
cdylib_name = "siltti"```
2. Put ios_build.sh in rust folder of siltti project
3. run `sh ios_build.sh` from it
4. It will create `SilttiUniffiFFI.xcframework` and `SilttiUniffi.swift`, add them into iOS project

## iOS
0. Device should be opt-in for installing apps via xcode, open `Settings > Privacy & Secure > Developer Mode > Enable toggle`

1. Run project on a real device supporting iOS 16+. Allow camera permission
2. On first app launch, open Manage Networks and tap to add defaults (up to 3 networks)
3. From main screen scan QR code with payload or send blank payload
4. Use `Status/Read/Write` buttons for getting `NDEF Status/NDEF Message/Write APDU with payload` in endless cycle (until error is triggered)


## Test Flight
1. To distribute a new build run Product > Archive > Distribute App > TestFlight
2. After a while it will appear on a http://appstoreconnect.apple.com/ portal, under Apps > Sillti > Testflight
3. Archive Post-Action will automatically increment minor build version (so next build could be uploaded to TestFlight)
4. All users from `testers`(?) group will automatically be notified via email/push
5. To add new users to a group, firstly invite them under `Users and Access` tab on a portal
