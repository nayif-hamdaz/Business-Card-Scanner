import os
import json
import base64
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
from dotenv import load_dotenv
import gspread
from google.oauth2.service_account import Credentials
import openpyxl
from io import BytesIO

# --- Configuration ---
load_dotenv()
try:
    client = OpenAI()
except Exception as e:
    raise ValueError(f"Failed to initialize OpenAI client. Is OPENAI_API_KEY set? Error: {e}")

# --- Google Sheets Configuration ---
SCOPES = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file'
]
SPREADSHEET_ID = "1_UHVEejnKhaaT2a0KJ4II5DqEOy3wSvsIkbWVB9BtHI" # Replace with your Sheet ID

if os.path.exists('credentials.json'):
    creds = Credentials.from_service_account_file('credentials.json', scopes=SCOPES)
    gc = gspread.authorize(creds)
    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    worksheet = spreadsheet.sheet1
else:
    print("WARNING: credentials.json not found. Google Sheets integration will not work.")
    worksheet = None

app = Flask(__name__)
CORS(app)

# --- Main Route for Live Check ---
@app.route('/')
def index():
    return "Card Scanner Backend is live and running."

# --- Helper function to get mime type ---
def get_mime_type(file_storage):
    if file_storage.filename.lower().endswith('.png'):
        return 'image/png'
    elif file_storage.filename.lower().endswith(('.jpg', '.jpeg')):
        return 'image/jpeg'
    return 'application/octet-stream' # default

# --- API Endpoints ---
@app.route('/scan-card', methods=['POST'])
def scan_card():
    if 'front' not in request.files:
        return jsonify({"error": "No 'front' image file found in the request."}), 400

    front_file = request.files['front']
    back_file = request.files.get('back') # .get() safely returns None if not found

    try:
        # Prepare content for OpenAI Vision API
        messages_content = []
        system_prompt = """
        You are an expert business card data extractor. You will be given an image of a business card.
        Your job is to read the text and extract key information in a structured JSON format.
        The fields to extract are: organization, name, designation, contact, email, website, and address.
        If a field is not found, use an empty string "" as its value.
        Your response MUST be ONLY the JSON object, with no extra text, explanations, or markdown formatting.
        """ # Same prompt as before
        messages_content.append({"type": "text", "text": system_prompt})

        # Process front image
        front_bytes = front_file.read()
        front_base64 = base64.b64encode(front_bytes).decode('utf-8')
        front_mime_type = get_mime_type(front_file)
        messages_content.append({
            "type": "image_url",
            "image_url": {"url": f"data:{front_mime_type};base64,{front_base64}"}
        })

        # Process back image if it exists
        if back_file:
            back_bytes = back_file.read()
            back_base64 = base64.b64encode(back_bytes).decode('utf-8')
            back_mime_type = get_mime_type(back_file)
            messages_content.append({
                "type": "image_url",
                "image_url": {"url": f"data:{back_mime_type};base64,{back_base64}"}
            })

        # Call OpenAI
        response = client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=[{"role": "user", "content": messages_content}]
        )

        json_string = response.choices[0].message.content
        if json_string is None:
            return jsonify({"error": "AI model did not return any data."}), 500

        parsed_data = json.loads(json_string)
        parsed_data['remarks'] = '' # Ensure remarks field is always present
        return jsonify(parsed_data)

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"error": f"An unexpected error occurred: {e}"}), 500


@app.route('/save-contact', methods=['POST'])
def save_contact():
    if not worksheet:
        return jsonify({"error": "Backend not configured for Google Sheets."}), 500
    contact_data = request.json
    try:
        all_rows = worksheet.get_all_values()
        sl_no = len(all_rows)
        new_row = [
            sl_no,
            contact_data.get('organization', ''),
            contact_data.get('name', ''),
            contact_data.get('designation', ''),
            contact_data.get('contact', ''),
            contact_data.get('email', ''),
            contact_data.get('website', ''),
            contact_data.get('address', ''),
            contact_data.get('remarks', '')
        ]
        worksheet.append_row(new_row)
        return jsonify({"status": "success", "message": f"Contact #{sl_no} saved to Google Sheets."})
    except Exception as e:
        return jsonify({"error": f"An error occurred saving to Google Sheets: {e}"}), 500

# Download excel endpoint (unchanged)
@app.route('/download-excel', methods=['GET'])
def download_excel():
    # ... (code for this function remains the same)
    pass # Placeholder to keep the structure

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
