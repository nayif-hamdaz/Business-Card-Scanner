import os
import json
import base64
import requests
import msal
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
from dotenv import load_dotenv

# --- Configuration ---
load_dotenv()

# --- Initialize OpenAI ---
try:
    client = OpenAI()
except Exception as e:
    raise ValueError(f"Failed to initialize OpenAI client. Is OPENAI_API_KEY set? Error: {e}")

# --- Microsoft Graph API Configuration ---
TENANT_ID = os.getenv("TENANT_ID")
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")
USER_ID = os.getenv("USER_ID")

EXCEL_FILE_NAME = "Contacts.xlsx"
EXCEL_TABLE_NAME = "Table1" 

MS_GRAPH_AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
MS_GRAPH_SCOPE = ["https://graph.microsoft.com/.default"]

# Initialize MSAL client
msal_app = msal.ConfidentialClientApplication(
    CLIENT_ID, authority=MS_GRAPH_AUTHORITY, client_credential=CLIENT_SECRET
)

# --- Flask App Initialization ---
app = Flask(__name__)
CORS(app)

# --- Helper function to get an Access Token ---
def get_access_token():
    result = msal_app.acquire_token_silent(MS_GRAPH_SCOPE, account=None)
    if not result:
        print("No suitable token in cache, acquiring a new one...")
        result = msal_app.acquire_token_for_client(scopes=MS_GRAPH_SCOPE)
    if "access_token" in result:
        return result["access_token"]
    else:
        print(result.get("error"))
        print(result.get("error_description"))
        print(result.get("correlation_id"))
        return None

# --- Helper function to get mime type ---
def get_mime_type(file_storage):
    filename = file_storage.filename.lower()
    if filename.endswith('.png'): return 'image/png'
    if filename.endswith(('.jpg', '.jpeg')): return 'image/jpeg'
    if filename.endswith('.gif'): return 'image/gif'
    if filename.endswith('.bmp'): return 'image/bmp'
    if filename.endswith('.webp'): return 'image/webp'
    if filename.endswith('.heic'): return 'image/heic'
    return 'application/octet-stream'

# --- API Endpoints ---
@app.route('/')
def index():
    # A simple endpoint to confirm the API is live.
    return "Business Card Scanner API is live and running."

@app.route('/scan-card', methods=['POST'])
def scan_card():
    if 'front' not in request.files:
        return jsonify({"error": "No 'front' image file found in the request."}), 400

    front_file = request.files['front']
    back_file = request.files.get('back')

    try:
        messages_content = []
        system_prompt = """
        You are an expert business card data extractor. Your job is to analyze the business card and extract key information in a structured JSON format.
        First, determine the business's category (e.g., Services, Vendor, Distributor, Infrastructure, Reseller, Technology, etc.).
        The fields to extract are: category, organization, name, designation, contact, email, website, and address.
        If a field is not found, use an empty string "" as its value.
        Your response MUST be ONLY the JSON object, with no extra text or markdown formatting.
        """
        messages_content.append({"type": "text", "text": system_prompt})

        front_bytes = front_file.read()
        front_base64 = base64.b64encode(front_bytes).decode('utf-8')
        front_mime_type = get_mime_type(front_file)
        messages_content.append({
            "type": "image_url",
            "image_url": {"url": f"data:{front_mime_type};base64,{front_base64}"}
        })

        if back_file and back_file.filename:
            back_bytes = back_file.read()
            back_base64 = base64.b64encode(back_bytes).decode('utf-8')
            back_mime_type = get_mime_type(back_file)
            messages_content.append({
                "type": "image_url",
                "image_url": {"url": f"data:{back_mime_type};base64,{back_base64}"}
            })

        response = client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=[{"role": "user", "content": messages_content}]
        )

        json_string = response.choices[0].message.content
        parsed_data = json.loads(json_string or '{}')
        
        parsed_data.setdefault('category', '')
        parsed_data.setdefault('remarks', '')
        
        return jsonify(parsed_data)

    except Exception as e:
        print(f"An error occurred during scanning: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/save-contact', methods=['POST'])
def save_contact():
    contact_data = request.json
    print("Received data to save:", contact_data)

    access_token = get_access_token()
    if not access_token:
        return jsonify({"error": "Failed to acquire access token."}), 500

    row_values = [
        contact_data.get('category', ''),
        contact_data.get('organization', ''),
        contact_data.get('name', ''),
        contact_data.get('designation', ''),
        contact_data.get('contact', ''),
        contact_data.get('email', ''),
        contact_data.get('website', ''),
        contact_data.get('address', ''),
        contact_data.get('remarks', '')
    ]

    graph_url = f"https://graph.microsoft.com/v1.0/users/{USER_ID}/drive/root:/{EXCEL_FILE_NAME}:/workbook/tables/{EXCEL_TABLE_NAME}/rows"

    headers = { 'Authorization': 'Bearer ' + access_token, 'Content-Type': 'application/json' }
    payload = { "values": [row_values] }
    response = requests.post(graph_url, headers=headers, json=payload)

    if response.status_code == 201:
        print("Successfully added row to Excel.")
        return jsonify({"status": "success", "message": "Contact saved to SharePoint Excel."})
    else:
        print(f"Failed to add row. Status: {response.status_code}, Body: {response.text}")
        return jsonify({"error": "Failed to save to SharePoint.", "details": response.json()}), response.status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)

