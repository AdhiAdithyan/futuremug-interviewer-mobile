# Futuremug Interviewer

Flutter app (Android + iOS) for Futuremug interviewers: sign-up and sign-in,
profile, availability, interviews, reports and earnings.

Stack: Flutter · Riverpod · go_router · Dio · Drift (SQLite) · flutter_secure_storage.

## Getting started

```bash
flutter pub get
flutter run                                   # mock API (default)
flutter run --dart-define=APP_ENV=staging     # staging API
```

### Environments

| `APP_ENV` | Backend | Notes |
| --- | --- | --- |
| `mock` (default) | In-app fixtures | No server needed. A **MOCK** banner shows in the corner. |
| `dev` | Set with `--dart-define=API_BASE_URL=...` | Falls back to staging. |
| `staging` | `https://staging-api.futuremug.com/api/v1` | |
| `prod` | `https://api.futuremug.com/api/v1` | |

### Mock accounts

| Do this | Result |
| --- | --- |
| Sign in with any username and password | Dashboard |
| Sign in as `newuser` | Profile setup (profile not complete) |
| Use the password `wrong` | "Incorrect username or password" |
| Enter OTP `000000` | "That code is not correct"; any other 6 digits pass |
| Choose the username `taken` at sign-up | "That username is already taken" |
| Finish sign-up (or sign in as `newuser`) | 4-step profile setup: personal → professional → skills → documents |

Documents can be uploaded from files, the camera or the photo library, and
opened from the list (in mock mode, opening a document that wasn't uploaded
from this phone shows a sample PDF).

The mock server keeps profile edits and uploaded documents in memory until
the app restarts. Profile setup progress is saved on the device after each
step, so closing the app resumes at the same step.

### API endpoints not in the spec yet

The app already calls these; the mock answers them. The backend team needs
to add them (see the review doc's API gaps):

| Gap | Endpoint |
| --- | --- |
| G1 | `POST /auth/register` |
| G2 | `GET/PUT /evaluator/profile`, `POST /evaluator/profile/documents`, `DELETE /evaluator/profile/documents/{id}`, `GET /evaluator/profile/documents/{id}/download` (file bytes) |
| G7 | New `documentType` values: `DEGREE_CERTIFICATE`, `EXPERIENCE_LETTER`, `PROFILE_PHOTO`, `OTHER` (the spec has only `RESUME_CV`, `CERTIFICATION`, `IDENTITY_PROOF`) |
| — | A token refresh endpoint (today an expired session signs the user out) |

## Project structure

```
lib/
  main.dart                  start-up, error handlers
  app.dart                   MaterialApp + root provider overrides
  core/
    config/                  environments (APP_ENV)
    database/                Drift SQLite vault (drafts, cache)
    network/                 ApiClient, ApiException, interceptors, mock API
    router/                  routes, auth redirect rules, bottom tabs
    security/                secure token storage
    theme/                   colours, theme (Plus Jakarta Sans bundled)
    logging/
  features/<feature>/
    data/                    repositories (API + local)
    domain/                  models and rules
    application/             Riverpod controllers
    presentation/            screens and widgets
  shared/widgets/            reusable UI (buttons, cards, step header)
```

Rules of thumb:

- Screens never call Dio directly: screen → controller → repository → `ApiClient`.
- `ApiClient` throws only `ApiException` subtypes; show `e.message` to the user.
- Route paths live in `AppRoutes`; access rules live in `resolveAuthRedirect`
  (unit-tested).
- Read colours and text styles from `Theme.of(context)`.

## Checks (same as CI)

```bash
dart format lib test
flutter analyze
flutter test
```

CI (`.github/workflows/flutter_ci.yml`) runs these on every push and pull
request, then builds a debug APK against the mock API.

## Android release signing

Create `android/key.properties` (git-ignored):

```
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without it, release builds are signed with the debug key so they still build.
Those builds can't be uploaded to the Play Store.

## Database

`lib/core/database/app_database.dart` uses Drift's SQL API without code
generation. To change the schema, bump `schemaVersion` and add an
`onUpgrade` step.
