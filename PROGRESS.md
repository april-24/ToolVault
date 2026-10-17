# Tool Vault progress

Last updated: 17 October 2026

## Implemented

- Separate Flutter projects for resident mobile/web use (`client_app/`) and the locker kiosk (`locker_site_app/`).
- Resident browsing, search, hourly pricing, tool safety guidance, reservation pass with QR/PIN, and active rental details.
- Kiosk idle screen, pickup verification, original-tool barcode verification on return, and return confirmation flow.
- Multiple sample units for selected tools, with a distinct barcode per asset.
- Shared inventory and rental state in Firebase Firestore; support report text and image attachments use Firestore and Firebase Storage.
- Anonymous Firebase sessions for prototype data access, plus demo resident profiles for the app login screen.
- Chrome occupancy-sensor simulation and Android camera-brightness path where supported.
- Firebase setup rules and Windows-oriented instructions in the root README.
- Startup error screen in both apps to show Firebase initialization/sign-in failures instead of leaving a blank page.

## Current verification

- Dart static analysis reported no issues for either app during the latest source check.
- The full Chrome and Android flows have **not yet been verified end to end** on the project owner's machine.
- Firebase Console setup still needs to be confirmed: Anonymous sign-in enabled, Firestore rules published, and Storage bucket/rules configured.

## Next steps

1. Confirm both apps start in Chrome after Firebase setup; resolve any on-screen startup error.
2. Run a complete reservation → kiosk pickup → barcode return → simulated occupancy → payment walkthrough with both apps open.
3. Confirm Firestore availability updates and support-report attachment upload in the shared Firebase project.
4. Add final tool photos and verify their display in the resident catalog.
5. Review and tighten Firebase rules before sharing beyond the hackathon demo.
6. Connect actual locker hardware and a payment provider only if the project scope advances beyond simulation.

## Notes for teammates

- Use the same Firebase project in both apps so reservation and return state is shared.
- The `server.py` file is from an earlier local API version; the current Flutter apps use Firebase directly.
- QR/barcode samples are documented in `locker_site_app/README.md`.
