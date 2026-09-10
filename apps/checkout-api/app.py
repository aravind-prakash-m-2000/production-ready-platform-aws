"""Checkout API — sample SLO-aware HTTP service for the platform demo."""

from __future__ import annotations

import os
import time
from typing import Dict

from flask import Flask, Response, jsonify
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

APP_NAME = os.getenv("APP_NAME", "checkout-api")
PORT = int(os.getenv("PORT", "8080"))

REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "route", "status"],
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "Request latency",
    ["route"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5),
)

app = Flask(__name__)
READY = True
STARTED = time.time()


@app.before_request
def _start_timer() -> None:
    from flask import g

    g.start = time.perf_counter()


@app.after_request
def _record(response: Response) -> Response:
    from flask import g, request

    route = request.path
    elapsed = time.perf_counter() - getattr(g, "start", time.perf_counter())
    LATENCY.labels(route=route).observe(elapsed)
    REQUESTS.labels(request.method, route, str(response.status_code)).inc()
    response.headers["X-App"] = APP_NAME
    return response


@app.get("/healthz")
def healthz() -> Dict[str, str]:
    return {"status": "ok", "app": APP_NAME}


@app.get("/readyz")
def readyz():
    if not READY:
        return jsonify({"status": "not-ready"}), 503
    return {"status": "ready", "uptime_seconds": int(time.time() - STARTED)}


@app.get("/")
def index() -> Dict[str, str]:
    return {"service": APP_NAME, "message": "checkout ok"}


@app.get("/api/v1/checkout")
def checkout() -> Dict[str, str]:
    return {"order_id": "ord-demo", "status": "accepted"}


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
