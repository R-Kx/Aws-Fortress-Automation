from flask import Flask, jsonify
from database import check_db_status
import os

app = Flask(__name__)

ENV = os.getenv("ENV", "DEV")

@app.route('/')
def home():
    return jsonify({
        "status": "online",
        "message": "Flask App running on AWS EC2",
        "provisioned_by": "Terraform",
        "configured_by": "Ansible"
    })

@app.route('/health')
def health():
    db_message = check_db_status()
    status_code = 200 if "Connected" in db_message else 500
    return jsonify({
        "service": "active",
        "database": db_message
    }), status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
