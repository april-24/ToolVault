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

Choose an Android device instead of Chrome to run on a phone. Tap **Ask Tool Finder** at the top-left of the Tools page to open the local prototype chat and get keyword-based tool suggestions. Reserve a tool, then use its pickup QR/PIN at the kiosk. Once pickup is verified, the app changes to **Borrowed Successfully** and starts the timer. Open the borrowed row in **My Rentals** to create a separate return QR/PIN, valid for two minutes. If it expires, reopen the rental to generate another pass; the rental timer keeps running. After the kiosk confirms return, choose a payment method; card payment is simulated and accepts only `4242 4242 4242 4242`, any future expiry, and any three-digit CVV.

The selected tool page shows step-by-step safety points. The Help page keeps answers left-aligned and places Contact Support below the FAQs. Support reports preview selected photos before sending; sending uploads attachments and returns to Help & Terms.
