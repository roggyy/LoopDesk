# Stage 1: Build environment
FROM python:3.12-slim AS builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy only requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy virtual environment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY . .

# Replace the functions.py section with:
RUN echo "=== Replacing functions.py ===" && \
    # This will find the correct python version path
    PYTHON_PATH=$(python -c "import sys; print(f'{sys.prefix}/lib/python{sys.version_info.major}.{sys.version_info.minor}/site-packages/google/adk/flows/llm_flows/functions.py')") && \
    echo "Target path: $PYTHON_PATH" && \
    mkdir -p "$(dirname "$PYTHON_PATH")" && \
    cp -v /app/functions.py "$PYTHON_PATH" && \
    # Verify the file was copied
    echo "=== File verification ===" && \
    ls -la "$PYTHON_PATH" && \
    echo "=== First 5 lines ===" && \
    head -n 5 "$PYTHON_PATH" && \
    echo "=== File replaced successfully ==="

# Create a non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]