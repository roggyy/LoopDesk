FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Replace functions.py inside ADK
RUN echo "=== Replacing functions.py ===" && \
    PYTHON_PATH=$(python -c "import sys; print(f'{sys.prefix}/lib/python{sys.version_info.major}.{sys.version_info.minor}/site-packages/google/adk/flows/llm_flows/functions.py')") && \
    echo "Target path: $PYTHON_PATH" && \
    mkdir -p "$(dirname "$PYTHON_PATH")" && \
    cp -v /app/functions.py "$PYTHON_PATH"

# Create non-root user and set permissions
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser:appuser /app
USER appuser

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]