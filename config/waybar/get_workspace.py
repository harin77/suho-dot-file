import sys
import json
import subprocess

def main():
    if len(sys.argv) < 2:
        return
    ws_id = int(sys.argv[1])
    
    # Get active workspace
    try:
        active_raw = subprocess.check_output(["hyprctl", "activeworkspace", "-j"])
        active_ws = json.loads(active_raw)["id"]
    except Exception:
        active_ws = 1

    # Get all workspaces
    try:
        workspaces_raw = subprocess.check_output(["hyprctl", "workspaces", "-j"])
        workspaces = json.loads(workspaces_raw)
        occupied_ids = [w["id"] for w in workspaces]
    except Exception:
        occupied_ids = []

    if ws_id == active_ws:
        status = "active"
    elif ws_id in occupied_ids:
        status = "occupied"
    else:
        status = "empty"

    out = {
        "text": str(ws_id),
        "class": status
    }
    print(json.dumps(out))

if __name__ == "__main__":
    main()
