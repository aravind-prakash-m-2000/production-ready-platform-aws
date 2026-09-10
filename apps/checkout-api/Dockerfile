FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN groupadd --gid 65532 nonroot \
 && useradd --uid 65532 --gid 65532 --create-home --home-dir /home/nonroot nonroot

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-compile -r requirements.txt

COPY app.py .

USER 65532:65532
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz')"

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "4", "app:app"]
