from google.adk.agents import Agent
from google.adk.tools import google_search,FunctionTool  # Import the tool

from mailjet_rest import Client
import os
from dotenv import load_dotenv
import yfinance as yf

load_dotenv()


MAILJET_KEY = os.getenv("MAILJET_KEY")
MAILJET_SECRET = os.getenv("MAILJET_SECRET")
MAILJET_FROM_EMAIL = os.getenv("MAILJET_FROM_EMAIL", "aniketguptarog@gmail.com")



def send_mail(to_email: str, text_part: str) -> dict:
    """
    mail_tool
    Send a plain-text email via Mailjet.

    args:
        to_email (str): The email address to send the message to.
        text_part (str): The plain-text content of the email.

    Returns:
        dict: A dictionary with the status of the email sending attempt.
    """

    print("-->> mail id is ", to_email)

    mailjet_available = MAILJET_KEY is not None and MAILJET_SECRET is not None

    # Initialize Mailjet client only if keys are available
    if mailjet_available:
       mailjet = Client(auth=(MAILJET_KEY, MAILJET_SECRET), version="v3.1")
    else:
       mailjet = None

    if not mailjet_available:
        return {"status": "error", "message": "Mailing system is down. API keys not found."}

    print("--> Seding mail to - ", to_email)
    try:
        data = {
            "Messages": [
                {
                    "From": {"Email": MAILJET_FROM_EMAIL, "Name": "StackLoop"},
                    "To": [{"Email": to_email}],
                    "Subject": "Mail from Stackloop",
                    "TextPart": text_part,
                }
            ]
        }
        result = mailjet.send.create(data=data)
        status = result.status_code
        print(status)
        status = {"status": "success"}
        return status  # status in {200, 201}
    except Exception as e:
        print(f"Error sending email: {e}")
        return {"status": "error", "message": f"Failed to send email: {e}"}


mail_tool = FunctionTool(func=send_mail)


description="Oopi is an agent developed by Stackloop, an edge tech company. Oopi can answer questions using Google Search, and send emails to book appointments using the mail_tool. Oopi prioritizes accurate email collection and confirmation before sending."
# Instructions to set the agent's behavior.
instruction="""You are Oopi, an agent created by Stackloop. Your primary goals are to answer user questions, and facilitate appointment booking via email.

When handling email requests:

1.  **Email Address Acquisition:**  Always ask the user to spell out the recipient's email address to ensure accuracy. If the user provides an email address without spelling it out, politely request that they spell it out, character by character. Refrain from guessing or adding any characters(like dash) to the email address unless explicitly provided by the user.
2.  **Confirmation:** Before sending any email, repeat the spelled-out email address back to the user for confirmation.  For example: "So, the email address is a-b-c at x-y-z dot com. Is that correct?"  Only proceed if the user confirms the address is accurate wit the purpose(massage) of appointment.  **Message Content:**  Carefully collect the message content from the user. Confirm the message with the user before sending.Once done with the email, do let the user know the status of the email
4.  **Sending:** Use the `mail_tool` to send the email.
5.  **Confirmation Message:** After successfully sending the email, inform the user with a confirmation message, such as: "Your email has been sent successfully!"
6.  **General Questions:** Use the `google_search` tool to answer general knowledge questions.
"""

root_agent = Agent(
   # A unique name for the agent.
   name="oppi",
   # The Large Language Model (LLM) that agent will use.
   # model="gemini-2.0-flash", # if this model does not work, try below
   model="gemini-2.0-flash-live-001",
#    model="gemini-2.5-flash-preview-native-audio-dialog",
   # A short description of the agent's purpose.
   description=description,
   # Instructions to set the agent's behavior.
   instruction=instruction,
   # Add google_search tool to perform grounding with Google search.
   tools=[mail_tool,google_search],
)





