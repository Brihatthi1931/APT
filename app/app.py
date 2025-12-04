from flask import Flask, jsonify
import logging
import sys

app = Flask(__name__)

# Setup logging to stdout (Source 93)
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

@app.route('/')
def home():
    app.logger.info("Home endpoint called")
    return "Hello! The architecture is successfully deployed."

@app.route('/health')
def health():
    app.logger.info("Health check called")
    return jsonify(status="ok") # (Source 92)

if __name__ == '__main__':
    # Run on port 8080 (Source 92)
    app.run(host='0.0.0.0', port=8080)