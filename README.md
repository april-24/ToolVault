# ToolVault

Access to PPT: https://1drv.ms/p/c/690f335b24831557/IQBxLst4PwjSQZXm3phwIhHFAU1CyOJ1lEMzjB-K0kU-wf8?e=HecRrk
=======
# Tool Vault

Tool Vault is a township tool-rental prototype with two Flutter apps. Residents reserve shared household tools in the mobile app; a separate kiosk app simulates pickup and return at an unattended locker. Both apps use Firebase Firestore for shared inventory and rental data.

## Repository contents

Upload the **whole `Hackathon` folder** to GitHub, with these files and folders at the repository root:

```text
Hackathon/
├── client_app/          Resident Flutter app
├── locker_site_app/     Locker/kiosk Flutter app
├── firestore.rules      Demo Firestore security rules
├── storage.rules        Demo Storage rules for report attachments
├── README.md            Setup and usage guide
├── PROGRESS.md          Project progress and next steps
├── .gitignore
└── server.py            Legacy local API; current apps use Firebase
```

Keep each app's `pubspec.yaml`, `pubspec.lock`, `lib/`, `android/`, `web/`, and `README.md`. Firebase client configuration files (`lib/firebase_options.dart`, `android/app/google-services.json`, and `firebase.json`) are included so the apps point to the demo Firebase project. These identify the Firebase project; they are not server credentials. Access is controlled by Firebase rules.

Do **not** commit generated `build/` or `.dart_tool/` folders, local Android SDK paths (`android/local.properties`), signing keys, passwords, or Firebase CLI login credentials. The root and app `.gitignore` files exclude generated and local files.

## Requirements

- Flutter SDK (stable) with Chrome or an Android device available.
- A Google account with access to the Firebase project `toolvault-271d9` for the shared demo backend.
- Firebase CLI and FlutterFire CLI for Firebase setup or when changing the Firebase project.

Check Flutter setup with:

```powershell
flutter doctor -v
```

On Windows, if PowerShell blocks `npm.ps1`, use `npm.cmd` instead of `npm` when installing Firebase CLI:

```powershell
npm.cmd install --global firebase-tools
dart pub global activate flutterfire_cli
```

Sign into the Firebase account that owns the project and verify the project is visible:

```powershell
firebase.cmd login
firebase.cmd projects:list
```

If the project list is empty, check `firebase.cmd login:list` and sign in with the correct Google account. Do not create a second project for this repository.

## One-time Firebase Console setup

In Firebase Console for `toolvault-271d9`:

1. Open **Authentication → Sign-in method** and enable **Anonymous**. The demo profile login in the resident app is separate from Firebase Authentication; both apps use anonymous Firebase sessions to access the shared prototype data.
2. Open **Firestore Database → Rules**, paste the root `firestore.rules`, and publish.
3. Create the default **Cloud Storage** bucket. Open its **Rules**, paste the root `storage.rules`, and publish. Storage is used for resident support-report attachments.

The included rules are intentionally broad for a hackathon demo: any signed-in anonymous session can read and write the prototype data. Do not use these rules with real residents or physical lockers. Production use needs authenticated resident identities, role-based authorization, validated rental transitions, and appropriate Firebase security controls.

## Configure and run

Open two PowerShell terminals so the resident app and kiosk can run at the same time. Run `flutter pub get` from each app folder.

### Resident app

```powershell
cd .\client_app
flutter pub get
dart pub global run flutterfire_cli:flutterfire configure --project=toolvault-271d9
flutter run -d chrome
```

In FlutterFire's platform selector, choose **Android** and **Web**. If prompted to register an app, use the existing Firebase project. When configuration finishes, run `flutter run -d chrome` in this folder.

### Locker kiosk app

In a second terminal:

```powershell
cd .\locker_site_app
flutter pub get
dart pub global run flutterfire_cli:flutterfire configure --project=toolvault-271d9
flutter run -d chrome
```

Choose **Android** and **Web** here too. If both apps are already configured for this project, `flutterfire configure` can be skipped. For a phone, use `flutter devices` to find its device ID and run `flutter run -d <device-id>` from the relevant app folder.

## Demo workflow

1. Sign in to the resident app with a sample account below and reserve an available tool.
2. Show the reservation's QR code or PIN at the kiosk to simulate pickup. The rental timer starts after pickup is verified.
3. To return the tool, choose **Return** at the kiosk and scan or type that unit's barcode. The sample barcode values and QR codes are in [`locker_site_app/README.md`](locker_site_app/README.md).
4. On Chrome, press **Simulate dark sensor reading** in the return panel to simulate the locker closing. On Android, the kiosk can use camera brightness when available.
5. Review the charge and complete the app's simulated payment step.

The inventory documents are seeded into Firestore the first time the resident app opens. Both apps must use the same Firebase project to share reservations and item status. `server.py` is a retained legacy local API and does not need to be started.

### Resident demo accounts

| Name | Email | Password | Unit |
|---|---|---|---|
| Aina Rahman | `aina@toolvault.demo` | `Aina123!` | V-08-12 |
| Jason Tan | `jason@toolvault.demo` | `Jason123!` | V-03-05 |
| Priya Kumar | `priya@toolvault.demo` | `Priya123!` | V-11-02 |

These are prototype profiles handled by the app, not Firebase email/password accounts. The card payment is also simulated; the demo card number is `4242 4242 4242 4242`, with any future expiry and any three-digit CVV. Never enter real card details.

## Current limitations

- The kiosk and lock are simulations; the software does not control locker hardware.
- Chrome uses a sensor simulation for occupancy because the current browser camera plugin cannot provide the brightness frame stream. Camera brightness may be used on Android.
- Payment is a UI simulation and does not charge a card.
- Firebase demo rules permit broad access to signed-in users. Replace them before production.
- Tool images can be added under `client_app/assets/tools/` and referenced by the resident app.

See [`PROGRESS.md`](PROGRESS.md) for the current implementation status and remaining work.
