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

# First, clean up any existing modifications
echo "🔍 Cleaning up any existing modifications..."
sed -i '/#.*response_event_id=/d' "$ADK_PATH"
sed -i '/#.*function_response=/d' "$ADK_PATH"

# Remove duplicate append lines
sed -i '/function_response_events.append(function_response_event)/{n;d;}' "$ADK_PATH"

# Apply the patch - convert from new format to old format
echo "🔍 Applying patch..."
sed -i -e '/trace_tool_call(/,/)/ {/response_event_id=function_response_event.id/,/function_response=function_response,/d}' "$ADK_PATH"
sed -i '/trace_tool_call(/,/)/ {/args=function_args,/a\          function_response_event=function_response_event,'"$'\n'"\      )\n      function_response_events.append(function_response_event)"'}' "$ADK_PATH"

# Verify patch
echo "🔍 Verifying patch..."
if grep -q "function_response_event=function_response_event" "$ADK_PATH"; then
    echo "✅ Patch applied successfully!"
    echo "🔍 Current state:"
    grep -A 10 "trace_tool_call" "$ADK_PATH" | head -n 10
else
    echo "❌ Patch failed to apply"
    # Restore backup
    mv "${ADK_PATH}.bak" "$ADK_PATH"
    exit 1
fi

# Ensure only one append line exists
sed -i '/function_response_events.append(function_response_event)/{n;/function_response_events.append(function_response_event)/d;}' "$ADK_PATH"

echo "✅ Final state:"
grep -A 5 "trace_tool_call" "$ADK_PATH"
grep -A 1 "function_response_events.append" "$ADK_PATH" | head -n 2

echo "Build and patch completed successfully!"