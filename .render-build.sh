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

# Apply patch
echo "🔍 Before patch:"
grep -A 5 "trace_tool_call" "$ADK_PATH" || echo "❌ trace_tool_call not found"

# Apply the patch
sed -i 's/function_response_event=function_response_event,/response_event_id=function_response_event.id,\n        function_response=function_response,/' "$ADK_PATH"

# Verify patch
echo "🔍 After patch:"
if grep -q "response_event_id=function_response_event.id" "$ADK_PATH"; then
    echo "✅ Patch applied successfully!"
    grep -A 5 "trace_tool_call" "$ADK_PATH"
else
    echo "❌ Patch failed to apply"
    # Restore backup
    mv "${ADK_PATH}.bak" "$ADK_PATH"
    exit 1
fi

echo "Build and patch completed successfully!"