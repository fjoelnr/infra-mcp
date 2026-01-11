import json
import sys
from pathlib import Path
from datetime import datetime, UTC

import requests
from requests.exceptions import ReadTimeout, ConnectionError, JSONDecodeError

BASE_DIR = Path(__file__).parent
SERVERS_FILE = BASE_DIR / "servers.json"
REGISTRY_DIR = BASE_DIR.parent / "registry"
REGISTRY_FILE = REGISTRY_DIR / "capability_registry.json"

TIMEOUT = 5  # bewusst kurz & deterministisch

HEADERS = {
    "Accept": "application/json",
    "Connection": "close",  # 🔒 kritisch für Stabilität
}

def load_servers():
    if not SERVERS_FILE.exists():
        raise RuntimeError("servers.json not found")

    with open(SERVERS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    if "servers" not in data or not isinstance(data["servers"], dict):
        raise RuntimeError("servers.json must contain a 'servers' object")

    return data["servers"]

def fetch_capabilities(base_url: str):
    url = base_url.rstrip("/") + "/.well-known/capabilities.json"
    try:
        r = requests.get(url, timeout=5)
        r.raise_for_status()

        if not r.text.strip():
            raise ValueError("Empty response body")

        return r.json()

    except Exception as e:
        return {
            "_error": str(e),
            "_url": url
        }

def normalize_capabilities(server_name, caps):
    normalized = []

    capabilities = caps.get("capabilities", {})
    for cap_name, cap in capabilities.items():
        resources = cap.get("resources", {})
        for res_name, res in resources.items():
            normalized.append({
                "id": f"{server_name}.{cap_name}.{res_name}",
                "server": server_name,
                "capability": cap_name,
                "resource": res_name,
                "method": res.get("method"),
                "endpoint": res.get("endpoint"),
                "access": cap.get("type", "unknown"),
            })

    return normalized

def main():
    args = parse_args()
    servers = load_servers()

    all_capabilities = []

    for name, base_url in servers.items():
        print(f"\n🔍 Discovering {name} → {base_url}")

        caps = fetch_capabilities(base_url)

        if "_error" in caps:
            print(f"⚠️  Failed to discover {name}")
            print(f"    Reason: {caps['_error']}")
            continue

        server = caps.get("server", {})
        print(f"✔ MCP Version: {caps.get('mcp_version')}")
        print(f"✔ Server: {server.get('name')}")
        print(f"✔ Description: {server.get('description')}")

        capabilities = caps.get("capabilities", {})
        print("✔ Capabilities:")
        for c in capabilities:
            print(f"  - {c}")

        normalized = normalize_capabilities(caps)
        print("🧩 Normalized Capabilities:")
        for n in normalized:
            print(f"  - {n['id']} ({n['access']}) → {n['endpoint']}")

        all_capabilities.extend(normalized)

    if args.write_registry:
        if not all_capabilities:
            print("\n⚠️ No capabilities discovered, registry not written.")
            return

        write_registry(all_capabilities)


if __name__ == "__main__":
    main()
