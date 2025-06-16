echo "Starting build and patching process..."

# Install dependencies
pip install -r requirements.txt

# Locate and patch adk-python (modify the call in functions.py)
ADK_PATH=$(pip show google-adk | grep Location | cut -d' ' -f2)/google/adk/flows/llm_flows/functions.py

echo "Patching file at: $ADK_PATH"

# Patch the lines automatically using sed (platform dependent)
# sed -i for Linux, sed -i '' for macOS
sed -i 's/trace_tool_call(.*tool=tool,.*args=function_args,.*response_event_id=function_response_event.id,.*function_response=function_response,.*)/trace_tool_call(tool=tool, args=function_args, function_response_event=function_response_event)/' "$ADK_PATH"

echo "Patch applied. Proceeding to launch app if needed..."
