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
    url = f"{base_url.rstrip('/')}/.well-known/capabilities.json"

    try:
        r = requests.get(url, headers=HEADERS, timeout=TIMEOUT)
        r.raise_for_status()

        if not r.text.strip():
            raise JSONDecodeError("Empty response body", r.text, 0)

        return {
            "status": "ok",
            "data": r.json()
        }

    except ReadTimeout:
        return {"status": "timeout"}

    except ConnectionError:
        return {"status": "unreachable"}

    except JSONDecodeError:
        return {"status": "invalid"}

    except Exception as e:
        return {"status": "error", "detail": str(e)}

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
    write_registry = "--write-registry" in sys.argv

    servers = load_servers()
    registry = {
        "generated_at": datetime.now(UTC).isoformat(),
        "servers": {},
        "capabilities": [],
    }

    for name, base_url in servers.items():
        print(f"\n🔍 Discovering {name} → {base_url}")

        result = fetch_capabilities(base_url)

        if result["status"] != "ok":
            print(f"✖ Status: {result['status']}")
            registry["servers"][name] = {
                "base_url": base_url,
                "status": result["status"],
            }
            continue

        caps = result["data"]

        print(f"✔ MCP Version: {caps.get('mcp_version')}")
        print(f"✔ Server: {caps.get('server', {}).get('name')}")
        print(f"✔ Description: {caps.get('server', {}).get('description')}")

        cap_keys = list(caps.get("capabilities", {}).keys())
        print("✔ Capabilities:")
        for c in cap_keys:
            print(f"  - {c}")

        normalized = normalize_capabilities(
            caps["server"]["name"],
            caps
        )

        print("🧩 Normalized Capabilities:")
        for n in normalized:
            print(f"  - {n['id']} ({n['access']}) → {n['endpoint']}")

        registry["servers"][name] = {
            "base_url": base_url,
            "status": "ok",
            "server_name": caps["server"]["name"],
        }
        registry["capabilities"].extend(normalized)

    if write_registry:
        REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
        with open(REGISTRY_FILE, "w", encoding="utf-8") as f:
            json.dump(registry, f, indent=2)

        print(f"\n📦 Registry written to {REGISTRY_FILE}")

if __name__ == "__main__":
    main()
