import os
import logging
import datetime
import pytz
import requests
import re
from werkzeug.security import generate_password_hash, check_password_hash
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.transport.requests import Request
from google.oauth2 import service_account
from googleapiclient.errors import HttpError
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import joblib
from sqlalchemy import text

# Initialize app and config
app = Flask(__name__)

# Setup logging
logging.basicConfig(level=logging.INFO)

# Config for SQLite and JWT
db_path = os.path.abspath("./final.db")
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{db_path}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["JWT_SECRET_KEY"] = "super-secret-key"  
jwt = JWTManager(app)

# Initialize the database
db = SQLAlchemy(app)

# Set up rate limiting
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["200 per day", "50 per hour"]
)

# User Model
class User(db.Model):
    __tablename__ = 'users'

    user_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), nullable=False, unique=True)
    pin_hash = db.Column(db.String(200), nullable=False)

# Account Model
class Account(db.Model):
    __tablename__ = 'accounts'

    account_id = db.Column(db.Integer, primary_key=True)
    account_name = db.Column(db.String(100), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)

# Category Model
class Category(db.Model):
    __tablename__ = 'categories'

    category_id = db.Column(db.Integer, primary_key=True)
    category_name = db.Column(db.String(100), nullable=False, unique=True)

# Transaction Model
class Transaction(db.Model):
    __tablename__ = 'transactions'

    transaction_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    account_id = db.Column(db.Integer, db.ForeignKey('accounts.account_id'), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.category_id'), nullable=True)
    amount = db.Column(db.Float, nullable=False)
    transaction_type = db.Column(db.String(10), nullable=False)
    description = db.Column(db.Text, nullable=True)
    transaction_date = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    transaction_metadata = db.Column(db.Text, nullable=True)

# OCR Result Model
class OcrResult(db.Model):
    __tablename__ = 'ocr_results'
    result_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    ocr_output = db.Column(db.Text, nullable=False)
    transaction_id = db.Column(db.Integer, db.ForeignKey('transactions.transaction_id'), nullable=True)

# Google Drive API setup
SERVICE_ACCOUNT_FILE = os.path.expanduser("~/Desktop/google-drive-key.json")
SCOPES = ['https://www.googleapis.com/auth/drive']
credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
drive_service = build('drive', 'v3', credentials=credentials)

# Load ML Model
model_path = "/Users/vanshoberoi/Desktop/model.pkl"
model = joblib.load(model_path) if os.path.exists(model_path) else None
if model:
    logging.info("ML model loaded successfully.")
else:
    logging.warning("ML Model not found. Ensure the necessary file exists.")

# Ensure all tables exist before running the app
with app.app_context():
    db.create_all()

# Test Database Connection
with app.app_context():
    try:
        db.session.execute(text('SELECT 1'))
        logging.info("✅ Database connection successful!")
    except Exception as e:
        logging.error(f"❌ Database connection failed: {e}")

# Function to upload image to Google Drive and run OCR
def upload_image_and_ocr(image_path=None):
    file_id = None  # Initialize file_id to handle edge case if upload fails
    try:
        # If no image_path is provided, skip the process without any notification
        if image_path is None:
            return None  # No image to process, simply move on
        
        # Step 1: Upload image to Google Drive
        file_metadata = {'name': os.path.basename(image_path)}
        media = MediaFileUpload(image_path, mimetype='image/jpeg')
        file = drive_service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        file_id = file.get('id')  # Get file ID from the upload response
        
        # Step 2: Set permissions to make the file publicly accessible temporarily
        drive_service.permissions().create(
            fileId=file_id,
            body={'type': 'anyone', 'role': 'reader'}
        ).execute()
        
        # Get the URL of the uploaded file for OCR
        file_url = f"https://drive.google.com/uc?id={file_id}"

        # Step 3: Perform OCR (replace with your actual OCR logic)
        ocr_result = run_your_model(file_url)
        
    except HttpError as e:
        logging.error(f"Google Drive API error: {str(e)}")
        raise Exception("Error uploading image to Google Drive or during OCR.")
    
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        raise Exception("Unexpected error occurred during OCR processing.")
    
    finally:
        # Step 4: Clean up by deleting the image from Google Drive after processing
        if file_id:
            try:
                drive_service.files().delete(fileId=file_id).execute()
            except HttpError as e:
                logging.error(f"Error deleting file from Google Drive: {str(e)}")
        
        # Optionally, if the image was temporarily saved on the server, remove it
        if image_path and os.path.exists(image_path):  # Check if the file exists
            try:
                os.remove(image_path)
            except OSError as e:
                logging.error(f"Error deleting temporary file {image_path}: {str(e)}")

    if image_path:
        date, amount, category = run_your_model(file_url)
        return date, amount, category
    else:
        return None, None, None

    
        # Store the OCR result in the database
        ocr_text_summary = f"Date: {date}, Amount: {amount}, Category: {category}"
        new_result = OcrResult(user_id=current_user_id, ocr_output=ocr_text_summary)
        db.session.add(new_result)
        db.session.commit()

        return jsonify({
            "message": "OCR processed successfully.",
            "data": {
                "date": date,
                "amount": amount,
                "category": category
            }
        }), 200

    except Exception as e:
        logging.error(f"OCR route error: {str(e)}")
        return jsonify({"error": "An error occurred during OCR processing."}), 500

def run_your_model(file_url):
    if model:
        result = model.predict([file_url])  # simulate call
        result_dict = result[0]  # your output is a list of dicts
        return (
            result_dict.get("date", "Not found"),
            result_dict.get("total_amount", "Not found"),
            result_dict.get("category", "Not found")
        )
    else:
        raise Exception("Model is not loaded properly.")

# Function to get user's timezone from IP
def get_user_timezone():
    try:
        response = requests.get("https://ipinfo.io/json", timeout=3)
        if response.status_code == 200:
            data = response.json()
            timezone_str = data.get("timezone", "Asia/Kolkata")
            if timezone_str in pytz.all_timezones:
                return pytz.timezone(timezone_str)
    except Exception as e:
        logging.error(f"Failed to get timezone from IP: {str(e)}")
    
    return pytz.timezone("Asia/Kolkata")


# Secure SMS Parsing
def parse_transaction_sms(sms_text, sender):
    allowed_senders = ["UnionBank", "SBI", "HDFC", "ICICI", "AxisBank"]
    if sender not in allowed_senders:
        return None

    transaction_patterns = [
        r'A/c.*Credited for Rs:(\d+\.\d+).*on (\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2}).*Ref No: (\d+).*Avl Bal Rs:(\d+\.\d+)',
        r'A/c.*Debited for Rs:(\d+\.\d+).*on (\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2}).*Ref No: (\d+).*Avl Bal Rs:(\d+\.\d+)'
    ]

    for pattern in transaction_patterns:
        match = re.search(pattern, sms_text)
        if match:
            return {
                'transaction_type': 'income' if 'Credited' in sms_text else 'expense',
                'amount': float(match.group(1)),
                'date': match.group(2),
                'reference_id': match.group(3),
                'available_balance': float(match.group(4)),
                'bank_name': sender
            }
    return None

@app.route('/register_user', methods=['POST'])
def register_user():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    pin = data.get('pin')
    confirm_pin = data.get('confirm_pin')

    if not all([username, email, pin, confirm_pin]):
        return jsonify({'error': 'All fields are required'}), 400

    if pin != confirm_pin:
        return jsonify({'error': 'PIN and Confirm PIN do not match'}), 400

    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({'error': 'Email already registered'}), 409

    try:
        pin_hash = generate_password_hash(pin)
        new_user = User(username=username, email=email, pin_hash=pin_hash)
        db.session.add(new_user)
        db.session.commit()

        access_token = create_access_token(identity=new_user.user_id)
        return jsonify({
            'message': 'User registered successfully',
            'access_token': access_token,
            'user_id': new_user.user_id
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to register user: {str(e)}'}), 500


@app.route('/login', methods=['POST'])
@limiter.limit("5 per minute")  # ⛔ max 5 attempts per minute per IP
def login():
    data = request.get_json()
    pin = data.get('pin')

    if not pin or len(pin) != 4 or not pin.isdigit():
        return jsonify({'error': 'PIN must be 4 digits'}), 400

    user = next((u for u in User.query.all() if check_password_hash(u.pin_hash, pin)), None)
    if user:
        access_token = create_access_token(identity=user.user_id)
        return jsonify({
            'message': 'Login successful',
            'access_token': access_token,
            'username': user.username,
            'user_id': user.user_id
        }), 200

    return jsonify({'error': 'Incorrect PIN'}), 401

     
@app.route('/add_expense', methods=['POST'])
@jwt_required()
def add_expense():
    current_user_id = get_jwt_identity()
    data = request.json
    if not data.get('amount') or not data.get('account_id'):
        return jsonify({'error': 'Account ID and Amount are required'}), 400

    try:
        category_id = data.get('category_id')
        if not category_id:
            others_category = Category.query.filter_by(category_name='Others').first()
            if not others_category:
                others_category = Category(category_name='Others')
                db.session.add(others_category)
                db.session.commit()
            category_id = others_category.category_id

        new_transaction = Transaction(
            user_id=current_user_id,
            account_id=data['account_id'],
            category_id=category_id,
            amount=data['amount'],
            transaction_type='expense',
            description=data.get('description', ''),
            transaction_metadata=data.get('metadata')
        )
        db.session.add(new_transaction)
        db.session.commit()

        return jsonify({'message': 'Expense added successfully', 'transaction_id': new_transaction.transaction_id})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to add expense'}), 500

@app.route('/get_expenses',methods=['GET'])
@jwt_required()

def get_expenses():
    current_user_id = get_jwt_identity()
    transactions = Transaction.query.filter_by(user_id=current_user_id, transaction_type='expense').all()
    user_timezone = get_user_timezone()
    expense_list = []

    for trans in transactions:
        try:
            # Convert UTC time to user's local time
            if trans.transaction_date.tzinfo is None:
                utc_time = pytz.utc.localize(trans.transaction_date)
            else:
                utc_time = trans.transaction_date.astimezone(pytz.utc)

            local_time = utc_time.astimezone(user_timezone)

            expense_list.append({
                'transaction_id': trans.transaction_id,
                'account_id': trans.account_id,
                'category_id': trans.category_id,
                'amount': trans.amount,
                'description': trans.description,
                'transaction_date': local_time.strftime("%Y-%m-%d %H:%M:%S"),
                'metadata': trans.transaction_metadata
            })
        except Exception as e:
            logging.error(f"Error processing transaction {trans.transaction_id}: {str(e)}")

    return jsonify(expense_list), 200


@app.route('/predict_category', methods=['POST'])
def predict_category():
    if model is None:
        return jsonify({'error': 'ML Model is not loaded'}), 500

    data = request.json
    if not data.get('description'):
        return jsonify({'error': 'Description is required'}), 400

    try:
        prediction = model.predict([data['description']])[0]

        # Get category_id from database
        category = db.session.execute(
            text("SELECT category_id FROM categories WHERE category_name = :name"),
            {"name": prediction}
        ).fetchone()

        if category:
            return jsonify({'predicted_category': prediction, 'category_id': category[0]})
        else:
            return jsonify({'predicted_category': prediction, 'category_id': None})
    except Exception as e:
        logging.error(f"Error predicting category: {str(e)}")
        return jsonify({'error': 'Prediction failed'}), 500


@app.route('/parse_sms', methods=['POST'])
def parse_sms():
    data = request.json
    sms_text = data.get('sms_text')
    sender = data.get('sender')

    if not sms_text or not sender:
        return jsonify({'error': 'Missing sms_text or sender'}), 400

    parsed_data = parse_transaction_sms(sms_text, sender)
    if parsed_data:
        return jsonify(parsed_data)
    else:
        return jsonify({'error': 'Unable to parse SMS'}), 400
    
if __name__ == '__main__':
    app.run(debug=True)
