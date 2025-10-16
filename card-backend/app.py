import os
import json
import base64
import requests
import msal
import httpx
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor

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
# We assume the data is on 'Sheet1'. This can be changed if needed.
WORKSHEET_NAME = "Sheet1" 

MS_GRAPH_AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
MS_GRAPH_SCOPE = ["https://graph.microsoft.com/.default"]

# Create a requests session with a timeout
session = requests.Session()
session.timeout = 15

# Initialize MSAL client with the configured session using the correct keyword
msal_app = msal.ConfidentialClientApplication(
    CLIENT_ID,
    authority=MS_GRAPH_AUTHORITY,
    client_credential=CLIENT_SECRET,
    http_client=session
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
        print(result.get("error"), result.get("error_description"))
        return None

# --- Helper function to get mime type ---
def get_mime_type(file_storage):
    filename = file_storage.filename.lower()
    if filename.endswith('.png'):
        return 'image/png'
    elif filename.endswith(('.jpg', '.jpeg')):
        return 'image/jpeg'
    elif filename.endswith('.gif'):
        return 'image/gif'
    elif filename.endswith('.bmp'):
        return 'image/bmp'
    elif filename.endswith('.webp'):
        return 'image/webp'
    elif filename.endswith('.heic'):
        return 'image/heic'
    return 'application/octet-stream'

# Helper function to process a single image with OpenAI
def _process_image(image_file):
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

        image_bytes = image_file.read()
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        image_mime_type = get_mime_type(image_file)
        messages_content.append({
            "type": "image_url",
            "image_url": {"url": f"data:{image_mime_type};base64,{image_base64}"}
        })

        response = client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=[{"role": "user", "content": messages_content}]
        )

        json_string = response.choices[0].message.content
        return json.loads(json_string or '{}')
    except Exception as e:
        print(f"Error processing image {image_file.filename}: {e}")
        return {"error": f"Failed to process image {image_file.filename}"}

# --- API Endpoints ---
@app.route('/')
def index():
    return "Business Card Scanner API is live and running."

@app.route('/scan-batch', methods=['POST'])
def scan_batch():
    if 'images' not in request.files:
        return jsonify({"error": "No 'images' file part found in the request."}), 400
    
    image_files = request.files.getlist('images')
    results = []

    with ThreadPoolExecutor() as executor:
        future_results = executor.map(_process_image, image_files)
        for result in future_results:
            results.append(result)

    return jsonify(results)


@app.route('/save-contact', methods=['POST'])
def save_contact():
    contact_data = request.json
    print("Received data to save:", contact_data)

    access_token = get_access_token()
    if not access_token:
        return jsonify({"error": "Failed to acquire access token."}), 500

    headers = { 'Authorization': 'Bearer ' + access_token, 'Content-Type': 'application/json' }
    
    # THE FINAL FIX: Step 1 - Get the used range, considering only cells with values.
    get_used_range_url = f"https://graph.microsoft.com/v1.0/users/{USER_ID}/drive/root:/{EXCEL_FILE_NAME}:/workbook/worksheets('{WORKSHEET_NAME}')/usedRange(valuesOnly=true)"
    
    try:
        response = requests.get(get_used_range_url, headers=headers, timeout=15)
        response.raise_for_status() 
    except requests.exceptions.RequestException as e:
        print(f"Failed to get used range. Error: {e}")
        return jsonify({"error": "Failed to connect to Microsoft Graph to get worksheet size."}), 500

    used_range_data = response.json()
    # The number of rows in the used range tells us where the last data is.
    last_data_row = used_range_data.get('rowCount', 0)
    print(f"Found last data at row: {last_data_row}")

    # THE FINAL FIX: Step 2 - Calculate the next available row address.
    # The new row will be immediately after the last data row.
    next_row = last_data_row + 1
    
    # We need to know the number of columns to create the correct range
    column_count = 10 # Category, Organization, Name, Designation, Contact, Email, Website, Address, Remarks, ContactType
    last_column_letter = chr(ord('A') + column_count - 1)
    
    # The range where we will write the new data (e.g., A18:J18)
    target_range = f"A{next_row}:{last_column_letter}{next_row}"
    print(f"Calculated target range for new data: {target_range}")

    # The order MUST match the columns in your Excel file exactly.
    row_values = [
        [ # This must be a list of lists for writing to a range
            contact_data.get('category', ''),
            contact_data.get('organization', ''),
            contact_data.get('name', ''),
            contact_data.get('designation', ''),
            contact_data.get('contact', ''),
            contact_data.get('email', ''),
            contact_data.get('website', ''),
            contact_data.get('address', ''),
            contact_data.get('remarks', ''),
            contact_data.get('ContactType', '')
        ]
    ]

    # THE FINAL FIX: Step 3 - Use PATCH to write to the calculated specific range.
    update_range_url = f"https://graph.microsoft.com/v1.0/users/{USER_ID}/drive/root:/{EXCEL_FILE_NAME}:/workbook/worksheets('{WORKSHEET_NAME}')/range(address='{target_range}')"
    
    payload = { "values": row_values }
    
    try:
        response = requests.patch(update_range_url, headers=headers, json=payload, timeout=15)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Failed to update range. Error: {e}")
        return jsonify({"error": "Failed to connect to Microsoft Graph to save data."}), 500


    if response.status_code == 200:
        print("Successfully updated range in Excel.")
        return jsonify({"status": "success", "message": "Contact saved to SharePoint Excel."})
    else:
        print(f"Failed to update range. Status: {response.status_code}, Body: {response.text}")
        return jsonify({"error": "Failed to save to SharePoint.", "details": response.json()}), response.status_code


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)

