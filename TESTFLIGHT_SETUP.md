# TestFlight release setup

The repository is configured to upload a properly signed build to App Store Connect using GitHub Actions, Apple cloud signing, and an App Store Connect API key.

## Apple-side prerequisites

1. Apple Developer Program membership must be active.
2. Register the explicit bundle ID `com.robtheproducer.nearbysignaldetector` if it does not already exist.
3. In App Store Connect, create an iOS app record named `Nearby Signal Detector` that uses that bundle ID.
4. Create an App Store Connect API key with sufficient permission to upload builds and use automatic signing. Save the Key ID, Issuer ID, and downloaded `.p8` private key.
5. Find the Apple Developer Team ID for the membership.

## GitHub Actions secrets

In repository Settings → Secrets and variables → Actions, add these repository secrets:

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

Paste the complete contents of the downloaded `.p8` file into `APP_STORE_CONNECT_PRIVATE_KEY`. Never commit the `.p8` file to the repository.

## Upload

Open Actions → **Upload to TestFlight** → **Run workflow**.

The workflow uses macOS 26 and Xcode 26.6, generates the Xcode project with XcodeGen, authenticates xcodebuild with the App Store Connect API key, archives using automatic signing, and uploads directly to App Store Connect. The workflow run number is used as the build number so each upload remains unique.

After Apple finishes processing the build, add the build to an internal TestFlight group in App Store Connect and invite the Apple Account used on the test iPhone.
