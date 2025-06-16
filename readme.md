# Project Setup and Execution

This document provides instructions on how to set up and run this project, as well as a critical fix for an issue within the `adk-python` library.

## 1. Setup

Follow these steps to set up your local development environment.

### Prerequisites

- Python 3.10+
- pip (Python package installer)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd <your-project-directory>
    ```

2.  **Create a virtual environment:**
    It is highly recommended to use a virtual environment to manage project dependencies.

    ```bash
    python -m venv env
    ```
    
    > **Note:** For convenience, a pre-configured virtual environment (`env` directory) has been included with the necessary fixes already applied. While this is not a recommended practice (as virtual environments should typically be recreated from `requirements.txt`), you can use it to skip the manual fix steps. However, for production use, it's better to create a fresh virtual environment and apply the fixes manually as described in section 2.

3.  **Activate the virtual environment:**
    -   On Windows:
        ```bash
        .\env\Scripts\activate
        ```
    -   On macOS/Linux:
        ```bash
        source env/bin/activate
        ```

4.  **Install dependencies:**
    Install all the required packages from `requirements.txt`.
    ```bash
    pip install -r requirements.txt
    ```

5.  **Set up environment variables:**
    Create a `.env` file in the project root directory and add the following environment variables with your actual credentials:
    ```env
    GOOGLE_GENAI_USE_VERTEXAI=FALSE
    GOOGLE_API_KEY="your_google_api_key_here"
    MAILJET_KEY="your_mailjet_key_here"
    MAILJET_SECRET="your_mailjet_secret_here"
    MAILJET_FROM_EMAIL="your_email@example.com"
    ```
    
    Replace the placeholder values with your actual credentials. Make sure to keep this file secure and never commit it to version control.

## 2. Important: Fix for `adk-python` Environment Script

There is a known issue in the `adk-python` library that requires a manual fix. The `handle_function_calls_live` method in `functions.py` calls `trace_tool_call` with incorrect parameters.


### How to Fix

1.  **Locate the file:**
    Navigate to the installed `adk` package in your virtual environment. The file to modify is located at:
    `env\Lib\site-packages\google\adk\flows\llm_flows\functions.py`

2.  **Modify the file:**
    Open the `functions.py` file and go to line 288 (or search for `handle_function_calls_live` function).
    
    **Incorrect code (lines 288-291):**
    ```python
    trace_tool_call(
        tool=tool,
        args=function_args,
        response_event_id=function_response_event.id,
        function_response=function_response,
    )
    ```

    **Corrected code:**
    ```python
    trace_tool_call(
        tool=tool,
        args=function_args,
        function_response_event=function_response_event,
    )
    ```

    The fix removes the `function_response_event` parameter from the `trace_tool_call` function call, as it's not a valid parameter for this function.

    go to git issue- https://github.com/google/adk-python/pull/1165/files

## 3. How to Run the Application

After setting up the environment and applying the fix, you can run the main application.

Make sure your virtual environment is activated.

```bash
- cd app
- uvicorn main:app --reload 
```