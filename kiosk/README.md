# Tool Vault — Locker Site kiosk

The kiosk is a browser-based HTML/CSS/JavaScript page in `web/`. It shares Firebase Authentication and Cloud Firestore with the resident app. Pickup uses the reservation QR/PIN; return uses a fresh, separate QR/PIN generated from the borrowed rental in My Rentals.

## Open the kiosk in VS Code

1. Open the `Hackathon` folder in VS Code.
2. Install the **Live Server** extension by Ritwick Dey if needed.
3. In Explorer, open `kiosk/web/index.html`.
4. Right-click the file and choose **Open with Live Server** (or click **Go Live**).
5. Keep the Live Server browser tab open while you run the resident app separately with Flutter.

There is no npm install or Flutter command required to launch the current kiosk. It imports Firebase's modular JavaScript SDK from Google's CDN. Internet access is needed for the Firebase SDK and shared Firestore data.

## Camera and sensor simulation

- Select **PICK UP** and scan the pickup QR or enter its six-digit PIN. The kiosk confirms pickup, starts the rental timer, and displays the assigned locker number with safety reminders.
- Reservations expire if not collected within 15 minutes. Residents can cancel an uncollected reservation from its details page.
- To return, open the borrowed rental in **My Rentals** and tap **Generate Return Pass**. This creates a separate QR/PIN valid for two minutes. Select **RETURN** and use that pass at the kiosk.
- The kiosk displays the exact locker assigned to that individual tool unit for both pickup and return. The rental timer continues while a return pass is active. If the pass expires before the return is confirmed, the rental returns to **Borrowed** and the resident can generate another pass.
- Select **OPEN OCCUPANCY SENSOR CAMERA** to request a live camera preview. Cover the camera until the image stays dark; after a sustained dark reading, the kiosk automatically confirms the return and closes the camera panel.
- If Chrome asks, allow camera access. Camera access works on `localhost` for development and requires HTTPS when hosted. To open the kiosk from a second phone, use an HTTPS-hosted link; plain HTTP to the laptop's local IP cannot access the phone camera. If camera access is denied, allow it in the browser's site settings and reopen the sensor panel. If QR decoding is unavailable, enter the PIN shown in the resident app.
- QR scanning uses the browser's `BarcodeDetector` when supported and a `jsQR` browser fallback otherwise. The kiosk needs internet access to load the fallback scanner library. If the camera is blocked, enter the PIN shown in the resident app.

## Firebase notes

The kiosk uses the shared project's existing web app configuration in `web/app.js`; no teammate-specific Firebase project setup is required. Anonymous sign-in must be enabled in Firebase Authentication, and the kiosk host must be listed under **Authentication → Settings → Authorized domains**. `localhost` is normally available for local development.

The displayed camera is not a physical occupancy sensor and the web app does not actuate a real locker. The return confirmation button represents that hardware event for the prototype.
