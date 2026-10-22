# TOOL VAULT

## Access Links

- **Resident mobile app:** [Open ToolVault](https://toolvault-271d9.web.app)
- **Self-service kiosk:** [Open the kiosk](https://toolvault-271d9-kiosk.web.app)
- **Source code:** [GitHub repository](https://github.com/april-24/ToolVault)
- **Demo login accounts:** [View sample accounts](DemoAccounts.md)

Open the resident app and kiosk in separate browser tabs or devices to show how they work together.

## What Tool Vault Does

Tool Vault is a shared tool-rental service for a township. Residents use the mobile app to find and reserve household tools, then use a self-service kiosk to collect and return them. The system connects each reservation to a locker, tracks rental time and fees, supports in-app payment, and lets residents report damaged tools. It helps residents access tools without needing to buy or store every item themselves.

## How to Open Tool Vault

### Option 1: Open the links

1. Open the [Resident mobile app](https://toolvault-271d9.web.app).
2. Open the [Self-service kiosk](https://toolvault-271d9-kiosk.web.app) in another tab, browser or device.
3. Sign in to the resident app with an account from [DemoAccounts.md](DemoAccounts.md).
4. Allow camera access on the kiosk if you want to demonstrate QR scanning. The kiosk link uses HTTPS, which supports camera access in modern browsers.

### Option 2: Run the apps in VS Code

1. Install **Visual Studio Code**, the **Flutter SDK**, and **Git**.
2. In VS Code Extensions, install **Flutter** by Dart Code (install the Dart extension if prompted) and **Live Server** by Ritwick Dey.
3. Clone or download the [GitHub repository](https://github.com/april-24/ToolVault), then open the downloaded `ToolVault` project folder in VS Code.
4. Open **Terminal → New Terminal** in VS Code and run the resident app:

   ```bash
   cd client_app
   flutter pub get
   flutter run -d chrome
   ```

5. In VS Code Explorer, open `kiosk/web/index.html`, right-click it and select **Open with Live Server**. Keep the resident app and kiosk open at the same time.
6. Use the demo account listed in [DemoAccounts.md](DemoAccounts.md) to sign in. The project already contains its shared Firebase configuration; teammates do not need to create a separate Firebase project.

## Demo Steps

1. Open the resident app and kiosk, then sign in with a sample resident account.
2. In the app, browse the tools, open one, review its safety guidance and reserve it.
3. Show the pickup QR code or PIN from the app and enter or scan it at the kiosk. The kiosk displays the assigned locker and confirms pickup.
4. In **My Rentals**, open the borrowed tool and generate a return pass. Use its temporary QR code or PIN at the kiosk to open the assigned locker for return.
5. Follow the kiosk's return-sensor simulation to confirm the tool is back. The app then shows the completed rental and final fee.
6. Complete the payment flow in the app. You can also demonstrate sending a damage report from the Help section.

The locker, return sensor and payment are demonstrated through the software prototype; they are not connected to physical locker hardware or real card charges.
