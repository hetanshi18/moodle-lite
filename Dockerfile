# ── Stage 1: Builder ────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt


# ── Stage 2: Runtime ────────────────────────────────────────
FROM python:3.11-slim

LABEL org.opencontainers.image.title="MoodLite LMS"
LABEL org.opencontainers.image.description="Minimal Learning Management System"
LABEL org.opencontainers.image.source="https://github.com/yourgithubusername/moodlite"

# Runtime system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 && rm -rf /var/lib/apt/lists/*

# Non-root user for security
RUN useradd -m -u 1000 moodlite
USER moodlite
WORKDIR /home/moodlite/app

# Copy installed packages from builder
COPY --from=builder --chown=moodlite:moodlite /root/.local /home/moodlite/.local
ENV PATH=/home/moodlite/.local/bin:$PATH

# Copy application source
COPY --chown=moodlite:moodlite . .

# Upload directory (will be overridden by mounted PV in Kubernetes)
RUN mkdir -p /home/moodlite/uploads

# Flask / Gunicorn config
ENV FLASK_APP=wsgi.py
ENV FLASK_ENV=production
ENV UPLOAD_FOLDER=/home/moodlite/uploads
ENV PORT=5000

EXPOSE 5000

# Health check for Kubernetes liveness/readiness probes
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["gunicorn","--bind","0.0.0.0:5000","--workers","2","--threads","4","--timeout","120","--access-logfile","-","--error-logfile","-","wsgi:app"]
