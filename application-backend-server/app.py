from flask import Flask, jsonify, request
import json
import os
import requests
from jose import jwt, JWTError
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)

# ============================================================
# CONFIGURATION
# ============================================================
OIDC_ISSUER = os.getenv('OIDC_ISSUER', 'http://authentication-identity-server:8080/realms/master')
OIDC_AUDIENCE = os.getenv('OIDC_AUDIENCE', 'myapp')

# Database configuration
DB_CONFIG = {
    'host': 'relational-database-server',
    'user': 'root',
    'password': 'root',
    'database': 'studentdb'
}

# ============================================================
# DATABASE HELPER FUNCTIONS
# ============================================================
def get_db_connection():
    """Create database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Error connecting to database: {e}")
        return None

def execute_query(query, params=None, fetch=True):
    """Execute database query"""
    connection = get_db_connection()
    if not connection:
        return None
    
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params or ())
        
        if fetch:
            result = cursor.fetchall()
        else:
            connection.commit()
            result = cursor.rowcount
        
        cursor.close()
        connection.close()
        return result
    except Error as e:
        print(f"Database error: {e}")
        if connection:
            connection.close()
        return None

# ============================================================
# AUTHENTICATION HELPER
# ============================================================
def verify_token(token):
    """Verify JWT token from Keycloak"""
    try:
        # Fetch JWKS from Keycloak
        jwks_url = f"{OIDC_ISSUER}/protocol/openid-connect/certs"
        jwks = requests.get(jwks_url, timeout=5).json()
        
        # Decode and verify token
        header = jwt.get_unverified_header(token)
        key = None
        for jwk in jwks['keys']:
            if jwk['kid'] == header['kid']:
                key = jwk
                break
        
        if not key:
            return None
        
        payload = jwt.decode(
            token,
            key,
            algorithms=['RS256'],
            audience=OIDC_AUDIENCE,
            options={"verify_aud": False}
        )
        return payload
    except Exception as e:
        print(f"Token verification error: {e}")
        return None

# ============================================================
# BASIC ENDPOINTS
# ============================================================
@app.route('/hello', methods=['GET'])
def hello():
    """Simple hello endpoint"""
    return jsonify({
        "message": "Hello from Application Backend Server!",
        "status": "running"
    })

@app.route('/secure', methods=['GET'])
def secure():
    """Secure endpoint requiring authentication"""
    auth_header = request.headers.get('Authorization')
    
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "Missing Bearer token"}), 401
    
    token = auth_header.split(' ')[1]
    payload = verify_token(token)
    
    if not payload:
        return jsonify({"error": "Invalid token"}), 401
    
    return jsonify({
        "message": "Secure resource OK",
        "preferred_username": payload.get('preferred_username'),
        "email": payload.get('email')
    })

# ============================================================
# STUDENT CRUD ENDPOINTS (EXTENSION)
# ============================================================

@app.route('/students', methods=['GET'])
def get_students():
    """Get all students"""
    query = "SELECT * FROM students ORDER BY created_at DESC"
    students = execute_query(query)
    
    if students is None:
        return jsonify({"error": "Database error"}), 500
    
    return jsonify({
        "total": len(students),
        "students": students
    })

@app.route('/students/<student_id>', methods=['GET'])
def get_student(student_id):
    """Get student by ID"""
    query = "SELECT * FROM students WHERE student_id = %s"
    students = execute_query(query, (student_id,))
    
    if students is None:
        return jsonify({"error": "Database error"}), 500
    
    if len(students) == 0:
        return jsonify({"error": "Student not found"}), 404
    
    return jsonify(students[0])

@app.route('/students', methods=['POST'])
def create_student():
    """Create new student"""
    data = request.get_json()
    
    # Validate required fields
    required_fields = ['student_id', 'fullname']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400
    
    query = """
        INSERT INTO students (student_id, fullname, dob, major, gpa)
        VALUES (%s, %s, %s, %s, %s)
    """
    params = (
        data['student_id'],
        data['fullname'],
        data.get('dob'),
        data.get('major'),
        data.get('gpa')
    )
    
    result = execute_query(query, params, fetch=False)
    
    if result is None:
        return jsonify({"error": "Failed to create student"}), 500
    
    return jsonify({
        "message": "Student created successfully",
        "student_id": data['student_id']
    }), 201

@app.route('/students/<student_id>', methods=['PUT'])
def update_student(student_id):
    """Update student"""
    data = request.get_json()
    
    # Check if student exists
    check_query = "SELECT * FROM students WHERE student_id = %s"
    existing = execute_query(check_query, (student_id,))
    
    if not existing or len(existing) == 0:
        return jsonify({"error": "Student not found"}), 404
    
    # Build update query
    update_fields = []
    params = []
    
    if 'fullname' in data:
        update_fields.append("fullname = %s")
        params.append(data['fullname'])
    if 'dob' in data:
        update_fields.append("dob = %s")
        params.append(data['dob'])
    if 'major' in data:
        update_fields.append("major = %s")
        params.append(data['major'])
    if 'gpa' in data:
        update_fields.append("gpa = %s")
        params.append(data['gpa'])
    
    if not update_fields:
        return jsonify({"error": "No fields to update"}), 400
    
    params.append(student_id)
    query = f"UPDATE students SET {', '.join(update_fields)} WHERE student_id = %s"
    
    result = execute_query(query, params, fetch=False)
    
    if result is None:
        return jsonify({"error": "Failed to update student"}), 500
    
    return jsonify({"message": "Student updated successfully"})

@app.route('/students/<student_id>', methods=['DELETE'])
def delete_student(student_id):
    """Delete student"""
    query = "DELETE FROM students WHERE student_id = %s"
    result = execute_query(query, (student_id,), fetch=False)
    
    if result is None:
        return jsonify({"error": "Failed to delete student"}), 500
    
    if result == 0:
        return jsonify({"error": "Student not found"}), 404
    
    return jsonify({"message": "Student deleted successfully"})

@app.route('/students/search', methods=['GET'])
def search_students():
    """Search students by major or name"""
    major = request.args.get('major')
    name = request.args.get('name')
    
    if major:
        query = "SELECT * FROM students WHERE major LIKE %s"
        params = (f"%{major}%",)
    elif name:
        query = "SELECT * FROM students WHERE fullname LIKE %s"
        params = (f"%{name}%",)
    else:
        return jsonify({"error": "Missing search parameter (major or name)"}), 400
    
    students = execute_query(query, params)
    
    if students is None:
        return jsonify({"error": "Database error"}), 500
    
    return jsonify({
        "total": len(students),
        "students": students
    })

# ============================================================
# STATISTICS ENDPOINT
# ============================================================
@app.route('/stats', methods=['GET'])
def get_stats():
    """Get statistics"""
    queries = {
        'total_students': "SELECT COUNT(*) as count FROM students",
        'avg_gpa': "SELECT AVG(gpa) as avg_gpa FROM students",
        'by_major': "SELECT major, COUNT(*) as count FROM students GROUP BY major"
    }
    
    stats = {}
    for key, query in queries.items():
        result = execute_query(query)
        if result:
            if key == 'by_major':
                stats[key] = result
            else:
                stats[key] = result[0] if result else None
    
    return jsonify(stats)

# ============================================================
# RUN SERVER
# ============================================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081, debug=True)