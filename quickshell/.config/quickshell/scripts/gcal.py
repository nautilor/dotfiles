#!/usr/bin/env python3
"""Minimal Google Calendar helper (stdlib only).

  gcal.py status                 -> {"state": "no-client"|"logged-out"|"ready"}
  gcal.py login                  -> OAuth loopback login (opens browser)
  gcal.py logout
  gcal.py events START END       -> {"events": [...], "calendars": [writable ...]}; dates YYYY-MM-DD (END exclusive)
  gcal.py save JSON              -> create (no "id") or patch an event
  gcal.py delete CALENDAR_ID EVENT_ID

Setup: create an OAuth client of type "Desktop app" in Google Cloud Console,
enable the Google Calendar API, and save
  ~/.config/quickshell-notch/gcal/client.json  ->  {"client_id": "...", "client_secret": "..."}
Token is stored in ~/.local/share/quickshell-island/gcal-token.json (0600).
"""
import base64, hashlib, http.server, json, os, secrets, sys, time
import urllib.parse, urllib.request, urllib.error, webbrowser
from datetime import datetime, timedelta

CLIENT_FILES = [os.path.expanduser(p) for p in ("~/.config/quickshell-notch/gcal/client.json", "~/.config/quickshell/gcal/client.json")]
TOKEN_FILE = os.path.expanduser("~/.local/share/quickshell-island/gcal-token.json")  # shared with the previous shell: no re-login
SCOPE = "https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/calendar.events"
AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
API = "https://www.googleapis.com/calendar/v3"


def out(obj):
    print(json.dumps(obj))


def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def load_client():
    for path in CLIENT_FILES:
        c = load_json(path)
        if c and "installed" in c:  # raw Google download
            c = c["installed"]
        if c and c.get("client_id"):
            return c
    return None


def save_token(tok):
    os.makedirs(os.path.dirname(TOKEN_FILE), exist_ok=True)
    fd = os.open(TOKEN_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(tok, f)


def post(url, data):
    req = urllib.request.Request(url, urllib.parse.urlencode(data).encode())
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def get(url, token, method="GET", body=None):
    headers = {"Authorization": "Bearer " + token}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=15) as r:
        raw = r.read()
        return json.loads(raw) if raw else {}


def access_token():
    client, tok = load_client(), load_json(TOKEN_FILE)
    if not client or not tok:
        return None
    if tok.get("expires_at", 0) > time.time() + 60:
        return tok["access_token"]
    try:
        new = post(TOKEN_URL, {
            "client_id": client["client_id"],
            "client_secret": client.get("client_secret", ""),
            "refresh_token": tok["refresh_token"],
            "grant_type": "refresh_token",
        })
    except urllib.error.HTTPError:
        return None
    tok["access_token"] = new["access_token"]
    tok["expires_at"] = time.time() + new.get("expires_in", 3600)
    save_token(tok)
    return tok["access_token"]


def cmd_status():
    if not load_client():
        return out({"state": "no-client", "clientFile": CLIENT_FILES[0]})
    tok = load_json(TOKEN_FILE)
    if not tok:
        return out({"state": "logged-out"})
    if "calendar.events" not in tok.get("scope", ""):
        # token predates write access: sign in again
        return out({"state": "logged-out", "reauth": True})
    out({"state": "ready"})


def cmd_login():
    client = load_client()
    if not client:
        return out({"error": "no-client"})
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    state = secrets.token_urlsafe(16)
    result = {}

    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            if "code" in q or "error" in q:
                result["q"] = q
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h3>Signed in. You can close this tab.</h3>")

        def log_message(self, *a):
            pass

    srv = http.server.HTTPServer(("127.0.0.1", 0), H)
    srv.timeout = 180
    redirect = "http://127.0.0.1:%d" % srv.server_port
    url = AUTH_URL + "?" + urllib.parse.urlencode({
        "client_id": client["client_id"], "redirect_uri": redirect,
        "response_type": "code", "scope": SCOPE, "state": state,
        "code_challenge": challenge, "code_challenge_method": "S256",
        "access_type": "offline", "prompt": "consent",
    })
    webbrowser.open(url)
    deadline = time.time() + 180
    while "q" not in result and time.time() < deadline:
        srv.handle_request()
    q = result.get("q")
    if not q or q.get("state", [""])[0] != state or "code" not in q:
        return out({"error": "login-failed"})
    try:
        t = post(TOKEN_URL, {
            "client_id": client["client_id"],
            "client_secret": client.get("client_secret", ""),
            "code": q["code"][0], "code_verifier": verifier,
            "redirect_uri": redirect, "grant_type": "authorization_code",
        })
    except urllib.error.HTTPError as e:
        return out({"error": "token-exchange", "detail": e.read().decode()[:200]})
    t["expires_at"] = time.time() + t.get("expires_in", 3600)
    save_token(t)
    out({"ok": True})


def cmd_logout():
    try:
        os.remove(TOKEN_FILE)
    except OSError:
        pass
    out({"ok": True})


def cmd_events(start, end):
    token = access_token()
    if not token:
        return out({"error": "auth"})
    tmin = datetime.fromisoformat(start).astimezone().isoformat()
    tmax = datetime.fromisoformat(end).astimezone().isoformat()
    try:
        cals = get(API + "/users/me/calendarList?minAccessRole=reader", token).get("items", [])
        events = []
        writable = [
            {"id": c["id"], "name": c.get("summaryOverride") or c.get("summary", ""),
             "color": c.get("backgroundColor", "#8CC8D9"), "primary": bool(c.get("primary"))}
            for c in cals if c.get("accessRole") in ("owner", "writer")
        ]
        for cal in cals:
            if cal.get("selected") is False:
                continue
            qs = urllib.parse.urlencode({
                "timeMin": tmin, "timeMax": tmax, "singleEvents": "true",
                "orderBy": "startTime", "maxResults": 250,
            })
            cid = urllib.parse.quote(cal["id"], safe="")
            for ev in get("%s/calendars/%s/events?%s" % (API, cid, qs), token).get("items", []):
                if ev.get("status") == "cancelled":
                    continue
                s, e = ev.get("start", {}), ev.get("end", {})
                events.append({
                    "id": ev["id"],
                    "title": ev.get("summary", "(no title)"),
                    "allDay": "date" in s,
                    "start": s.get("dateTime") or s.get("date"),
                    "end": e.get("dateTime") or e.get("date"),
                    "location": ev.get("location", ""),
                    "calendar": cal.get("summaryOverride") or cal.get("summary", ""),
                    "calendarId": cal["id"],
                    "canEdit": cal.get("accessRole") in ("owner", "writer") and ev.get("eventType", "default") == "default",
                    "color": cal.get("backgroundColor", "#8CC8D9"),
                })
    except urllib.error.HTTPError as e:
        return out({"error": "auth" if e.code in (401, 403) else "http-%d" % e.code})
    except (urllib.error.URLError, OSError):
        return out({"error": "network"})
    out({"events": events, "calendars": writable})


def local_iso(s):
    return datetime.fromisoformat(s).astimezone().isoformat()


def cmd_save(raw):
    token = access_token()
    if not token:
        return out({"error": "auth"})
    d = json.loads(raw)
    if d["allDay"]:
        end = (datetime.fromisoformat(d["end"][:10]) + timedelta(days=1)).strftime("%Y-%m-%d")
        start = {"date": d["start"][:10], "dateTime": None}
        end = {"date": end, "dateTime": None}
    else:
        start = {"dateTime": local_iso(d["start"]), "date": None}
        end = {"dateTime": local_iso(d["end"]), "date": None}
    body = {"summary": d["title"], "location": d.get("location", ""), "start": start, "end": end}
    cid = urllib.parse.quote(d["calendarId"], safe="")
    try:
        if d.get("id"):
            get("%s/calendars/%s/events/%s" % (API, cid, urllib.parse.quote(d["id"], safe="")), token, "PATCH", body)
        else:
            for k in ("start", "end"):
                body[k] = {a: b for a, b in body[k].items() if b is not None}
            get("%s/calendars/%s/events" % (API, cid), token, "POST", body)
    except urllib.error.HTTPError as e:
        return out({"error": "scope" if e.code == 403 else "auth" if e.code == 401 else "http-%d" % e.code})
    except (urllib.error.URLError, OSError):
        return out({"error": "network"})
    out({"ok": True})


def cmd_delete(calendar_id, event_id):
    token = access_token()
    if not token:
        return out({"error": "auth"})
    try:
        get("%s/calendars/%s/events/%s" % (API, urllib.parse.quote(calendar_id, safe=""), urllib.parse.quote(event_id, safe="")), token, "DELETE")
    except urllib.error.HTTPError as e:
        return out({"error": "scope" if e.code == 403 else "http-%d" % e.code})
    except (urllib.error.URLError, OSError):
        return out({"error": "network"})
    out({"ok": True})


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["status"]: cmd_status()
    elif a[:1] == ["login"]: cmd_login()
    elif a[:1] == ["logout"]: cmd_logout()
    elif a[:1] == ["events"] and len(a) == 3: cmd_events(a[1], a[2])
    elif a[:1] == ["save"] and len(a) == 2: cmd_save(a[1])
    elif a[:1] == ["delete"] and len(a) == 3: cmd_delete(a[1], a[2])
    else: sys.exit(__doc__)
