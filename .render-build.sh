#!/bin/bash
set -e  # Exit on error

echo "Starting build and patching process..."

# Install dependencies
pip install -r requirements.txt

# Locate the ADK package
ADK_PATH=$(pip show google-adk | grep Location | cut -d' ' -f2)/google/adk/flows/llm_flows/functions.py

echo "ADK Path: $ADK_PATH"

# Check if file exists
if [ ! -f "$ADK_PATH" ]; then
    echo "❌ Error: ADK file not found at $ADK_PATH"
    exit 1
fi

# Create backup of original file
cp "$ADK_PATH" "${ADK_PATH}.bak"
echo "✅ Created backup at ${ADK_PATH}.bak"

# First, remove all existing trace_tool_call blocks
sed -i '/trace_tool_call(/,/)/d' "$ADK_PATH"

# Then, add our patched version in the right place
# Find the line with AF_FUNCTION_CALL_ID_PREFIX
INSERT_POINT=$(grep -n "AF_FUNCTION_CALL_ID_PREFIX" "$ADK_PATH" | cut -d: -f1)
if [ -z "$INSERT_POINT" ]; then
    echo "❌ Could not find insertion point"
    mv "${ADK_PATH}.bak" "$ADK_PATH"
    exit 1
fi

# Create a temporary file for the patch
TEMP_FILE=$(mktemp)

# Copy everything before the insertion point
head -n $INSERT_POINT "$ADK_PATH" > "$TEMP_FILE"

# Add our patched code
cat >> "$TEMP_FILE" << 'EOL'
AF_FUNCTION_CALL_ID_PREFIX = 'adk-'

      trace_tool_call(
          tool=tool,
          args=function_args,
          function_response_event=function_response_event,
      )
      function_response_events.append(function_response_event)
EOL

# Skip the original AF_FUNCTION_CALL_ID_PREFIX line and everything until the next empty line
tail -n +$((INSERT_POINT + 1)) "$ADK_PATH" | awk 'NR==1{next} /^$/{found=1} found' >> "$TEMP_FILE"

# Replace the original file
mv "$TEMP_FILE" "$ADK_PATH"

# Remove any duplicate append lines
sed -i '/function_response_events.append(function_response_event)/{n;/function_response_events.append(function_response_event)/d;}' "$ADK_PATH"

echo "✅ Patch applied successfully!"
echo "🔍 Final state:"
grep -A 5 "trace_tool_call" "$ADK_PATH" || true
grep -A 1 "function_response_events.append" "$ADK_PATH" || true

echo "Build and patch completed successfully!"