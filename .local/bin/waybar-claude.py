#!/usr/bin/env python3
import os
import json
import time
import urllib.request
from datetime import datetime, timezone

CONFIG_FILE = os.path.expanduser("~/.config/claude-usage/config.json")
CACHE_FILE = "/tmp/waybar_claude_usage_cache.json"
CACHE_TTL = 60

# Font Awesome 7 Brands ile resmi Claude logosu
CLAUDE_ICON = "<span face='Font Awesome 7 Brands' color='#d97757'>\ue861</span>"


def load_config():
    if not os.path.exists(CONFIG_FILE):
        return None
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return None


def fetch_usage_from_api(session_key, org_id):
    url = f"https://claude.ai/api/organizations/{org_id}/usage"
    req = urllib.request.Request(
        url,
        headers={
            "Cookie": f"sessionKey={session_key}",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=5) as response:
        return json.loads(response.read().decode("utf-8"))


def get_usage():
    if os.path.exists(CACHE_FILE):
        try:
            mtime = os.path.getmtime(CACHE_FILE)
            if time.time() - mtime < CACHE_TTL:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
        except Exception:
            pass

    cfg = load_config()
    if not cfg or not cfg.get("session_key") or not cfg.get("org_id"):
        return None

    try:
        data = fetch_usage_from_api(cfg["session_key"], cfg["org_id"])
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)
        return data
    except Exception:
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return None


def main():
    data = get_usage()

    if not data or "five_hour" not in data:
        print(
            json.dumps(
                {
                    "text": f"{CLAUDE_ICON} Auth Err",
                    "tooltip": "Claude API'ye bağlanılamadı. sessionKey veya org_id kontrol edin.",
                    "class": "critical",
                }
            )
        )
        return

    raw_5h = data.get("five_hour", {}).get("utilization", 0)
    pct_5h = int(raw_5h * 100) if raw_5h <= 1.0 else int(raw_5h)

    raw_7d = data.get("seven_day", {}).get("utilization", 0)
    pct_7d = int(raw_7d * 100) if raw_7d <= 1.0 else int(raw_7d)

    reset_str = ""
    resets_at = data.get("five_hour", {}).get("resets_at")
    if resets_at:
        try:
            reset_time = datetime.fromisoformat(resets_at.replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            diff_mins = int((reset_time - now).total_seconds() / 60)
            if diff_mins > 60:
                reset_str = f" 󱫡 {diff_mins // 60}h {diff_mins % 60}m"
            elif diff_mins > 0:
                reset_str = f" 󱫡 {diff_mins}m"
        except Exception:
            pass

    status_class = "normal"
    if pct_5h >= 75:
        status_class = "warning"
    if pct_5h >= 90:
        status_class = "critical"

    out = {
        "text": f"{CLAUDE_ICON} %{pct_5h}{reset_str}",
        "tooltip": f"5 Saatlik Oturum: %{pct_5h}\n• Haftalık Limit: %{pct_7d}\n• Sıfırlanma: {resets_at or 'Bilinmiyor'}",
        "percentage": pct_5h,
        "class": status_class,
    }

    print(json.dumps(out))


if __name__ == "__main__":
    main()
