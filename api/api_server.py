import os
import io
import sys
import time
import json
import struct
import hashlib
import shutil
from flask import Flask, request, jsonify, send_file, session

# Add parent dir to path to import builder_core, dv_core, and db_manager
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(BASE_DIR)
sys.path.insert(0, PARENT_DIR)
sys.path.insert(0, BASE_DIR)

import builder_core
import dv_core
import db_manager

app = Flask(__name__)
app.secret_key = "regmod_api_meonxt_secret_2026"

try:
    from flask_cors import CORS
    CORS(app)
except ImportError:
    @app.after_request
    def add_cors_headers(response):
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization,X-API-Key,X-Device-HWID'
        response.headers['Access-Control-Allow-Methods'] = 'GET,PUT,POST,DELETE,OPTIONS'
        return response

API_VERSION = "v2.0.0"
CACHE_BUILDS = {}
DV_BUILDS = {}

def check_request_auth(req):
    api_key = req.headers.get('X-API-Key')
    hwid = req.headers.get('X-Device-HWID')
    
    if not api_key or not hwid:
        body = req.get_json(silent=True) or {}
        if not api_key:
            api_key = body.get('api_key') or req.args.get('api_key')
        if not hwid:
            hwid = body.get('hwid') or req.args.get('hwid')
            
    if hwid and db_manager.is_hwid_blocked(hwid):
        return False, "Thiết bị này (HWID) đã bị quản trị viên chặn truy cập!"
        
    if not api_key:
        return False, "Yêu cầu API Key hợp lệ để thực hiện thao tác tạo Cache / Shader!"
        
    is_valid, msg = db_manager.validate_api_key(api_key, hwid)
    if not is_valid:
        return False, f"API Key không hợp lệ: {msg}"
        
    return True, "Authorized"

# -------------------------------------------------------------
# 1. HEALTH & METADATA
# -------------------------------------------------------------
@app.route('/', methods=['GET'])
@app.route('/api/v1/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'online',
        'server': '103.238.234.204:5678',
        'app_name': 'Reg Mod REST API',
        'version': API_VERSION,
        'auth_required': True,
        'modules': {
            'gun_shader': 'Active (Dây Vàng FFT & FFM)',
            'hitbox_cache': 'Active (Hitbox & Magic Bullet)'
        }
    })

# -------------------------------------------------------------
# 2. AUTHENTICATION & HWID APIS
# -------------------------------------------------------------
@app.route('/api/v1/auth/register', methods=['POST'])
@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json() or {}
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        hwid = data.get('hwid', '').strip()
        ip = request.remote_addr or ''
        
        success, result = db_manager.register_user(username, password, hwid, ip)
        if success:
            return jsonify({'success': True, 'data': result})
        return jsonify({'success': False, 'error': result}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/auth/login', methods=['POST'])
@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json() or {}
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        hwid = data.get('hwid', '').strip()
        ip = request.remote_addr or ''
        
        success, result = db_manager.login_user(username, password, hwid, ip)
        if success:
            return jsonify({'success': True, 'data': result})
        return jsonify({'success': False, 'error': result}), 401
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/auth/verify_hwid', methods=['POST'])
@app.route('/api/verify_hwid', methods=['POST'])
def verify_hwid():
    try:
        data = request.get_json() or {}
        hwid = data.get('hwid', '').strip()
        blocked = db_manager.is_hwid_blocked(hwid)
        return jsonify({
            'success': True,
            'hwid': hwid,
            'is_blocked': blocked,
            'message': 'Thiết bị bị chặn' if blocked else 'Thiết bị hợp lệ'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/auth/validate_key', methods=['POST', 'GET'])
@app.route('/api/validate_key', methods=['POST', 'GET'])
def validate_key():
    try:
        key = request.headers.get('X-API-Key')
        hwid = request.headers.get('X-Device-HWID')
        if not key:
            data = request.get_json(silent=True) or {}
            key = data.get('api_key') or request.args.get('api_key')
            hwid = hwid or data.get('hwid') or request.args.get('hwid')
            
        is_valid, msg = db_manager.validate_api_key(key, hwid)
        return jsonify({
            'success': is_valid,
            'message': msg
        }), (200 if is_valid else 401)
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/auth/check_session', methods=['POST'])
@app.route('/api/check_session', methods=['POST'])
def check_session():
    """Kiểm tra xem tài khoản và thiết bị có bị khóa hoặc bị xóa khỏi hệ thống không."""
    try:
        data = request.get_json(silent=True) or {}
        username = data.get('username', '').strip()
        hwid = data.get('hwid', '').strip()
        if not username and not hwid:
            return jsonify({'success': False, 'valid': False, 'error': 'Missing credentials'}), 400
            
        if hwid and db_manager.is_hwid_blocked(hwid):
            return jsonify({'success': False, 'valid': False, 'blocked': True, 'error': 'HWID is blocked by Admin'}), 403
            
        if username:
            user = db_manager.get_user_by_username(username)
            if not user:
                return jsonify({'success': False, 'valid': False, 'deleted': True, 'error': 'Account not found or deleted'}), 401
            if user.get('is_blocked') == 1:
                return jsonify({'success': False, 'valid': False, 'blocked': True, 'error': 'Account is locked'}), 403
                
        return jsonify({'success': True, 'valid': True, 'message': 'Session is active and valid'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# -------------------------------------------------------------
# 3. GUN SHADER APIS
# -------------------------------------------------------------
@app.route('/api/v1/gun/status', methods=['GET'])
def get_gun_status():
    try:
        data = dv_core.get_dv_status()
        return jsonify({'success': True, 'data': data})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/gun/build', methods=['POST'])
def build_gun_shader():
    try:
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Unauthorized: {auth_msg}"}), 403

        body = request.get_json() or {}
        ver = body.get('version', 'fft').lower()
        mode = body.get('mode', 'mod').lower()
        options = body.get('options', {})

        data_bytes, filename, sha256, applied_changes = dv_core.get_dv_bytes(ver, mode, options)
        build_id = f"gun_{ver}_{mode}_{int(time.time() * 1000)}"

        DV_BUILDS[build_id] = {
            'bytes': data_bytes,
            'filename': filename,
            'sha256': sha256,
            'version': ver,
            'mode': mode,
            'changes': applied_changes
        }

        if len(DV_BUILDS) > 10:
            del DV_BUILDS[list(DV_BUILDS.keys())[0]]

        return jsonify({
            'success': True,
            'build_id': build_id,
            'filename': filename,
            'size': len(data_bytes),
            'sha256': sha256,
            'version': ver,
            'mode': mode,
            'download_url': f"/api/v1/gun/download/{build_id}",
            'applied_changes': applied_changes
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400

@app.route('/api/v1/gun/download/<build_id>', methods=['GET'])
def download_gun_shader(build_id):
    if build_id not in DV_BUILDS:
        return jsonify({'success': False, 'error': 'Build not found or expired'}), 404

    item = DV_BUILDS[build_id]
    return send_file(
        io.BytesIO(item['bytes']),
        mimetype='application/octet-stream',
        as_attachment=True,
        download_name=item['filename']
    )

# -------------------------------------------------------------
# 4. HITBOX CACHE APIS
# -------------------------------------------------------------
@app.route('/api/v1/hitbox/info', methods=['GET'])
def get_hitbox_info():
    try:
        base_data = builder_core.load_base_file()
        parsed = builder_core.read_values_from_bytes(base_data)
        return jsonify({
            'success': True,
            'base_size': len(base_data),
            'sha256': hashlib.sha256(base_data).hexdigest(),
            'current_values': parsed,
            'offsets': builder_core.OFFSETS,
            'formulas': builder_core.MOD_FORMULAS
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/hitbox/build', methods=['POST'])
def build_hitbox_cache():
    try:
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Unauthorized: {auth_msg}"}), 403

        body = request.get_json() or {}
        params = body.get('params', {})
        
        base_data = builder_core.load_base_file()
        mod_bytes, sha256, applied_changes = builder_core.build_mod_file(base_data, params)

        build_id = f"hitbox_{int(time.time() * 1000)}"
        CACHE_BUILDS[build_id] = {
            'bytes': mod_bytes,
            'sha256': sha256,
            'time': time.strftime("%Y-%m-%d %H:%M:%S"),
            'changes': applied_changes
        }

        if len(CACHE_BUILDS) > 10:
            del CACHE_BUILDS[list(CACHE_BUILDS.keys())[0]]

        return jsonify({
            'success': True,
            'build_id': build_id,
            'sha256': sha256,
            'size': len(mod_bytes),
            'download_url': f"/api/v1/hitbox/download/{build_id}",
            'applied_changes': applied_changes
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400

@app.route('/api/v1/hitbox/download/<build_id>', methods=['GET'])
def download_hitbox_cache(build_id):
    if build_id not in CACHE_BUILDS:
        return jsonify({'success': False, 'error': 'Build not found or expired'}), 404

    item = CACHE_BUILDS[build_id]
    return send_file(
        io.BytesIO(item['bytes']),
        mimetype='application/octet-stream',
        as_attachment=True,
        download_name=item.get('filename', builder_core.FILE_NAME)
    )

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5678))
    print(f"[*] Starting Reg Mod REST API Server on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=False)
