"""Local LAN demo API for the Tool Vault resident and kiosk Flutter apps."""
from __future__ import annotations

import json
import math
import secrets
import threading
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

TOOLS = [
    ("step_ladder", "4-step safety ladder", 2.00),
    ("cordless_drill", "Cordless drill-driver kit", 3.00),
    ("wet_dry_vacuum", "Wet & dry vacuum", 4.00),
    ("carpet_cleaner", "Carpet & upholstery cleaner", 5.00),
    ("pressure_washer", "Adjustable pressure washer", 5.00),
    ("steam_cleaner", "Household steam cleaner", 4.00),
    ("hand_truck", "Folding hand truck", 2.00),
    ("furniture_kit", "Furniture moving kit", 2.00),
    ("laser_measure", "Laser distance measurer", 2.00),
    ("laser_level", "Self-leveling laser level", 3.00),
    ("stud_finder", "Wall stud & wire detector", 2.00),
    ("workbench", "Folding workbench", 2.00),
    ("drain_auger", "Manual drain auger", 2.00),
    ("dehumidifier", "Portable dehumidifier", 3.00),
    ("window_kit", "Ground-reach window cleaning kit", 2.00),
]
TOOL_MAP = {row[0]: row for row in TOOLS}
LOCK = threading.RLock()
RESERVATIONS: dict[str, dict] = {}


def iso(ts: float | None) -> str | None:
    return datetime.fromtimestamp(ts, timezone.utc).isoformat() if ts else None


def public(r: dict) -> dict:
    now = time.time()
    elapsed = max(0, now - r["picked_up_at"]) if r.get("picked_up_at") else 0
    total_hours = math.ceil(elapsed / 3600) if elapsed else 1
    status = r["status"]
    if status == "reserved" and now > r["pickup_expires_at"]:
        status = "expired"
    return {
        "id": r["id"], "resident": r["resident"], "unit": r["unit"],
        "tool_id": r["tool_id"], "tool_name": r["tool_name"],
        "hourly_rate": r["hourly_rate"], "pin": r["pin"],
        "pickup_qr": r["pickup_qr"], "barcode": r["barcode"],
        "status": status, "reserved_at": iso(r["reserved_at"]),
        "pickup_expires_at": iso(r["pickup_expires_at"]),
        "picked_up_at": iso(r.get("picked_up_at")),
        "returned_at": iso(r.get("returned_at")), "elapsed_seconds": int(elapsed),
        "charge_hours": total_hours, "rental_fee": round(total_hours * r["hourly_rate"], 2),
        "paid": r.get("paid", False), "payment_method": r.get("payment_method"),
        "last4": r.get("last4"),
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "ToolVaultDemo/1.0"

    def log_message(self, *_args):
        return  # Never log request bodies or test card data.

    def send_json(self, status: int, data: dict):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_json(200, {"ok": True})

    def body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        return json.loads(self.rfile.read(length) or b"{}")

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/health":
            return self.send_json(200, {"ok": True, "service": "Tool Vault demo"})
        if parsed.path == "/api/tools":
            with LOCK:
                items = []
                for tool_id, name, rate in TOOLS:
                    reserved_assets = sum(1 for r in RESERVATIONS.values() if r["tool_id"] == tool_id and (r["status"] in ("borrowed", "return_scanning") or (r["status"] == "reserved" and r["pickup_expires_at"] > time.time())))
                    items.append({"id": tool_id, "name": name, "hourly_rate": rate, "available": max(0, 1 - reserved_assets), "barcode": f"TVITEM|VILLAS01|{tool_id}|ASSET01"})
            return self.send_json(200, {"tools": items})
        if parsed.path == "/api/reservations":
            resident = parse_qs(parsed.query).get("resident", [""])[0]
            with LOCK:
                items = [public(r) for r in RESERVATIONS.values() if r["resident"] == resident]
            return self.send_json(200, {"reservations": items})
        if parsed.path.startswith("/api/reservations/"):
            rid = parsed.path.rsplit("/", 1)[-1]
            with LOCK:
                item = RESERVATIONS.get(rid)
                if item:
                    return self.send_json(200, {"reservation": public(item)})
            return self.send_json(404, {"error": "Reservation not found."})
        return self.send_json(404, {"error": "Endpoint not found."})

    def do_POST(self):
        try:
            data = self.body()
        except Exception:
            return self.send_json(400, {"error": "Invalid JSON request."})
        path = urlparse(self.path).path
        with LOCK:
            if path == "/api/reservations":
                tool_id = str(data.get("tool_id", ""))
                tool = TOOL_MAP.get(tool_id)
                if not tool:
                    return self.send_json(400, {"error": "Choose a listed tool."})
                busy = any(r["tool_id"] == tool_id and (r["status"] in ("borrowed", "return_scanning") or (r["status"] == "reserved" and r["pickup_expires_at"] > time.time())) for r in RESERVATIONS.values())
                if busy:
                    return self.send_json(409, {"error": "This tool is currently reserved or checked out."})
                now = time.time()
                rid = secrets.token_hex(4).upper()
                pin = f"{secrets.randbelow(1_000_000):06d}"
                barcode = f"TVITEM|VILLAS01|{tool_id}|ASSET01"
                item = {"id": rid, "resident": str(data.get("resident", "")), "unit": str(data.get("unit", "")), "tool_id": tool_id, "tool_name": tool[1], "hourly_rate": tool[2], "pin": pin, "pickup_qr": f"TVPICKUP|{rid}|{tool_id}|{pin}", "barcode": barcode, "status": "reserved", "reserved_at": now, "pickup_expires_at": now + 3600, "picked_up_at": None, "returned_at": None, "paid": False}
                RESERVATIONS[rid] = item
                return self.send_json(201, {"reservation": public(item)})

            if path == "/api/locker/pickup":
                pin = str(data.get("pin", "")).strip()
                qr = str(data.get("qr", "")).strip()
                item = next((r for r in RESERVATIONS.values() if (pin and secrets.compare_digest(pin, r["pin"])) or (qr and secrets.compare_digest(qr, r["pickup_qr"]))), None)
                if not item:
                    return self.send_json(404, {"error": "PIN or QR is not linked to an active reservation."})
                if item["status"] != "reserved" or time.time() > item["pickup_expires_at"]:
                    return self.send_json(409, {"error": "Reservation expired or already collected."})
                item["status"] = "borrowed"
                item["picked_up_at"] = time.time()
                return self.send_json(200, {"reservation": public(item), "locker": f"LOCKER-{item['tool_id'].upper()}"})

            if path == "/api/locker/return":
                barcode = str(data.get("barcode", "")).strip()
                item = next((r for r in RESERVATIONS.values() if secrets.compare_digest(barcode, r["barcode"]) and r["status"] == "borrowed"), None)
                if not item:
                    return self.send_json(404, {"error": "Barcode not found, not checked out, or assigned to another tool."})
                item["status"] = "return_scanning"
                return self.send_json(200, {"reservation": public(item), "locker": f"LOCKER-{item['tool_id'].upper()}"})

            if path == "/api/locker/return-sensor":
                rid = str(data.get("reservation_id", ""))
                item = RESERVATIONS.get(rid)
                if not item or item["status"] != "return_scanning" or data.get("dark_confirmed") is not True:
                    return self.send_json(409, {"error": "A verified return and dark occupancy-camera reading are required."})
                item["status"] = "returned"
                item["returned_at"] = time.time()
                return self.send_json(200, {"reservation": public(item)})

            if path == "/api/payment":
                item = RESERVATIONS.get(str(data.get("reservation_id", "")))
                if not item or item["status"] != "returned":
                    return self.send_json(409, {"error": "Return the tool before paying."})
                if item.get("paid"):
                    return self.send_json(409, {"error": "This rental is already paid."})
                method = str(data.get("method", ""))
                if method not in ("Card", "FPX online banking", "Touch 'n Go eWallet"):
                    return self.send_json(400, {"error": "Select a payment method."})
                last4 = None
                if method == "Card":
                    digits = "".join(ch for ch in str(data.get("card_number", "")) if ch.isdigit())
                    expiry = str(data.get("expiry", "")).strip()
                    try:
                        month_text, year_text = expiry.split("/")
                        month = int(month_text)
                        year = 2000 + int(year_text) if len(year_text) == 2 else int(year_text)
                        current = datetime.now(timezone.utc)
                        valid_expiry = 1 <= month <= 12 and (year, month) >= (current.year, current.month)
                    except (ValueError, TypeError):
                        valid_expiry = False
                    cvv = str(data.get("cvv", ""))
                    if digits != "4242424242424242" or not valid_expiry or not cvv.isdigit() or len(cvv) != 3:
                        return self.send_json(400, {"error": "For this demo only, use card 4242 4242 4242 4242, a future expiry and any 3-digit CVV."})
                    last4 = digits[-4:]
                item["paid"] = True
                item["payment_method"] = method
                item["last4"] = last4
                return self.send_json(200, {"reservation": public(item), "message": "Demo payment approved."})

        return self.send_json(404, {"error": "Endpoint not found."})


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Tool Vault shared LAN demo service")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", default=8765, type=int)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Tool Vault API listening on http://{args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nTool Vault API stopped.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
