#!/usr/bin/env python3
"""Create or update a Jira incident from Alertmanager webhooks or CLI flags."""

from __future__ import annotations

import argparse
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

JIRA_BASE = os.environ.get("JIRA_BASE_URL", "").rstrip("/")
JIRA_USER = os.environ.get("JIRA_USER", "")
JIRA_TOKEN = os.environ.get("JIRA_API_TOKEN", "")
JIRA_PROJECT = os.environ.get("JIRA_PROJECT", "SRE")


def jira_request(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    if not (JIRA_BASE and JIRA_USER and JIRA_TOKEN):
        raise SystemExit("Set JIRA_BASE_URL, JIRA_USER, and JIRA_API_TOKEN")

    body = json.dumps(payload).encode("utf-8")
    req = Request(
        f"{JIRA_BASE}{path}",
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    # HTTPBasicAuth equivalent
    import base64

    token = base64.b64encode(f"{JIRA_USER}:{JIRA_TOKEN}".encode()).decode()
    req.add_header("Authorization", f"Basic {token}")

    try:
        with urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except HTTPError as exc:
        detail = exc.read().decode()
        raise SystemExit(f"Jira API error {exc.code}: {detail}") from exc
    except URLError as exc:
        raise SystemExit(f"Jira unreachable: {exc}") from exc


def create_incident(summary: str, description: str, severity: str) -> dict[str, Any]:
    priority = "Highest" if severity == "page" else "High"
    payload = {
        "fields": {
            "project": {"key": JIRA_PROJECT},
            "summary": summary[:255],
            "description": description,
            "issuetype": {"name": "Incident"},
            "priority": {"name": priority},
            "labels": ["alertmanager", "sre", severity],
        }
    }
    return jira_request("/rest/api/2/issue", payload)


def issue_from_alertmanager(payload: dict[str, Any]) -> None:
    for alert in payload.get("alerts", []):
        status = alert.get("status", "firing")
        if status != "firing":
            continue
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})
        summary = annotations.get("summary") or labels.get("alertname", "alert")
        description = (
            f"{annotations.get('description', '')}\n\n"
            f"alertname={labels.get('alertname')}\n"
            f"severity={labels.get('severity')}\n"
            f"runbook={annotations.get('runbook_url', 'n/a')}\n"
        )
        issue = create_incident(summary, description, labels.get("severity", "ticket"))
        print(json.dumps({"key": issue.get("key"), "self": issue.get("self")}))


class Handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802
        if self.path not in ("/alertmanager", "/"):
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode())
        except json.JSONDecodeError:
            self.send_error(400, "invalid json")
            return
        try:
            issue_from_alertmanager(payload)
        except SystemExit as exc:
            self.send_error(502, str(exc))
            return
        self.send_response(204)
        self.end_headers()

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stderr.write("jira-bridge: " + (fmt % args) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serve", action="store_true", help="Run Alertmanager webhook server")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--summary")
    parser.add_argument("--description", default="Manual incident")
    parser.add_argument("--severity", default="ticket", choices=("page", "ticket"))
    args = parser.parse_args()

    if args.serve:
        HTTPServer(("0.0.0.0", args.port), Handler).serve_forever()
        return

    if not args.summary:
        parser.error("--summary is required unless --serve is set")
    issue = create_incident(args.summary, args.description, args.severity)
    print(json.dumps(issue, indent=2))


if __name__ == "__main__":
    main()
