# Production release runbook

The repository contains production security controls, but store publication
requires environment-specific credentials, legal declarations, and real-device
acceptance testing. Do not publish using mock credentials or local endpoints.

## Required production inputs

- Production Firebase Android and iOS apps for `com.lakshyaaerotech.app`.
- `android/app/google-services.json` and the untracked
  `ios/Runner/GoogleService-Info.plist` from the production Firebase project.
- An HTTPS backend domain, production Firebase Admin credentials, PhonePe
  credentials, and an exact HTTPS webhook URL.
- Android Play App Signing enrollment and a private upload keystore.
- Apple Developer team, App Store Connect app record, distribution signing,
  APNs and App Attest capabilities, and provisioning profiles.
- Public privacy-policy, support, and account-deletion URLs.
- Final screenshots, descriptions, categories, age rating, reviewer accounts,
  data-safety/app-privacy answers, and applicable legal approvals.

## Backend configuration

Set all values through the deployment platform's secret manager:

```text
NODE_ENV=production
PORT=3000
CORS_ALLOWED_ORIGINS=https://www.lakshyaaerotech.com,https://lakshyaaerotech.com
ENABLE_PAYMENT_MOCKS=false
ENFORCE_APP_CHECK=true
BOOKING_RATE_PER_ACRE=800
PHONEPE_MERCHANT_ID=...
PHONEPE_SALT_KEY=...
PHONEPE_SALT_INDEX=...
PHONEPE_BASE_URL=https://...
PHONEPE_CALLBACK_URL=https://api.lakshyaaerotech.com/api/payment/webhook
FIREBASE_USE_APPLICATION_DEFAULT=true
FIREBASE_PROJECT_ID=lakshya-aerotech
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
FIREBASE_STORAGE_BUCKET=lakshya-aerotech.firebasestorage.app
```

Deploy Firebase authorization before enabling production clients:

```bash
firebase use <production-project-id>
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Register the Android app with Play Integrity and the iOS app with App Attest
(DeviceCheck fallback) in Firebase App Check. Validate production tokens in a
staging environment before enabling App Check enforcement for Firebase
products and the backend. Add the Play App Signing SHA-256 certificate to the
Firebase Android app and enable the App Attest capability for the Apple App ID
and provisioning profile.

## Android release

Google Play submissions after August 31, 2026 must target API level 36. This
project explicitly targets API 36. Create the upload keystore outside Git,
copy `android/key.properties.example` to the ignored `android/key.properties`,
and fill in the real values.

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.lakshyaaerotech.com/api \
  --dart-define=BOOKING_RATE_PER_ACRE=800 \
  --obfuscate --split-debug-info=build/symbols/android
```

Upload `build/app/outputs/bundle/release/app-release.aab` to an internal testing
track first. Preserve the symbol files for crash de-obfuscation.

## iOS release

Add the production `GoogleService-Info.plist` to the Runner target, select the
Apple development team, confirm Push Notifications and Background Modes, then
build on macOS:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.lakshyaaerotech.com/api \
  --dart-define=BOOKING_RATE_PER_ACRE=800 \
  --obfuscate --split-debug-info=build/symbols/ios
```

Validate the archive in Xcode before uploading to App Store Connect.

## Mandatory acceptance tests

- New farmer, retailer, and external-pilot registration and approval.
- Employee invitation, password setup, suspension, and role restrictions.
- Farm creation and map permissions on supported Android and iOS versions.
- Booking, assignment, mission tracking, cash collection, and issue handling.
- Successful, failed, cancelled, retried, duplicated, and delayed payment
  callbacks using the gateway's official sandbox before production tests.
- Foreground, background, terminated-state, and tapped notifications.
- Account deletion, anonymization, and deletion-request web flow.
- Offline, expired-token, permission-denied, slow-network, and server-failure
  behavior.

## Store disclosures

The app processes contact information, account identifiers, precise location,
farm/address data, verification documents, payment status, and user content.
Reconcile this inventory with every production SDK and backend process when
completing Google Play Data safety and Apple App Privacy. The templates under
`docs/` are operational starting points, not legal advice.
