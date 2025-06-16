#!/bin/bash
set -e  # Exit on error

echo "🚀 Starting build and patching process..."

# Step 1: Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Step 2: Locate the ADK functions.py file
ADK_PATH=$(pip show google-adk | grep Location | cut -d' ' -f2)/google/adk/flows/llm_flows/functions.py
echo "📍 ADK Path: $ADK_PATH"

# Step 3: Validate path
if [ ! -f "$ADK_PATH" ]; then
    echo "❌ Error: ADK file not found at $ADK_PATH"
    exit 1
fi

# Step 4: Create a backup
cp "$ADK_PATH" "${ADK_PATH}.bak"
echo "✅ Created backup at ${ADK_PATH}.bak"

# Step 5: Remove existing trace_tool_call blocks (multi-line)
sed -i '/trace_tool_call(/,/)/d' "$ADK_PATH"

# Step 6: Find insert point after 'AF_FUNCTION_CALL_ID_PREFIX'
INSERT_POINT=$(grep -n "AF_FUNCTION_CALL_ID_PREFIX" "$ADK_PATH" | cut -d: -f1)
if [ -z "$INSERT_POINT" ]; then
    echo "❌ Could not find insertion point"
    mv "${ADK_PATH}.bak" "$ADK_PATH"
    exit 1
fi

# Step 7: Create a temporary patch file
TEMP_FILE=$(mktemp)

# Copy everything up to and including the insert line
head -n "$INSERT_POINT" "$ADK_PATH" > "$TEMP_FILE"

# Step 8: Insert patched code block
cat >> "$TEMP_FILE" << 'EOL'

      trace_tool_call(
          tool=tool,
          args=function_args,
          function_response_event=function_response_event,
      )
      function_response_events.append(function_response_event)
EOL

# Append the rest of the original file (skipping the next blank line after insertion)
tail -n +$((INSERT_POINT + 1)) "$ADK_PATH" | awk 'NR==1{next} /^$/{found=1} found' >> "$TEMP_FILE"

# Step 9: Replace the original file with the patched version
mv "$TEMP_FILE" "$ADK_PATH"

# Step 10: Clean duplicate lines
awk '!seen[$0]++' "$ADK_PATH" > "${ADK_PATH}.cleaned" && mv "${ADK_PATH}.cleaned" "$ADK_PATH"

# Step 11: Final state confirmation
echo "✅ Patch applied successfully!"
echo "🔍 Showing patched trace_tool_call:"
grep -A 5 "trace_tool_call" "$ADK_PATH" || true

echo "🔍 Checking for extra function_response_events.append lines:"
grep "function_response_events.append(function_response_event)" "$ADK_PATH" | wc -l

echo "🏁 Build and patch completed successfully!"
