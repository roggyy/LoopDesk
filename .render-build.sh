#!/bin/bash
set -e  # Exit on error

echo "🚀 Starting build and patching process..."

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Locate the ADK package's functions.py file
ADK_PATH=$(pip show google-adk | grep Location | cut -d' ' -f2)/google/adk/flows/llm_flows/functions.py

echo "📁 ADK Path: $ADK_PATH"

# Check if file exists
if [ ! -f "$ADK_PATH" ]; then
    echo "❌ Error: ADK file not found at $ADK_PATH"
    exit 1
fi

# Create backup of original file
cp "$ADK_PATH" "${ADK_PATH}.bak"
echo "✅ Created backup at ${ADK_PATH}.bak"

# Remove all existing trace_tool_call blocks
echo "🧹 Cleaning old trace_tool_call blocks..."
sed -i '/trace_tool_call(/,/)/d' "$ADK_PATH"

# Find the first occurrence of AF_FUNCTION_CALL_ID_PREFIX to use as insertion point
INSERT_POINT=$(grep -n "AF_FUNCTION_CALL_ID_PREFIX" "$ADK_PATH" | head -n 1 | cut -d: -f1)
if [ -z "$INSERT_POINT" ]; then
    echo "❌ Could not find insertion point"
    mv "${ADK_PATH}.bak" "$ADK_PATH"
    exit 1
fi

echo "🔧 Inserting patched code at line $INSERT_POINT"

# Create a temporary file for the patch
TEMP_FILE=$(mktemp)

# Copy everything before the insertion point
head -n "$INSERT_POINT" "$ADK_PATH" > "$TEMP_FILE"

# Add the patched trace_tool_call code
cat >> "$TEMP_FILE" << 'EOL'
AF_FUNCTION_CALL_ID_PREFIX = 'adk-'

      trace_tool_call(
          tool=tool,
          args=function_args,
          function_response_event=function_response_event,
      )
      function_response_events.append(function_response_event)
EOL

# Skip original AF_FUNCTION_CALL_ID_PREFIX line and copy remaining content after the next empty line
tail -n +"$((INSERT_POINT + 1))" "$ADK_PATH" | awk 'NR==1{next} /^$/{found=1} found' >> "$TEMP_FILE"

# Replace the original file with the patched one
mv "$TEMP_FILE" "$ADK_PATH"

# Clean up potential duplicate appends
sed -i '/function_response_events.append(function_response_event)/{n;/function_response_events.append(function_response_event)/d;}' "$ADK_PATH"

# Final verification
echo "✅ Patch applied successfully!"
echo "🔍 Showing patched lines:"
grep -A 5 "trace_tool_call" "$ADK_PATH" || true
grep -A 1 "function_response_events.append" "$ADK_PATH" || true

echo "🏁 Build and patch completed successfully!"
