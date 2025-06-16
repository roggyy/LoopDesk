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

# Apply the patch - this converts from new format to old format
sed -i 's/response_event_id=function_response_event.id,\n\s*function_response=function_response,/function_response_event=function_response_event,/' "$ADK_PATH"

# Verify patch
echo "🔍 After patch:"
if grep -q "function_response_event=function_response_event" "$ADK_PATH"; then
    echo "✅ Patch applied successfully!"
    grep -A 5 "trace_tool_call" "$ADK_PATH"
else
    echo "❌ Patch failed to apply"
    # Restore backup
    mv "${ADK_PATH}.bak" "$ADK_PATH"
    exit 1
fi

# Add back the function_response_events.append line if it's missing
if ! grep -q "function_response_events.append(function_response_event)" "$ADK_PATH"; then
    sed -i '/trace_tool_call/a \      function_response_events.append(function_response_event)' "$ADK_PATH"
    echo "✅ Added back function_response_events.append line"
fi

# Remove the commented lines if they exist
sed -i '/# response_event_id=/d' "$ADK_PATH"
sed -i '/# function_response=/d' "$ADK_PATH"

echo "✅ Final state:"
grep -A 5 "trace_tool_call" "$ADK_PATH"
grep -A 1 "function_response_events.append" "$ADK_PATH"

echo "Build and patch completed successfully!"