# TOOL VAULT — Prototype Guide

Tool Vault is a township tool-rental prototype with a Flutter resident app and an HTML/CSS/JavaScript kiosk:

- `client mobile app/` — resident app for browsing and reserving shared tools.
- `kiosk/web/` — browser kiosk for pickup, return, QR scanning, and the live camera preview used to simulate the locker occupancy sensor.

The apps are already configured to use the team's shared Firebase project. For the demo, teammates do **not** need to create their own Firebase project or do Firebase Console setup. Both apps use the same configured project, so rental and inventory changes are shared and persist between runs. The Firebase project owner remains responsible for its settings and access rules.

## Open the project in VS Code

### 1. Install the VS Code extensions

1. Open **Visual Studio Code**.
2. Select the **Extensions** icon on the left, or press **Ctrl+Shift+X**.
3. Search for **Flutter** by Dart Code and select **Install**. VS Code will also install or prompt you to install the **Dart** extension; install it too.
4. Search for **Live Server** by Ritwick Dey and select **Install**. This launches the HTML kiosk in a browser.
5. If VS Code asks to reload, select **Reload**.

> The Flutter extension helps VS Code understand Flutter projects. You still need the Flutter SDK installed on your computer. This project was prepared with Flutter; check your setup in the VS Code terminal with `flutter doctor -v`.

### 2. Open the Hackathon folder

1. In VS Code, select **File → Open Folder…**.
2. Choose the `Hackathon` folder you downloaded or cloned. For the original Windows location, it is `C:\Users\lowli\Downloads\Hackathon`.
3. If VS Code asks whether you trust the authors, choose **Yes, I trust the authors**.
4. In the Explorer panel, confirm that `client mobile app` and `kiosk` appear under the opened folder.

Open the `Hackathon` folder itself, not only one of the app folders, so you can easily access both apps and this guide.

## Run both apps in Chrome

Run the resident Flutter app from a VS Code terminal and open the kiosk with Live Server. Keep both browser tabs open for the shared demo.

### Start the resident app

1. Select **Terminal → New Terminal**.
2. Make sure the terminal starts in the `Hackathon` folder. Then enter:

```powershell
cd "client mobile app"
flutter pub get
flutter run -d chrome
```

Wait for Chrome to open the resident app. Sign in with one of the resident accounts below.

### Start the kiosk site

1. In VS Code, install the **Live Server** extension if it is not already installed.
2. In the Explorer panel, open `kiosk/web/index.html`.
3. Right-click `index.html` and choose **Open with Live Server** (or select **Go Live**).
4. Keep the Live Server tab open alongside the resident app. Do not use `flutter run` for the kiosk; its browser version is now HTML, CSS, and JavaScript.

Use `localhost` for the local demo. Allow Chrome to use the camera when prompted. QR scan uses the browser's built-in decoder where available, with a `jsQR` fallback loaded from jsDelivr (internet required). For a second phone or a hosted demo, use an HTTPS-hosted kiosk link and add its domain to Firebase Authentication's authorized domains; a plain HTTP link to your computer's local IP cannot access the phone's camera.

### Run the resident app on an Android phone instead

Connect the resident's phone with USB debugging enabled, then run `flutter devices` in the `client mobile app` terminal. Use the device ID shown in the list:

```powershell
flutter run -d DEVICE_ID
```

For the simplest examiner walkthrough, run the resident app and kiosk in Chrome as described above.

## Resident demo accounts

Use any of these sample profiles on the resident app's login screen:

| Resident | Email | Password | Unit |
|---|---|---|---|
| Aina Rahman | `aina@toolvault.demo` | `Aina123!` | V-08-12 |
| Jason Tan | `jason@toolvault.demo` | `Jason123!` | V-03-05 |
| Priya Kumar | `priya@toolvault.demo` | `Priya123!` | V-11-02 |

These are prototype resident profiles, not Firebase email/password accounts. Firebase access runs through the shared project's existing anonymous demo sign-in configuration. The kiosk does not need a resident login.

## Pickup and return pass

Each reservation has a pickup PIN and QR and must be collected within 15 minutes. Residents can cancel an uncollected reservation from its details page. After the kiosk verifies pickup, the resident app marks the rental **Borrowed** and starts the timer. Open a borrowed rental from **My Rentals**, then tap **Generate Return Pass** to create a separate return PIN and QR that work for two minutes. The timer keeps running while the pass is active. If it expires, the rental returns to **Borrowed**; when the resident is still viewing the pass, the app returns to My Rentals. The kiosk shows the assigned locker number for that individual tool unit. Its live camera preview simulates the physical occupancy sensor: a sustained dark frame automatically confirms the return.

## Suggested demo walkthrough

1. Sign into the resident app using a sample account.
2. Open a tool, review its safety guidance, and reserve it.
3. Use the reservation QR or PIN at the kiosk to simulate pickup.
4. Open the borrowed rental in **My Rentals**, tap **Generate Return Pass**, then present the new two-minute QR/PIN at the kiosk.
5. Put the tool back in its assigned locker, open the occupancy-camera preview, and cover the camera until it detects a sustained dark frame; the kiosk then completes the return automatically.
6. Return to the resident app to review the rental fee and complete the simulated payment flow.

The shared Firestore data persists between sessions. If a previous demo left tools reserved or borrowed, their availability may reflect that saved state.

## Prototype notes

- The kiosk camera, physical locker, occupancy sensor, and payment are simulations; no physical locker is controlled and no real card is charged.
- The kiosk opens a live browser camera preview; the confirm button simulates the physical occupancy sensor. Camera access requires localhost or HTTPS.
- Firebase is already configured for the shared demo project; no separate Firebase project is needed for a teammate running this repository.
- `server.py` is a legacy local API from an earlier version and is not required to run the current Firebase-connected apps.
- The full progress log is in `PROGRESS.md`.
