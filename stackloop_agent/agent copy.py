# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from google.adk.agents import Agent
from google.adk.tools import google_search,FunctionTool  # Import the tool

from mailjet_rest import Client
import os

# Initialize Mailjet client from environment variables
# mailjet = Client(
#     auth=(os.environ["MJ_APIKEY_PUBLIC"], os.environ["MJ_APIKEY_PRIVATE"]),
#     version="v3.1"
# )

mailjet = Client(
    auth=("ca5a8602d1ad743db9b6a4b1f99b6864", "e8baf4c4e1528d152edb92a36e54d873"),
    version="v3.1"
)

def send_mail(to_email: str, text_part: str) -> bool:
    """
    mail_tool
    Send a plain-text email via Mailjet.

    args:
        to_email (str): The email address to send the message to.
        text_part (str): The plain-text content of the email.

    Returns True if the request succeeded (status 200 or 201), else False.
    """

    mailjet = Client(
    auth=("ca5a8602d1ad743db9b6a4b1f99b6864", "e8baf4c4e1528d152edb92a36e54d873"),
    version="v3.1"
)
    
    data = {
        "Messages": [
            {
                "From": {"Email": os.environ.get("MAILJET_FROM_EMAIL", "aniketguptarog@gmail.com"), "Name": "Me"},
                "To": [{"Email": to_email}],
                "Subject": "Mail from Stackloop",
                "TextPart": text_part
            }
        ]
    }
    result = mailjet.send.create(data=data)
    status = result.status_code
    return status in {200, 201}

mail_tool = FunctionTool(func=send_mail)

# success = send_mail("abhijeetg375@gmail.com", "Hello from Mailjet!")
# print("Sent!" if success else "Failed to send.")

root_agent = Agent(
   # A unique name for the agent.
   name="google_search_agent",
   # The Large Language Model (LLM) that agent will use.
   # model="gemini-2.0-flash-exp", # if this model does not work, try below
   model="gemini-2.0-flash-live-001",
   # A short description of the agent's purpose.
   description="Agent to answer questions using Google Search and can send mail to book appointmaint useing mail_tool.",
   # Instructions to set the agent's behavior.
   instruction="Answer the question using the Google Search tool.",
   # Add google_search tool to perform grounding with Google search.
   tools=[google_search,mail_tool],
)






# import os
# import base64
# from email.message import EmailMessage
# from typing import Optional

# from google.auth import default
# from google.auth.transport.requests import Request
# from google.oauth2.service_account import Credentials as SA_Credentials
# from googleapiclient.discovery import build
# from googleapiclient.errors import HttpError

# # Required Gmail API scope for sending email
# SCOPES = ["https://www.googleapis.com/auth/gmail.send"]

# def get_gmail_credentials() -> Optional[object]:
#     """
#     Returns a valid Gmail API credential using one of:
#     1) Service account via GOOGLE_APPLICATION_CREDENTIALS (with domain-wide delegation).
#     2) ADC: default user credentials (`gcloud auth application-default login`).
#     """
#     creds = None

#     # Option A: Service account w/ domain delegation
#     svc_file = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
#     delegated_user = os.getenv("GMAIL_DELEGATED_USER")
#     if svc_file and delegated_user:
#         creds = SA_Credentials.from_service_account_file(
#             svc_file, scopes=SCOPES
#         ).with_subject(delegated_user)
#         return creds

#     # Option B: Application Default Credentials
#     creds, _ = default(scopes=SCOPES)
#     if creds and not creds.valid and creds.expired and creds.refresh_token:
#         creds.refresh(Request())
#     return creds

# def gmail_send(email_to: str, subject: str, body_text: str) -> Optional[dict]:
#     """
#     Sends a Gmail message synchronously.
#     Returns the Gmail "Message" resource (with id) on success.
#     """
#     creds = get_gmail_credentials()
#     if not creds:
#         raise RuntimeError("No valid Gmail credentials found!")

#     try:
#         service = build("gmail", "v1", credentials=creds)
#         msg = EmailMessage()
#         msg.set_content(body_text)
#         msg["To"] = email_to
#         msg["From"] = "me"
#         msg["Subject"] = subject

#         raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
#         message_body = {"raw": raw}
#         sent = service.users().messages().send(userId="me", body=message_body).execute()
#         return sent  # contains message id and threadId
#     except HttpError as e:
#         print(f"Gmail API error: {e}")
#         return None


# # from gmail_tool import gmail_send

# def my_email_tool(to: str, subject: str, body: str):
#     result = gmail_send(to, subject, body)
#     if result:
#         return {"status": "success", "message_id": result["id"]}
#     return {"status": "failure"}


# # tests/test_gmail_tool.py
# import base64
# import pytest
# from unittest.mock import patch, MagicMock
# # from gmail_tool import gmail_send

# @patch("gmail_tool.build")
# def test_gmail_send_mock(build_mock):
#     mock_service = MagicMock()
#     build_mock.return_value = mock_service
#     mock_msgs = mock_service.users.return_value.messages.return_value
#     mock_msgs.send.return_value.execute.return_value = {"id": "123abc"}

#     result = gmail_send("aniketguptarog@gmail.com", "Hallo", "Test body")
#     assert result["id"] == "123abc"

#     # Ensure Gmail API built and send() was invoked
#     build_mock.assert_called_once_with("gmail", "v1", credentials=build_mock.call_args[1]["credentials"])
#     mock_msgs.send.assert_called()





# # def run_tests():
# #     """Simple test runner focusing on my_email_tool"""
# #     from unittest.mock import patch
    
# #     print("Running tests...")
    
# #     # Test 1: my_email_tool success case
# #     with patch("__main__.gmail_send") as gmail_mock:
# #         gmail_mock.return_value = {"id": "123abc", "threadId": "thread123"}
# #         result = my_email_tool("test@example.com", "Test Subject", "Test body")
# #         assert result["status"] == "success"
# #         assert result["message_id"] == "123abc"
# #         print("✓ my_email_tool success test passed")
    
# #     # Test 2: my_email_tool failure case
# #     with patch("__main__.gmail_send") as gmail_mock:
# #         gmail_mock.return_value = None
# #         result = my_email_tool("test@example.com", "Test Subject", "Test body")
# #         assert result["status"] == "failure"
# #         print("✓ my_email_tool failure test passed")
    
# #     # Test 3: Test gmail_send with full mocking
# #     print("Testing gmail_send function...")
# #     with patch("googleapiclient.discovery.build") as build_mock, \
# #          patch("__main__.get_gmail_credentials") as creds_mock:
        
# #         # Setup mocks
# #         creds_mock.return_value = "fake_credentials"
# #         mock_service = MagicMock()
# #         build_mock.return_value = mock_service
# #         mock_msgs = mock_service.users.return_value.messages.return_value
# #         mock_msgs.send.return_value.execute.return_value = {"id": "test123", "threadId": "thread456"}
        
# #         # Test the function
# #         result = gmail_send("aniketguptarog@gmail.com", "Test Subject", "Test Body")
        
# #         # Verify results
# #         assert result is not None
# #         assert result["id"] == "test123"
# #         print("✓ gmail_send test passed")
    
# #     print("All tests passed! ✓")

# # if __name__ == "__main__":
# #     run_tests()


# def run_tests():
#     """Simple test runner focusing on my_email_tool"""
#     from unittest.mock import patch, MagicMock
    
#     print("Running tests...")
    
#     # Test 1: my_email_tool success case
#     with patch("__main__.gmail_send") as gmail_mock:
#         gmail_mock.return_value = {"id": "123abc", "threadId": "thread123"}
#         result = my_email_tool("test@example.com", "Test Subject", "Test body")
#         assert result["status"] == "success"
#         assert result["message_id"] == "123abc"
#         print("✓ my_email_tool success test passed")
    
#     # Test 2: my_email_tool failure case
#     with patch("__main__.gmail_send") as gmail_mock:
#         gmail_mock.return_value = None
#         result = my_email_tool("test@example.com", "Test Subject", "Test body")
#         assert result["status"] == "failure"
#         print("✓ my_email_tool failure test passed")
    
#     # Test 3: Test that my_email_tool calls gmail_send with correct parameters
#     with patch("__main__.gmail_send") as gmail_mock:
#         gmail_mock.return_value = {"id": "xyz789"}
        
#         my_email_tool("user@test.com", "Hello", "World")
        
#         # Verify gmail_send was called with correct arguments
#         gmail_mock.assert_called_once_with("user@test.com", "Hello", "World")
#         print("✓ my_email_tool parameter passing test passed")
    
#     # Test 4: Test gmail_send with proper mocking (avoiding universe domain issues)
#     print("Testing gmail_send function...")
#     with patch("__main__.get_gmail_credentials") as creds_mock, \
#          patch("googleapiclient.discovery.build") as build_mock:
        
#         # Create a proper mock credentials object with universe_domain
#         mock_credentials = MagicMock()
#         mock_credentials.universe_domain = "googleapis.com"
#         mock_credentials.valid = True
#         mock_credentials.expired = False
#         creds_mock.return_value = mock_credentials
        
#         # Setup Gmail service mock
#         mock_service = MagicMock()
#         build_mock.return_value = mock_service
        
#         # Setup the chain of method calls
#         mock_users = MagicMock()
#         mock_messages = MagicMock()
#         mock_send = MagicMock()
#         mock_execute = MagicMock()
        
#         mock_service.users.return_value = mock_users
#         mock_users.messages.return_value = mock_messages
#         mock_messages.send.return_value = mock_send
#         mock_send.execute.return_value = {"id": "test123", "threadId": "thread456"}
        
#         # Test the function
#         result = gmail_send("aniketguptarog@gmail.com", "Test Subject", "Test Body")
        
#         # Verify results
#         assert result is not None
#         assert result["id"] == "test123"
        
#         # Verify the service was built with correct parameters
#         build_mock.assert_called_once_with("gmail", "v1", credentials=mock_credentials)
#         print("✓ gmail_send test passed")
    
#     print("All tests passed! ✓")

# if __name__ == "__main__":
#     run_tests()
