# Apply the patch using sed
echo "🔍 Applying patch..."
sed -i '' -e '/trace_tool_call(/,/)/ {/response_event_id=function_response_event.id/,/function_response=function_response,/d}' "$ADK_PATH"
sed -i '' -e '/args=function_args,/a\          function_response_event=function_response_event,'"$'\n'"\      )\n      function_response_events.append(function_response_event)" "$ADK_PATH"

# Remove any duplicate append lines
sed -i '' -e '/function_response_events.append(function_response_event)/{n;/function_response_events.append(function_response_event)/d;}' "$ADK_PATH"

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

echo "✅ Final state:"
grep -A 5 "trace_tool_call" "$ADK_PATH" || true
grep -A 1 "function_response_events.append" "$ADK_PATH" | head -n 2 || true

echo "Build and patch completed successfully!"