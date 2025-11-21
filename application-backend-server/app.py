from flask import Flask, jsonify, request
import time
import requests
import os
import json
from jose import jwt

# Cấu hình OIDC (OpenID Connect) cho xác thực
ISSUER   = os.getenv("OIDC_ISSUER", "http://authentication-identity-server:8080/realms/master")
AUDIENCE = os.getenv("OIDC_AUDIENCE", "myapp")
JWKS_URL = f"{ISSUER}/protocol/openid-connect/certs"

# Cache cho JWKS (JSON Web Key Set)
_JWKS = None
_TS = 0

def get_jwks():
    """Lấy JWKS từ Keycloak, cache 10 phút"""
    global _JWKS, _TS
    now = time.time()
    if not _JWKS or now - _TS > 600:
        try:
            _JWKS = requests.get(JWKS_URL, timeout=5).json()
            _TS = now
        except:
            pass
    return _JWKS

# Tạo Flask app
app = Flask(__name__)

@app.get("/")
def index():
    """API root - hiển thị thông tin service"""
    return jsonify(
        service="Application Backend Server",
        version="1.0",
        endpoints=["/hello", "/student", "/secure"]
    )

@app.get("/hello")
def hello():
    """API đơn giản trả về thông báo chào"""
    return jsonify(message="Hello from App Server!")

@app.get("/student")
def student():
    """API trả về danh sách sinh viên từ file JSON"""
    try:
        # Đọc file students.json
        json_path = os.path.join(os.path.dirname(__file__), 'students.json')
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return jsonify(data)
    except Exception as e:
        return jsonify(error=str(e)), 500

@app.get("/secure")
def secure():
    """API bảo mật - yêu cầu token từ Keycloak"""
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return jsonify(error="Missing Bearer token"), 401
    
    token = auth.split(" ", 1)[1]
    try:
        jwks = get_jwks()
        if not jwks:
            return jsonify(error="Cannot fetch JWKS"), 500
            
        payload = jwt.decode(
            token, 
            jwks, 
            algorithms=["RS256"], 
            audience=AUDIENCE, 
            issuer=ISSUER
        )
        return jsonify(
            message="Secure resource OK", 
            preferred_username=payload.get("preferred_username")
        )
    except Exception as e:
        return jsonify(error=str(e)), 401

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081, debug=True)