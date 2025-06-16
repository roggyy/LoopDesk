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

# Create a temporary file for the patch
TEMP_PATCH=$(mktemp)
cat > "$TEMP_PATCH" << 'EOL'
--- functions.py.original
+++ functions.py.patched
@@ -1,4 +1,4 @@
-# Original file will be patched here
+# This is a patch file
 # The actual content will be replaced by sed
 
 def handle_function_calls_live(...):
@@ -6,7 +6,7 @@
         trace_tool_call(
             tool=tool,
             args=function_args,
-            response_event_id=function_response_event.id,
-            function_response=function_response,
+            function_response_event=function_response_event,
         )
+        function_response_events.append(function_response_event)
 EOL