# ToolVault 3D Township — V2 Phone, Carryable Props and Sound

**REPLACE THE OLD `township_3d` FOLDER IN FULL.** Do not replace or edit `client_app/` or `locker_site_app/`.

This version preserves the original low-poly township and changes the interaction:

- The house is scenery only; it has NO booking interaction.
- **Press `E` anywhere EXCEPT close to ToolVault** to pull out the cartoon resident's phone and open the REAL Flutter Resident App on port 5000. **Press `P` anywhere** as a phone shortcut.
- **Press `E` next to the ToolVault locker** to open the REAL Flutter Locker App on port 5001.
- The 3D character can carry **15 distinct procedural low-poly tool models** matching the existing rental catalogue. A ladder looks like a ladder, a drill like a drill, etc.
- Background music is an ORIGINAL, royalty-free synth loop created for this demonstration. It and the five short sound effects are bundled locally as WAV files.
- Tori assistant continues recommending tools for household problems, and highlights the matching tool in the pickup selector. Default recommendations work without an API key.

## Folder layout

```
ToolVault-main/
├── client_app/              original Flutter Resident App — do not replace
├── locker_site_app/         original Flutter Locker Kiosk — do not replace
├── township_3d/            THIS NEW REPLACEMENT FOLDER
│   ├── index.html
│   ├── styles.css
│   ├── app.js               world, game controls and visual journey
│   ├── tool_models.js       distinct 3D models for all 15 tools
│   ├── catalog.js           names and rates from original Flutter catalogue
│   ├── assistant.js         local household-problem matching
│   ├── audio/               original background music and sound effects
│   ├── serve.dart           local Dart web server, included with Flutter
│   ├── server.py            optional Python web server
│   ├── START_3D.bat         double-click Dart server shortcut
│   └── README.md
└── README.md
```

## Start all three (Windows VS Code)

Open **three terminals**, from your `ToolVault-main` directory (or use full paths).

**Terminal 1 — Resident App:**
```powershell
cd .\client_app
flutter pub get
flutter run -d chrome --web-port=5000
```

**Terminal 2 — Locker Kiosk:**
```powershell
cd .\locker_site_app
flutter pub get
flutter run -d chrome --web-port=5001
```

**Terminal 3 — 3D game:**
```powershell
cd .\township_3d
dart run serve.dart
```

Open **http://localhost:5500** in Chrome. Or double-click `START_3D.bat` from the `township_3d` folder; it starts the same Dart server. Alternatively, if Python is installed: `python server.py`.

**Internet required:** Three.js currently loads from the jsDelivr or unpkg CDN, so an internet connection is required for the 3D view. Music and sound files are served from the local `audio/` folder.

## Controls

| Control | What it does |
| --- | --- |
| W, A, S, D or arrow keys | Walk the cartoon resident around the township |
| **E**, anywhere away from locker | Take out the phone and open **real resident booking UI** |
| **E**, near locker | Open **real pickup / return kiosk UI** |
| **P** | Open the phone regardless of current location |
| G | Show the 15-item tool gallery |
| Esc | Close open panel |
| Tool gallery | See pictograms and names; choose corresponding 3D prop for the pickup demo |
| Music ON/OFF | Starts/pauses the included original music; Chrome requires a click before audio can play |
| Music volume | Adjusts the background music |
| Effects ON/OFF | Mutes / unmutes walking, opening, pickup and return effects |

## Demonstrate the whole process with a ladder

1. In the 3D game, ask Tori: **"I need a ladder to reach my curtains."** Tori recommends the **4-step safety ladder** and highlights it as the current demo tool.
2. While standing **anywhere away from the locker** press **E**. The resident pulls out a 3D phone, and the real Flutter booking website opens within a phone-shaped panel. Login, reserve the ladder and read your **real pickup PIN**.
3. Click **"Booking completed (demo)"**, close the phone, and walk toward the station with **WASD**.
4. Press **E** near ToolVault. In the REAL Flutter kiosk screen, **enter the real pickup PIN and complete the pickup simulation**.
5. Beneath the kiosk screen, choose **4-step safety ladder** if not already highlighted and click **"Show collected item in 3D"**. The kiosk closes and the cartoon resident visibly carries a long, detailed low-poly ladder while walking.
6. Walk around or back toward the house. The ladder remains attached to the resident while they move.
7. Go back to the locker, press **E**, and use the **REAL Flutter kiosk** to process the tool return (the existing app asks for the correct tool barcode and simulates locker sensing).
8. After successful actual kiosk return, click **"Show returned item in 3D"** in the demo controls. The 3D ladder disappears from the resident's hands; the mission shows as complete. Check rental status/payment in the Resident App.

You can substitute any of the other 14 tool models for the ladder, by choosing the item in the locker selector. A gallery of all 15 catalogue items can be opened from the top bar or by pressing **G**.

## IMPORTANT: Real app workflow versus visual demonstration

**The 3D game does not automatically observe booking or return data from Firebase.** This avoids making unsafe assumptions about your existing Flutter authentication/Firestore rules. The buttons marked "(demo)" are a **manual visual confirmation only**: they change what the character holds and what the game's mission list displays. They do NOT book, collect, pay for or return a tool in Firebase. Always do the REAL booking/pickup/return operations in the Flutter interfaces too. The 3D visuals should only be synchronized manually *after* the corresponding kiosk action finishes.

A future extension could add verified Firebase rental-state subscriptions, but it requires securely adding integration code to your Flutter apps or a trusted backend. **No changes to the existing Flutter apps are required for this add-on.**

## AI assistant

- Built-in mode is a keyword recommender for 15 known products; it is **not a generative AI model**. It works without a key and can suggest a matching gallery/3D demo item.
- Optional live AI is supported by `serve.dart` / `server.py`, set securely using `OPENAI_API_KEY` in your *local terminal only*, never inside public JS/HTML or GitHub. API calls are billed separately from ChatGPT subscriptions.
- Tori cannot reserve tools and does not know actual real-time inventory. Check that in the resident app.

## Notes for demo reliability

- The original Flutter apps must run on ports **5000** and **5001**. The 3D game runs on **5500**.
- If the Flutter website inside the phone or kiosk panel is blank, ensure the respective Flutter server is running, and click **Open separately**. Cross-origin embedding can be limited by browser and app configurations.
- Never use real payment details. The original project payment, locker-open and locker-sensor steps are simulated.
- The 3D equipment models are illustrative, not certified safety or dimensional representations. Tool suitability should follow actual manufacturer instructions.
- If the game shows **"3D engine could not load"**, check internet access. If the page stays blank, try Chrome hardware acceleration.

## Editing files

- **Game mechanics & interactions:** `app.js`
- **Visual styles & phone / gallery panels:** `styles.css`
- **15 3D rental item shapes:** `tool_models.js`
- **Catalogue names / demo prices:** `catalog.js`
- **Built-in assistant recommendations:** `assistant.js`
- **Audio files:** `audio/` (all original, safe to use in your project)
- **App URLs:** `APP_URLS` constant at the top of `app.js`
