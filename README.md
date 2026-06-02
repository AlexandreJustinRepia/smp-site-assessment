# SMP Site Assessment

A Flutter field data collection app for government Site Monitoring Platform (SMP) assessments at Biak-Na-Bato National Park (BNBNP). The app is intended for authorized government personnel only and supports authenticated access, offline-first assessment capture, local SQLite storage, Firestore sync, role-based user approval, and PDF report export.

## Intended Use

This application is for official government assessment workflows only. Access should be limited to approved personnel, and all accounts must be reviewed before users can enter the main app.

## Current Features

- Email/password sign-in and account registration through Firebase Auth.
- Admin approval workflow for newly registered users.
- Role-based access for viewers, editors, access managers, and admins.
- Offline-first assessment creation, editing, listing, searching, and deletion using SQLite.
- Manual and background Firestore sync for assessment records.
- Pending delete queue so offline deletes are pushed when connectivity returns.
- Paginated assessment list with search across grid, centroid, location, coordinates, team members, classification fields, threats, and restoration fields.
- Assessment detail view with full survey data and audit information.
- PDF report preview, print, share, or save from an assessment detail page.
- User profile screen for name updates and password changes.
- Cached user access so approved users can keep using the app when offline.
- Portrait-only mobile/tablet experience with Android, iOS, web, desktop runner scaffolds.

## Assessment Data Captured

Each assessment records:

- Survey information: grid number, centroid number, elevation, date, location, target coordinates, actual coordinates, and team members.
- Land cover or existing land use.
- Tree crown cover.
- Forest condition.
- Forest litter ground cover and average depth.
- Threats.
- Inventory rows for regenerants and trees, including species, DBH, merchantable height, total height, and remarks.
- Recommended restoration approaches.
- Creator UID and email for audit context.

## Roles and Permissions

Access is controlled by Firebase Auth, Firestore user documents, and `firestore.rules`.

| Role | Read assessments | Create/Edit assessments | Delete assessments | Manage users |
| --- | --- | --- | --- | --- |
| `viewer` | Yes | No | No | No |
| `editor` | Yes | Yes | No | No |
| `access_manager` | Yes | Yes | No | Yes, except protected admin users and admin role assignment |
| `admin` | Yes | Yes | Yes | Yes, except protected admin users |

New accounts are created as unapproved `viewer` users. An admin or access manager must approve them before they can enter the main app.

## Data and Sync

- Local records are stored in `site_assessments.db` through `sqflite`.
- Remote records are stored in the Firestore `assessments` collection.
- The local `firestoreId` links a SQLite row to its Firestore document.
- `updatedAt` is used to keep the newer copy when syncing local and remote records.
- Inventory rows are stored locally as JSON and remotely as a Firestore list.
- Sync runs on app startup when Firebase and connectivity are available, and can also be triggered from the list screen.
- Firestore writes fail silently in offline paths so field work can continue without blocking the UI.

## Firebase Setup

This project expects Firebase configuration files to be present:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Platform Firebase configuration as needed for iOS, web, macOS, Windows, or Linux builds.

Required Firebase products:

- Firebase Authentication with Email/Password enabled.
- Cloud Firestore.

Deploy Firestore rules with:

```sh
firebase deploy --only firestore:rules
```

To bootstrap the first admin, create or update a document in Firestore at `users/{uid}` for the Firebase Auth user:

```json
{
  "name": "Admin Name",
  "email": "admin@example.com",
  "role": "admin",
  "approved": true
}
```

## Getting Started

Install dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

Run static analysis:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

Build an Android APK:

```sh
flutter build apk
```

## Project Structure

- `lib/main.dart` - app entry point and theme.
- `lib/screens/` - authentication gate, list, form, detail, profile, and user management screens.
- `lib/screens/form_sections/` - reusable assessment form sections.
- `lib/models/assessment.dart` - assessment and inventory row models.
- `lib/db/database_helper.dart` - SQLite schema, CRUD, cached access, and background sync helpers.
- `lib/services/` - Firestore, sync, and user access services.
- `lib/widgets/` - shared UI widgets.
- `firestore.rules` - Firestore security rules for assessment and user access.
- `firebase.json` - Firebase rules deployment configuration.
