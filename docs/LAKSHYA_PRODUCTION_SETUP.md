# Lakshya production setup

The public website remains at `https://www.lakshyaaerotech.com`. The mobile
backend should be deployed as an always-running service at
`https://api.lakshyaaerotech.com` because it maintains Firestore listeners and
a scheduled coupon check in addition to serving HTTP requests.

## Confirmed application identity

- Android application ID: `com.lakshyaaerotech.app`
- iOS bundle ID: `com.lakshyaaerotech.app`
- Firebase project: `lakshya-aerotech`
- Firebase Storage bucket: `lakshya-aerotech.firebasestorage.app`
- Mobile API base URL: `https://api.lakshyaaerotech.com/api`
- Backend health URL: `https://api.lakshyaaerotech.com/health`
- PhonePe callback: `https://api.lakshyaaerotech.com/api/payment/webhook`

## Recommended backend deployment

Deploy `backend/Dockerfile` to a long-running container service. For Google
Cloud Run, use the Firebase project's Google Cloud project, a dedicated runtime
service account, at least one minimum instance, and always-allocated CPU so the
Firestore listeners and scheduler continue running between HTTP requests.

Set these non-secret production variables:

```text
NODE_ENV=production
PORT=8080
CORS_ALLOWED_ORIGINS=https://www.lakshyaaerotech.com,https://lakshyaaerotech.com
ENABLE_PAYMENT_MOCKS=false
ENFORCE_APP_CHECK=true
BOOKING_RATE_PER_ACRE=800
FIREBASE_USE_APPLICATION_DEFAULT=true
FIREBASE_PROJECT_ID=lakshya-aerotech
FIREBASE_STORAGE_BUCKET=lakshya-aerotech.firebasestorage.app
PHONEPE_CALLBACK_URL=https://api.lakshyaaerotech.com/api/payment/webhook
```

Store the PhonePe merchant ID, salt key, salt index, and production base URL in
the hosting platform's secret manager. Do not place them in GitHub, `.env`
files, build logs, or chat messages. When Application Default Credentials are
enabled, grant the Cloud Run runtime service account only the Firebase,
Firestore, Storage, Messaging, and App Check permissions the backend needs.

After deployment:

1. Map `api.lakshyaaerotech.com` to the backend service in DNS.
2. Confirm the health URL returns HTTP 200 JSON.
3. Register the exact PhonePe callback URL.
4. Deploy `firestore.rules`, `firestore.indexes.json`, and `storage.rules`.
5. Enable Firebase App Check only after Play Integrity tokens have been tested
   through a Google Play internal-testing build.

## Public website URLs

The Play Store and App Store records should use:

- Privacy policy: `https://www.lakshyaaerotech.com/privacy-policy`
- Account deletion: `https://www.lakshyaaerotech.com/account-deletion`
- Support: `https://www.lakshyaaerotech.com/support`

These pages must be deployed from the website repository before a store review.

## Android release workflow

The manual `Android Production Release` workflow builds a Play Store AAB,
device-testing APKs, and obfuscation symbols using the production API URL. Add
the following GitHub Actions secrets to a protected `production` environment:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD
ANDROID_KEY_ALIAS
```

Set the optional environment variable `BOOKING_RATE_PER_ACRE` to `800` unless
the production server uses another rate. The server remains authoritative for
the final booking price.
