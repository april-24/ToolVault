# Tool Vault — Locker Site kiosk

This is the kiosk app for the vault device. It shares Firestore inventory and rental state with the resident app.

## Firebase and run setup

From this folder, run:

```powershell
flutter pub get
dart pub global run flutterfire_cli:flutterfire configure --project=toolvault-271d9
```

Select **Android** and **Web** to create this kiosk app's Firebase configuration. In Firebase Console, enable Anonymous sign-in, publish the root `firestore.rules`, and create Cloud Storage with the root `storage.rules` (the resident app uses Storage for damage-report media). See `../README.md` for the full steps.

Run the kiosk:

```powershell
flutter run -d chrome
```

The kiosk opens on an idle welcome page. A resident reserves in the app, then picks up with the linked QR/PIN. For returns, choose **RETURN**, enter or scan the original item's barcode, and use the occupancy sensor panel below the return entry. Android uses camera brightness when available. On Web, press **SIMULATE DARK SENSOR READING** to represent the locker closing; this avoids the unsupported browser image-stream assertion. No full-screen camera page is opened.

The camera and lock are simulations; this app does not operate physical locker hardware.

## Sample tool barcodes

Enter or scan the barcode printed beside the physical tool. Selected common tools have multiple assets, each with its own barcode. QR images below encode the exact displayed value.

| Tool | Barcode value(s) | QR sample |
|---|---|---|
| 4-step safety ladder (2 units) | <code>TVITEM&#124;VILLAS01&#124;step_ladder&#124;ASSET01</code><br><code>TVITEM&#124;VILLAS01&#124;step_ladder&#124;ASSET02</code> | ![ladder barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cstep_ladder%7CASSET01&size=110) ![ladder barcode 2](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cstep_ladder%7CASSET02&size=110) |
| Cordless drill-driver kit (3 units) | <code>TVITEM&#124;VILLAS01&#124;cordless_drill&#124;ASSET01</code><br><code>TVITEM&#124;VILLAS01&#124;cordless_drill&#124;ASSET02</code><br><code>TVITEM&#124;VILLAS01&#124;cordless_drill&#124;ASSET03</code> | ![drill-driver barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Ccordless_drill%7CASSET01&size=110) ![drill-driver barcode 2](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Ccordless_drill%7CASSET02&size=110) ![drill-driver barcode 3](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Ccordless_drill%7CASSET03&size=110) |
| Wet & dry vacuum (2 units) | <code>TVITEM&#124;VILLAS01&#124;wet_dry_vacuum&#124;ASSET01</code><br><code>TVITEM&#124;VILLAS01&#124;wet_dry_vacuum&#124;ASSET02</code> | ![vacuum barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cwet_dry_vacuum%7CASSET01&size=110) ![vacuum barcode 2](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cwet_dry_vacuum%7CASSET02&size=110) |
| Carpet & upholstery cleaner | <code>TVITEM&#124;VILLAS01&#124;carpet_cleaner&#124;ASSET01</code> | ![carpet cleaner barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Ccarpet_cleaner%7CASSET01&size=110) |
| Adjustable pressure washer | <code>TVITEM&#124;VILLAS01&#124;pressure_washer&#124;ASSET01</code> | ![pressure washer barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cpressure_washer%7CASSET01&size=110) |
| Household steam cleaner | <code>TVITEM&#124;VILLAS01&#124;steam_cleaner&#124;ASSET01</code> | ![steam cleaner barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Csteam_cleaner%7CASSET01&size=110) |
| Folding hand truck (2 units) | <code>TVITEM&#124;VILLAS01&#124;hand_truck&#124;ASSET01</code><br><code>TVITEM&#124;VILLAS01&#124;hand_truck&#124;ASSET02</code> | ![hand truck barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Chand_truck%7CASSET01&size=110) ![hand truck barcode 2](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Chand_truck%7CASSET02&size=110) |
| Furniture moving kit | <code>TVITEM&#124;VILLAS01&#124;furniture_kit&#124;ASSET01</code> | ![furniture kit barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cfurniture_kit%7CASSET01&size=110) |
| Laser distance measurer | <code>TVITEM&#124;VILLAS01&#124;laser_measure&#124;ASSET01</code> | ![laser measure barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Claser_measure%7CASSET01&size=110) |
| Self-leveling laser level | <code>TVITEM&#124;VILLAS01&#124;laser_level&#124;ASSET01</code> | ![laser level barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Claser_level%7CASSET01&size=110) |
| Wall stud & wire detector | <code>TVITEM&#124;VILLAS01&#124;stud_finder&#124;ASSET01</code> | ![stud finder barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cstud_finder%7CASSET01&size=110) |
| Folding workbench | <code>TVITEM&#124;VILLAS01&#124;workbench&#124;ASSET01</code> | ![workbench barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cworkbench%7CASSET01&size=110) |
| Manual drain auger | <code>TVITEM&#124;VILLAS01&#124;drain_auger&#124;ASSET01</code> | ![drain auger barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cdrain_auger%7CASSET01&size=110) |
| Portable dehumidifier | <code>TVITEM&#124;VILLAS01&#124;dehumidifier&#124;ASSET01</code> | ![dehumidifier barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cdehumidifier%7CASSET01&size=110) |
| Ground-reach window cleaning kit | <code>TVITEM&#124;VILLAS01&#124;window_kit&#124;ASSET01</code> | ![window kit barcode](https://quickchart.io/qr?text=TVITEM%7CVILLAS01%7Cwindow_kit%7CASSET01&size=110) |

