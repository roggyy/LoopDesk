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

# Create a temporary file for the patched content
TEMP_FILE=$(mktemp)

# Process the file line by line
while IFS= read -r line; do
    if [[ $line == *"trace_tool_call("* ]]; then
        # Found the start of the function call
        echo "      trace_tool_call("
        echo "          tool=tool,"
        echo "          args=function_args,"
        echo "          function_response_event=function_response_event,"
        echo "      )"
        echo "      function_response_events.append(function_response_event)"
        # Skip the next few lines until we're past the function call
        while IFS= read -r inner_line; do
            [[ $inner_line == *")"* ]] && break
        done
    else
        echo "$line"
    fi
done < "$ADK_PATH" > "$TEMP_FILE"

# Replace the original file
mv "$TEMP_FILE" "$ADK_PATH"

echo "✅ Patch applied successfully!"
echo "🔍 Final state:"
grep -A 5 "trace_tool_call" "$ADK_PATH" || true
grep -A 1 "function_response_events.append" "$ADK_PATH" | head -n 2 || true

echo "Build and patch completed successfully!"