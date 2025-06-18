# Stage 1: Build environment
FROM python:3.12-slim AS builder
SHELL ["/bin/bash", "-c"]

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl build-essential && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY . .

# Replace functions.py inside ADK
RUN echo "=== Replacing functions.py ===" && \
    PYTHON_PATH=$(python -c "import sys; print(f'{sys.prefix}/lib/python{sys.version_info.major}.{sys.version_info.minor}/site-packages/google/adk/flows/llm_flows/functions.py')") && \
    echo "Target path: $PYTHON_PATH" && \
    mkdir -p "$(dirname "$PYTHON_PATH")" && \
    cp -v /app/functions.py "$PYTHON_PATH"

RUN adduser --disabled-password --gecos '' appuser && chown -R appuser:appuser /app
RUN chown -R appuser:appuser /opt/venv
USER appuser

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

RUN ls -l /opt/venv/bin

CMD ["/opt/venv/bin/uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
