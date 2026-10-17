# Tool Vault — resident app

The resident Flutter app shares inventory and rental state with the Locker Site app through Firebase Firestore. Report comments and attachments are stored in Firestore and Firebase Storage.

## Demo resident accounts

| Resident | Email | Password | Unit |
|---|---|---|---|
| Aina Rahman | `aina@toolvault.demo` | `Aina123!` | V-08-12 |
| Jason Tan | `jason@toolvault.demo` | `Jason123!` | V-03-05 |
| Priya Kumar | `priya@toolvault.demo` | `Priya123!` | V-11-02 |

Enter one of these accounts on the login screen. The quick-fill account list was removed from the app.

## Firebase setup

From this folder, run:

```powershell
flutter pub get
dart pub global run flutterfire_cli:flutterfire configure --project=toolvault-271d9
```

Select Android and Web. In Firebase Console, enable **Anonymous** under Authentication sign-in methods, publish `../firestore.rules` under Firestore Rules, and set up Cloud Storage with `../storage.rules`. The one-time setup is also described in `../README.md`.

## Run

```powershell
flutter run -d chrome
```

Choose an Android device instead of Chrome to run on a phone. Reserve a tool, then show its QR/PIN at the kiosk. The timer begins after the kiosk verifies pickup. Tap a reserved or borrowed row in **My rentals** to reopen the pass/details. After the kiosk confirms return, choose a payment method; card payment is simulated and accepts only `4242 4242 4242 4242`, any future expiry, and any three-digit CVV.

The safe-use guidance appears on the selected tool's reservation page. Support reports preview selected photos before sending; sending uploads attachments and returns to Help & Terms.
