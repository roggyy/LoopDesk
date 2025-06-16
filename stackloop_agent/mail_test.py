
# from mailjet_rest import Client
# import os
# api_key = "ca5a8602d1ad743db9b6a4b1f99b6864" #os.environ['MJ_APIKEY_PUBLIC']
# api_secret = "e8baf4c4e1528d152edb92a36e54d873" #os.environ['MJ_APIKEY_PRIVATE']
# mailjet = Client(auth=(api_key, api_secret), version='v3.1')
# data = {
#   'Messages': [
# 				{
# 						"From": {
# 								"Email": "aniketguptarog@gmail.com",
# 								"Name": "Me"
# 						},
# 						"To": [
# 								{
# 										"Email": "abhijeetg375@gmail.com",
# 										"Name": "You"
# 								}
# 						],
# 						"Subject": "My first Mailjet Email!",
# 						"TextPart": "Greetings from Mailjet!",
# 						"HTMLPart": "<h3>Dear passenger 1, welcome to <a href=\"https://www.mailjet.com/\">Mailjet</a>!</h3><br />May the delivery force be with you!"
# 				}
# 		]
# }
# result = mailjet.send.create(data=data)
# print(result.status_code)
# print(result.json())


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
    Send a plain-text email via Mailjet.
    Returns True if the request succeeded (status 200 or 201), else False.
    """
    data = {
        "Messages": [
            {
                "From": {"Email": os.environ.get("MAILJET_FROM_EMAIL", "aniketguptarog@gmail.com"), "Name": "Me"},
                "To": [{"Email": to_email}],
                "Subject": "Mail from Mailjet",
                "TextPart": text_part
            }
        ]
    }
    result = mailjet.send.create(data=data)
    status = result.status_code
    print(f"Mailjet response status: {status}")
    return status in {200, 201}


success = send_mail("abhijeetg375@gmail.com", "Hello from Mailjet!")
print("Sent!" if success else "Failed to send.")
