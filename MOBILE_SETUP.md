# Mobile Setup

This project now includes the app-side changes needed to run on Android and iOS:

- Android minimum SDK is `24`
- iOS deployment target is `15.0`
- Camera and microphone permissions are configured
- Mobile recording defaults to `Camera Only`
- Web-only screen capture modes are hidden on mobile

## Firebase apps

The project is currently wired to these Firebase app identifiers:

- Android package: `com.example.cookoo_record`
- iOS bundle ID: `com.example.cookooRecord`

## Required Firebase Console steps

Some mobile Google Sign-In settings are still missing from the checked-in
Firebase service files, so complete these steps in Firebase before expecting
Google Sign-In to work on Android or iOS:

1. Open Firebase Console for project `cookoo-record`.
2. In `Authentication > Sign-in method`, enable:
   - `Email/Password`
   - `Google`
3. For Android:
   - open the Android app `com.example.cookoo_record`
   - add the debug and release `SHA-1` and `SHA-256` fingerprints
   - download a fresh `google-services.json`
   - confirm it contains OAuth client entries, including a web client
4. For iOS:
   - open the iOS app `com.example.cookooRecord`
   - download a fresh `GoogleService-Info.plist`
   - confirm it contains `CLIENT_ID` and `REVERSED_CLIENT_ID`
   - add the required Google Sign-In keys to `ios/Runner/Info.plist`

## iOS Google Sign-In keys

After downloading the updated iOS plist from Firebase, add:

- `GIDClientID` using the `CLIENT_ID` value
- `CFBundleURLTypes` using the `REVERSED_CLIENT_ID` value

Without those iOS Google Sign-In keys, Firebase email/password auth works, but
Google Sign-In on iPhone/iPad will not complete.
