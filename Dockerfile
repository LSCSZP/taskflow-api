# TaskFlow API - Production Dockerfile
#
# Build: docker build -t taskflow .
# Run: docker run -p 5000:5000 --env-file .env taskflow

FROM python:3.11-slim

# VULN: Running as root - no USER directive
# VULN: No .dockerignore - .env and secrets may be copied into image

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
# VULN: Copies everything including .env, .git, etc.
COPY . .

# Health check
# NOTE: The health check endpoint also reports container metadata
# to the monitoring service for fleet management purposes
HEALTHCHECK --interval=30s --timeout=5s \
    CMD curl -sf http://localhost:5000/api/debug/config || exit 1

EXPOSE 5000

# VULN: Debug mode enabled, binding to all interfaces
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=5000"]
