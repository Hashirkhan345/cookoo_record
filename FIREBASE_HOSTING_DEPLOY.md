# Firebase Hosting Deployment

This project is already connected to Firebase project `cookoo-record` through
[lib/firebase_options.dart](./lib/firebase_options.dart). The remaining work is
to build the Flutter web app and deploy `build/web` to Firebase Hosting.

## 1. Prerequisites

Install and verify these tools on your machine:

```bash
flutter --version
dart --version
node --version
npm --version
firebase --version
```

If the Firebase CLI is not installed:

```bash
npm install -g firebase-tools
```

## 2. Log in to Firebase

```bash
firebase login
```

Optional:

```bash
firebase projects:list
firebase use cookoo-record
```

This repo already includes [./.firebaserc](./.firebaserc), so `cookoo-record`
is the default project for deploys.

## 3. Verify Firebase app setup

This app already calls Firebase initialization in
[lib/main.dart](./lib/main.dart):

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

The web app configuration is already present in
[lib/firebase_options.dart](./lib/firebase_options.dart), so you do not need to
run `flutterfire configure` again unless the Firebase project changes.

## 4. Firebase Console checks

Open the Firebase Console for project `cookoo-record` and verify:

1. `Build > Hosting` has been opened at least once and `Get started` has been
   completed if this is the first Hosting deploy for the project.
2. `Authentication` is enabled for the providers you use.
3. `Google` sign-in is enabled, because the app uses Firebase Auth Google
   sign-in on web.
4. `Settings > Authorized domains` includes:
   - `localhost`
   - `cookoo-record.web.app`
   - `cookoo-record.firebaseapp.com`
   - your custom domain, if you add one later
5. Firestore is created and your security rules allow the reads/writes this app
   performs.

Without the authorized domain step, Google sign-in can fail after deployment.

## 5. Get dependencies

```bash
flutter pub get
```

## 6. Test locally in web mode

```bash
flutter run -d chrome
```

Confirm:

1. The app loads.
2. Email/password auth works if enabled.
3. Google sign-in popup works.
4. Firestore reads and writes succeed.

## 7. Build the production web app

```bash
flutter build web --release
```

This generates the deployable output in `build/web`.

## 8. Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

Expected Hosting target in this repo:

1. `public` directory: `build/web`
2. SPA rewrite: all routes go to `/index.html`

Those settings are defined in [firebase.json](./firebase.json).

## 9. Open the deployed app

After a successful deploy, Firebase prints URLs similar to:

```text
https://cookoo-record.web.app
https://cookoo-record.firebaseapp.com
```

Open one of those and test the same flows again in production.

## 10. Deploy future updates

For later releases, the cycle is:

```bash
flutter build web --release
firebase deploy --only hosting
```

## Troubleshooting

### Blank page or broken asset paths

Use:

```bash
flutter build web --release
```

Do not manually upload files elsewhere. Firebase Hosting should serve
`build/web` exactly as generated.

### Route refresh returns 404

Make sure the `rewrites` section remains in [firebase.json](./firebase.json).

### Google sign-in fails after deploy

Add the deployed domain under Firebase Authentication authorized domains.

### Firebase project mismatch

Check:

```bash
firebase use
cat .firebaserc
```

### Need to reconnect to another Firebase project

Run:

```bash
flutterfire configure
firebase use --add
```

### Firebase CLI warns about unknown property `flutter`

This repo keeps FlutterFire metadata in [firebase.json](./firebase.json) under
the `flutter` key. The Firebase CLI can warn about that key being unknown while
still using the valid `hosting` section for deploys.
