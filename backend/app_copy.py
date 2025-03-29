from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import joblib
import os
import logging
import datetime
import pytz
import requests
import re

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)

# Database Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Expense Model
class Expense(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    category = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    date = db.Column(db.DateTime, nullable=False, default=lambda: datetime.datetime.utcnow())
    source = db.Column(db.String(50), nullable=False, default="Manual")
    reference_id = db.Column(db.String(100), unique=True, nullable=True)

# Initialize database within app context
with app.app_context():
    db.create_all()

# Load ML Model
model_path = "model.pkl"
vectorizer_path = "vectorizer.pkl"

if os.path.exists(model_path) and os.path.exists(vectorizer_path):
    model = joblib.load(model_path)
    vectorizer = joblib.load(vectorizer_path)
    logging.info("ML model and vectorizer loaded successfully.")
else:
    model = None
    vectorizer = None
    logging.warning("ML Model or Vectorizer not found. Ensure 'model.pkl' and 'vectorizer.pkl' exist.")

# Function to get user's timezone from IP
def get_user_timezone():
    try:
        response = requests.get("https://ipinfo.io/json")
        if response.status_code == 200:
            data = response.json()
            timezone = data.get("timezone", "Asia/Kolkata")
            return pytz.timezone(timezone)
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
                'transaction_type': 'Credit' if 'Credited' in sms_text else 'Debit',
                'amount': float(match.group(1)),
                'date': match.group(2),
                'reference_id': match.group(3),
                'available_balance': float(match.group(4)),
                'bank_name': sender
            }
    return None

@app.route('/add_expense', methods=['POST'])
def add_expense():
    data = request.json
    if not data.get('category') or not data.get('amount'):
        return jsonify({'error': 'Category and Amount are required'}), 400
    
    try:
        new_expense = Expense(
            category=data['category'],
            amount=data['amount'],
            source=data.get('source', 'Manual'),
            reference_id=data.get('reference_id')
        )
        db.session.add(new_expense)
        db.session.commit()
        return jsonify({'message': 'Expense added successfully', 'expense_id': new_expense.id})
    except Exception as e:
        logging.error(f"Error adding expense: {str(e)}")
        return jsonify({'error': 'Failed to add expense'}), 500

@app.route('/get_expenses', methods=['GET'])
def get_expenses():
    expenses = Expense.query.all()
    user_timezone = get_user_timezone()
    expense_list = []
    
    for exp in expenses:
        try:
            utc_time = pytz.utc.localize(exp.date)
            local_time = utc_time.astimezone(user_timezone)
            expense_list.append({
                'id': exp.id,
                'category': exp.category,
                'amount': exp.amount,
                'date': local_time.strftime('%Y-%m-%d %H:%M:%S %Z'),
                'source': exp.source
            })
        except Exception as e:
            logging.error(f"Error converting time for expense ID {exp.id}: {str(e)}")

    return jsonify({'expenses': expense_list})

@app.route('/predict_category', methods=['POST'])
def predict_category():
    if model is None or vectorizer is None:
        return jsonify({'error': 'ML Model is not loaded'}), 500
    
    data = request.json
    if not data.get('description'):
        return jsonify({'error': 'Description is required'}), 400
    
    try:
        text_vector = vectorizer.transform([data['description']])
        prediction = model.predict(text_vector)[0]
        return jsonify({'predicted_category': prediction})
    except Exception as e:
        logging.error(f"Error predicting category: {str(e)}")
        return jsonify({'error': 'Prediction failed'}), 500

@app.route('/parse_sms', methods=['POST'])
def parse_sms():
    data = request.json
    sms_text = data.get('sms')
    sender = data.get('sender')

    if not sms_text or not sender:
        return jsonify({'error': 'SMS text and sender details are required'}), 400
    
    transaction = parse_transaction_sms(sms_text, sender)
    if transaction is None:
        return jsonify({'error': 'No valid transaction detected'}), 400
    
    existing_transaction = Expense.query.filter_by(reference_id=transaction['reference_id']).first()
    if existing_transaction:
        return jsonify({'error': 'Duplicate transaction detected'}), 409
    
    return jsonify(transaction)

if __name__ == '__main__':
    app.run(debug=True)
