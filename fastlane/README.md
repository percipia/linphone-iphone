# Fastlane Configuration

This project uses [fastlane match](https://docs.fastlane.tools/actions/match/) to manage code signing certificates and provisioning profiles.

## Configuration

The project manages certificates and provisioning profiles for three app identifiers:
- `com.percipia.connect` (main app)
- `com.percipia.connect.linphoneExtension` (extension)
- `com.percipia.connect.msgNotificationService` (notification service)

Certificates are stored in a private Git repository. The repository URL is configured via the `MATCH_GIT_URL` environment variable.

## Available Lanes

- `match_development` - Downloads development certificates and provisioning profiles (readonly)
- `match_appstore` - Downloads App Store certificates and provisioning profiles (readonly)
- `build_debug` - Builds debug version of the app
- `build_prod` - Builds production version of the app
- `upload_testflight` - Uploads the binary created by *build_prod* to Apple TestFlight for testing and release

## Generating New Provisioning Profiles

To generate new provisioning profiles, use the following commands on your local machine (from the project root directory):

### App Store Profiles
```bash
fastlane match appstore --app_identifier com.percipia.connect,com.percipia.connect.linphoneExtension,com.percipia.connect.msgNotificationService,com.percipia.connect.intentsExtension --force
```

### Development Profiles
```bash
fastlane match development --app_identifier com.percipia.connect,com.percipia.connect.linphoneExtension,com.percipia.connect.msgNotificationService,com.percipia.connect.intentsExtension --force
```

The `--force` flag will revoke existing profiles and create new ones.

> **Note:** Running the above `fastlane match` commands will require you to authenticate with your Apple Developer account. Additionally, during the process, fastlane will prompt you for the URL of the private certificates Git repository. Be sure to have both your Apple credentials and the repository link available before proceeding.
