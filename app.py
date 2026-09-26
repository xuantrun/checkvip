import os
import io
import time
import json
import hashlib
import shutil
import sys
import socket
from flask import Flask, render_template, request, jsonify, send_file, session
import builder_core
import dv_core
import db_manager
import avatar_core

PORT = 5678

def get_local_ip():
    local_ip = '127.0.0.1'
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        local_ip = s.getsockname()[0]
        s.close()
    except Exception:
        pass
    return local_ip

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

app = Flask(__name__)
app.secret_key = "regmod_meonxt_secret_session_key_2026"

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

WORKSPACE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CACHE_NAME = "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D"
LEGACY_CACHE_NAME = "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
FILE_NAME = DEFAULT_CACHE_NAME
DEFAULT_GOC_PATH = os.path.join(WORKSPACE_DIR, "cache gốc", DEFAULT_CACHE_NAME)

if not os.path.exists(DEFAULT_GOC_PATH):
    legacy_path = os.path.join(WORKSPACE_DIR, "cache gốc", LEGACY_CACHE_NAME)
    if os.path.exists(legacy_path):
        DEFAULT_GOC_PATH = legacy_path

# In-memory session store
ACTIVE_BASE_BYTES = None
ACTIVE_BASE_SOURCE = "cache gốc"
BUILDS = {}
DV_BUILDS = {}
AVATAR_BUILDS = {}

# -------------------------------------------------------------
# HELPER: EXTRACT & VALIDATE API KEY + HWID
# -------------------------------------------------------------
def check_request_auth(req):
    api_key = req.headers.get('X-API-Key')
    hwid = req.headers.get('X-Device-HWID')
    
    if not api_key or not hwid:
        body = req.get_json(silent=True) or {}
        if not api_key:
            api_key = body.get('api_key') or req.args.get('api_key')
        if not hwid:
            hwid = body.get('hwid') or req.args.get('hwid')
            
    # Check HWID blacklist first
    if hwid and db_manager.is_hwid_blocked(hwid):
        return False, "Thiết bị này (HWID) đã bị quản trị viên chặn truy cập!"
        
    if not api_key:
        return False, "Yêu cầu API Key hợp lệ để thực hiện thao tác tạo Cache / Shader!"
        
    is_valid, msg = db_manager.validate_api_key(api_key, hwid)
    if not is_valid:
        return False, f"API Key không hợp lệ: {msg}"
        
    return True, "Authorized"

# -------------------------------------------------------------
# 1. USER AUTHENTICATION & HWID APIS
# -------------------------------------------------------------
@app.route('/api/register', methods=['POST'])
def api_register():
    try:
        data = request.get_json() or {}
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        hwid = data.get('hwid', '').strip()
        ip = request.remote_addr or ''
        
        success, result = db_manager.register_user(username, password, hwid, ip)
        if success:
            return jsonify({'success': True, 'data': result})
        else:
            return jsonify({'success': False, 'error': result}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def api_login():
    try:
        data = request.get_json() or {}
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        hwid = data.get('hwid', '').strip()
        ip = request.remote_addr or ''
        
        success, result = db_manager.login_user(username, password, hwid, ip)
        if success:
            return jsonify({'success': True, 'data': result})
        else:
            return jsonify({'success': False, 'error': result}), 401
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/verify_hwid', methods=['POST'])
def api_verify_hwid():
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

@app.route('/api/validate_key', methods=['POST', 'GET'])
def api_validate_key():
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

@app.route('/api/check_session', methods=['POST'])
def api_check_session():
    try:
        data = request.get_json(silent=True) or {}
        username = data.get('username', '').strip().lower()
        api_key = data.get('api_key', '').strip() or request.headers.get('X-API-Key', '').strip()
        hwid = data.get('hwid', '').strip() or request.headers.get('X-Device-HWID', '').strip()
        
        if not username and api_key:
            conn_k = db_manager.get_db()
            cursor_k = conn_k.cursor()
            cursor_k.execute('SELECT owner FROM api_keys WHERE key = ?', (api_key,))
            key_row = cursor_k.fetchone()
            conn_k.close()
            if key_row and key_row['owner']:
                username = key_row['owner'].strip().lower()
        
        # 1. HWID Blacklist check
        if hwid and db_manager.is_hwid_blocked(hwid):
            return jsonify({
                'valid': False,
                'reason': 'HWID_BLOCKED',
                'message': 'Thiết bị này đã bị chặn truy cập!'
            }), 403
            
        # 2. User status check
        if username:
            conn = db_manager.get_db()
            cursor = conn.cursor()
            cursor.execute('SELECT is_blocked, api_key, role FROM users WHERE username = ?', (username,))
            user = cursor.fetchone()
            conn.close()
            
            if not user:
                return jsonify({
                    'valid': False,
                    'reason': 'USER_DELETED',
                    'message': 'Tài khoản của bạn đã bị xóa khỏi hệ thống!'
                }), 401
                
            if user['is_blocked'] == 1:
                return jsonify({
                    'valid': False,
                    'reason': 'USER_BLOCKED',
                    'message': 'Tài khoản của bạn đã bị quản trị viên khóa!'
                }), 403
                
            raw_r = user['role']
            try:
                role_val = int(raw_r)
            except Exception:
                s = str(raw_r).strip().lower()
                role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
            return jsonify({
                'valid': True,
                'role': role_val,
                'free_cache_enabled': db_manager.is_free_cache_enabled(),
                'message': 'Session Valid'
            }), 200
                
        return jsonify({
            'valid': True,
            'role': 0,
            'free_cache_enabled': db_manager.is_free_cache_enabled(),
            'message': 'Session Valid'
        }), 200
    except Exception as e:
        return jsonify({'valid': True, 'role': 0, 'free_cache_enabled': db_manager.is_free_cache_enabled(), 'error': str(e)}), 200

# -------------------------------------------------------------
# 2. ADMIN MEONXT PORTAL (PASS: 222007)
# -------------------------------------------------------------
@app.route('/meonxt')
def admin_page():
    return "Not Found", 404

@app.route('/meonxt/login', methods=['POST'])
def admin_login():
    data = request.get_json() or {}
    password = data.get('password', '').strip()
    if password == '222007':
        session['meonxt_auth'] = True
        return jsonify({'success': True})
    return jsonify({'success': False, 'error': 'Mật khẩu quản trị viên không chính xác!'}), 401

@app.route('/meonxt/logout', methods=['POST'])
def admin_logout():
    session.pop('meonxt_auth', None)
    return jsonify({'success': True})

@app.route('/meonxt/api/data', methods=['GET'])
def admin_get_data():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        users = db_manager.get_all_users()
        blacklist = db_manager.get_all_blocked_hwids()
        logs = db_manager.get_login_logs(50)
        return jsonify({
            'success': True,
            'users': users,
            'blacklist': blacklist,
            'logs': logs,
            'active_keys_count': len([u for u in users if u['is_blocked'] == 0]),
            'free_cache_enabled': db_manager.is_free_cache_enabled()
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/meonxt/api/toggle_free_cache', methods=['POST'])
def admin_toggle_free_cache():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    try:
        data = request.get_json(silent=True) or {}
        if 'enabled' in data:
            new_state = bool(data['enabled'])
            db_manager.set_free_cache_enabled(new_state)
        else:
            curr = db_manager.is_free_cache_enabled()
            new_state = not curr
            db_manager.set_free_cache_enabled(new_state)
        return jsonify({'success': True, 'free_cache_enabled': new_state})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/meonxt/api/block_hwid', methods=['POST'])
def admin_block_hwid():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    data = request.get_json() or {}
    hwid = data.get('hwid', '').strip()
    reason = data.get('reason', 'Chặn bởi quản trị viên qua MEONXT')
    if not hwid:
        return jsonify({'success': False, 'error': 'Thiếu HWID'}), 400
    res = db_manager.block_hwid(hwid, reason)
    return jsonify({'success': res})

@app.route('/meonxt/api/unblock_hwid', methods=['POST'])
def admin_unblock_hwid():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    data = request.get_json() or {}
    hwid = data.get('hwid', '').strip()
    if not hwid:
        return jsonify({'success': False, 'error': 'Thiếu HWID'}), 400
    res = db_manager.unblock_hwid(hwid)
    return jsonify({'success': res})

@app.route('/meonxt/api/toggle_user', methods=['POST'])
def admin_toggle_user():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    success, res = db_manager.toggle_block_user(username)
    return jsonify({'success': success, 'new_status': res})

@app.route('/meonxt/api/set_role', methods=['POST'])
def admin_set_role():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    role = data.get('role', 0)
    success, res = db_manager.set_user_role(username, role)
    return jsonify({'success': success, 'role': res})

@app.route('/meonxt/api/add_user', methods=['POST'])
def admin_add_user():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    password = data.get('password', '').strip()
    role = data.get('role', 0)
    hwid = data.get('hwid', '').strip()
    success, res = db_manager.add_user_by_admin(username, password, role=role, hwid=hwid)
    if success:
        return jsonify({'success': True, 'data': res})
    else:
        return jsonify({'success': False, 'error': res}), 400

@app.route('/meonxt/api/delete_user', methods=['POST'])
def admin_delete_user():
    if not session.get('meonxt_auth') and request.headers.get('X-Admin-Key') != '222007':
        return jsonify({'success': False, 'error': 'Unauthorized'}), 401
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    success = db_manager.delete_user(username)
    return jsonify({'success': success})

# -------------------------------------------------------------
# 3. WEB APP ROUTES & HITBOX CACHE
# -------------------------------------------------------------
@app.route('/')
def index():
    return "Not Found", 404

@app.route('/api/base_info', methods=['GET'])
def get_base_info():
    global ACTIVE_BASE_BYTES, ACTIVE_BASE_SOURCE
    try:
        if ACTIVE_BASE_BYTES is None:
            if os.path.exists(DEFAULT_GOC_PATH):
                with open(DEFAULT_GOC_PATH, 'rb') as f:
                    ACTIVE_BASE_BYTES = bytearray(f.read())
                ACTIVE_BASE_SOURCE = "cache gốc"
            else:
                return jsonify({'success': False, 'error': f"Không tìm thấy file tại {DEFAULT_GOC_PATH}"}), 404
        
        parsed = builder_core.read_values_from_bytes(ACTIVE_BASE_BYTES)
        sha256 = hashlib.sha256(ACTIVE_BASE_BYTES).hexdigest()
        
        return jsonify({
            'success': True,
            'source_name': ACTIVE_BASE_SOURCE,
            'file_size': len(ACTIVE_BASE_BYTES),
            'sha256': sha256,
            'current_values': parsed,
            'local_ip': get_local_ip(),
            'server_ip': '103.238.234.204',
            'port': PORT
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/reset_base', methods=['POST'])
def reset_base():
    global ACTIVE_BASE_BYTES, ACTIVE_BASE_SOURCE
    try:
        if not os.path.exists(DEFAULT_GOC_PATH):
            return jsonify({'success': False, 'error': 'Không tìm thấy file gốc'}), 404
        with open(DEFAULT_GOC_PATH, 'rb') as f:
            ACTIVE_BASE_BYTES = bytearray(f.read())
        ACTIVE_BASE_SOURCE = "cache gốc"
        return get_base_info()
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/upload_base', methods=['POST'])
def upload_base():
    global ACTIVE_BASE_BYTES, ACTIVE_BASE_SOURCE
    try:
        file = None
        if 'file' in request.files:
            file = request.files['file']
        elif 'cache_file' in request.files:
            file = request.files['cache_file']
            
        if not file or file.filename == '':
            return jsonify({'success': False, 'error': 'Vui lòng chọn tệp cache_res để tải lên'}), 400
            
        data = file.read()
        if len(data) == 0:
            return jsonify({'success': False, 'error': 'Tệp tải lên rỗng'}), 400
            
        ACTIVE_BASE_BYTES = bytearray(data)
        ACTIVE_BASE_SOURCE = file.filename
        
        return get_base_info()
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/build', methods=['POST'])
def build_cache():
    global ACTIVE_BASE_BYTES
    try:
        # STRICT SECURITY: Require valid API Key & Non-blocked HWID
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Từ chối quyền: {auth_msg}"}), 403

        # Free Cache Policy Check:
        # If Free Cache is turned OFF, free users (role < 1) cannot build cache! Only VIP users (role >= 1) can build.
        if not db_manager.is_free_cache_enabled():
            api_key = request.headers.get('X-API-Key')
            if not api_key:
                body = request.get_json(silent=True) or {}
                api_key = body.get('api_key') or request.args.get('api_key')
            user_role = db_manager.get_user_role_by_api_key(api_key)
            if user_role < 1:
                return jsonify({
                    'success': False,
                    'error': 'Tính năng tạo Cache miễn phí hiện đang tạm đóng bởi Quản trị viên! Vui lòng nâng cấp VIP hoặc liên hệ Admin để mở khóa.'
                }), 403

        data = request.get_json() or {}
        preset_id = data.get('preset_id')
        params = data.get('params', {})
        custom_base_b64 = data.get('custom_base_base64')
        
        # If preset_id is provided, apply formula from backend MOD_FORMULAS
        if preset_id and preset_id in builder_core.MOD_FORMULAS:
            formula = builder_core.MOD_FORMULAS[preset_id]
            merged_params = {}
            target_bones = [
                'male_head', 'female_head', 'male_spine', 'female_spine', 'chest_spine1',
                'sniper_collider', 'bone_hips'
            ]
            for k in target_bones:
                if k in params and isinstance(params[k], dict):
                    merged_params[k] = dict(params[k])
            # Formula is authority over default/unadjusted client sliders
            for k, v in formula.items():
                if k in target_bones and isinstance(v, dict):
                    if k in merged_params:
                        merged_params[k].update(v)
                    else:
                        merged_params[k] = dict(v)
            params = merged_params
        
        base_bytes = None
        if custom_base_b64:
            try:
                import base64
                base_bytes = bytearray(base64.b64decode(custom_base_b64))
            except Exception:
                base_bytes = None
                
        if base_bytes is None:
            if ACTIVE_BASE_BYTES is None:
                ACTIVE_BASE_BYTES = builder_core.load_base_file()
            base_bytes = ACTIVE_BASE_BYTES
            
        mod_bytes, sha256, applied_changes = builder_core.build_mod_file(base_bytes, params)
        
        out_filename = data.get('filename') or data.get('custom_filename') or FILE_NAME
        build_id = f"build_{int(time.time() * 1000)}"
        BUILDS[build_id] = {
            'bytes': mod_bytes,
            'sha256': sha256,
            'filename': out_filename,
            'time': time.strftime("%Y-%m-%d %H:%M:%S"),
            'changes': applied_changes
        }
        
        if len(BUILDS) > 20:
            del BUILDS[list(BUILDS.keys())[0]]
            
        import base64
        data_b64 = base64.b64encode(mod_bytes).decode('ascii')
            
        return jsonify({
            'success': True,
            'build_id': build_id,
            'download_url': f'/api/download/{build_id}',
            'data_b64': data_b64,
            'sha256': sha256,
            'size': len(mod_bytes),
            'changes_count': len(applied_changes),
            'changes': applied_changes,
            'filename': out_filename
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400

@app.route('/api/download/<build_id>', methods=['GET'])
def download_build(build_id):
    if build_id not in BUILDS:
        return "Bản build không tồn tại hoặc đã hết hạn!", 404
    
    b_data = BUILDS[build_id]['bytes']
    out_name = BUILDS[build_id].get('filename', FILE_NAME)
    return send_file(
        io.BytesIO(b_data),
        mimetype='application/octet-stream',
        as_attachment=True,
        download_name=out_name
    )

@app.route('/api/export_folder', methods=['POST'])
def export_folder():
    try:
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Từ chối quyền: {auth_msg}"}), 403

        data = request.get_json() or {}
        build_id = data.get('build_id')
        folder_name = data.get('folder_name', 'cache mod_output').strip() or 'cache mod_output'
            
        if build_id not in BUILDS:
            return jsonify({'success': False, 'error': 'Bản build không hợp lệ hoặc đã hết hạn'}), 404
            
        target_dir = os.path.join(WORKSPACE_DIR, folder_name)
        os.makedirs(target_dir, exist_ok=True)
        
        target_file = os.path.join(target_dir, FILE_NAME)
        with open(target_file, 'wb') as f:
            f.write(BUILDS[build_id]['bytes'])
            
        return jsonify({
            'success': True,
            'folder': folder_name,
            'file_path': target_file,
            'size': len(BUILDS[build_id]['bytes']),
            'sha256': BUILDS[build_id]['sha256']
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/overwrite_goc', methods=['POST'])
def overwrite_goc():
    try:
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Từ chối quyền: {auth_msg}"}), 403

        data = request.get_json() or {}
        build_id = data.get('build_id')
        
        if build_id not in BUILDS:
            return jsonify({'success': False, 'error': 'Bản build không hợp lệ hoặc đã hết hạn'}), 404
            
        if os.path.exists(DEFAULT_GOC_PATH):
            bak_path = DEFAULT_GOC_PATH + ".bak"
            if not os.path.exists(bak_path):
                shutil.copy2(DEFAULT_GOC_PATH, bak_path)
                
        with open(DEFAULT_GOC_PATH, 'wb') as f:
            f.write(BUILDS[build_id]['bytes'])
            
        return jsonify({
            'success': True,
            'file_path': DEFAULT_GOC_PATH,
            'backup_created': os.path.exists(DEFAULT_GOC_PATH + ".bak"),
            'size': len(BUILDS[build_id]['bytes']),
            'sha256': BUILDS[build_id]['sha256']
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# -------------------------------------------------------------
# 4. GUN SHADER (DÂY VÀNG)
# -------------------------------------------------------------
@app.route('/api/dv_status', methods=['GET'])
def api_dv_status():
    try:
        status = dv_core.get_dv_status()
        return jsonify({'success': True, 'data': status})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/dv_build', methods=['POST'])
def api_dv_build():
    try:
        # STRICT SECURITY: Require valid API Key & Non-blocked HWID
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Từ chối quyền: {auth_msg}"}), 403

        req = request.get_json() or {}
        ver = req.get('version', 'fft')
        mode = req.get('mode', 'mod')
        options = req.get('options', {})
        
        # Enforce VIP check for Shader mod mode
        if mode == 'mod':
            api_key = request.headers.get('X-API-Key')
            if not api_key:
                api_key = req.get('api_key') or request.args.get('api_key')
            
            conn = db_manager.get_db()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT u.role, u.is_blocked 
                FROM users u 
                JOIN api_keys a ON a.owner = u.username 
                WHERE a.key = ?
            ''', (api_key,))
            user_row = cursor.fetchone()
            conn.close()
            
            if not user_row or user_row['is_blocked'] == 1:
                return jsonify({'success': False, 'error': 'Tài khoản không hợp lệ hoặc đã bị khóa!'}), 403
            
            raw_r = user_row['role']
            try:
                role_val = int(raw_r)
            except Exception:
                s = str(raw_r).strip().lower()
                role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
            is_vip = role_val >= 1
            if not is_vip:
                return jsonify({'success': False, 'error': 'Tính năng Shader chỉ dành riêng cho tài khoản VIP đã được Admin cấp quyền!'}), 403

        data_bytes, filename, sha256, applied_changes = dv_core.get_dv_bytes(ver, mode, options)
        build_id = f"dv_{ver}_{mode}_{int(time.time() * 1000)}"
        
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
            
        import base64
        data_b64 = base64.b64encode(data_bytes).decode('ascii')
        
        return jsonify({
            'success': True,
            'build_id': build_id,
            'filename': filename,
            'size': len(data_bytes),
            'sha256': sha256,
            'version': ver,
            'mode': mode,
            'download_url': f"/api/dv_download/{build_id}",
            'data_b64': data_b64,
            'changes': applied_changes
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/dv_download/<build_id>', methods=['GET'])
def api_dv_download(build_id):
    if build_id not in DV_BUILDS:
        return "Bản build Dây Vàng không tồn tại hoặc đã hết hạn!", 404
        
    item = DV_BUILDS[build_id]
    return send_file(
        io.BytesIO(item['bytes']),
        mimetype='application/octet-stream',
        as_attachment=True,
        download_name=item['filename']
    )

@app.route('/api/dv_export', methods=['POST'])
def api_dv_export():
    try:
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Từ chối quyền: {auth_msg}"}), 403

        req = request.get_json() or {}
        build_id = req.get('build_id')
        folder_name = req.get('folder_name', 'dv_mod_output').strip() or 'dv_mod_output'
        
        if build_id not in DV_BUILDS:
            return jsonify({'success': False, 'error': 'Bản build không tồn tại'}), 404
            
        item = DV_BUILDS[build_id]
        target_dir = os.path.join(WORKSPACE_DIR, folder_name)
        os.makedirs(target_dir, exist_ok=True)
        
        target_file = os.path.join(target_dir, item['filename'])
        with open(target_file, 'wb') as f:
            f.write(item['bytes'])
            
        return jsonify({
            'success': True,
            'folder': folder_name,
            'file_path': target_file,
            'filename': item['filename'],
            'size': len(item['bytes']),
            'sha256': item['sha256']
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# -------------------------------------------------------------
# 5. REST V1 COMPATIBILITY LAYER
# -------------------------------------------------------------
@app.route('/api/v1/health', methods=['GET'])
def v1_health():
    return jsonify({
        'status': 'online',
        'server': '103.238.234.204:5678',
        'app_name': 'Reg Mod REST API',
        'version': 'v2.0.0',
        'auth_required': True,
        'free_cache_enabled': db_manager.is_free_cache_enabled()
    })

@app.route('/api/v1/gun/build', methods=['POST'])
def v1_gun_build():
    is_auth, auth_msg = check_request_auth(request)
    if not is_auth:
        return jsonify({'success': False, 'error': f"Unauthorized: {auth_msg}"}), 403
    return api_dv_build()

@app.route('/api/v1/gun/download/<build_id>', methods=['GET'])
def v1_gun_download(build_id):
    return api_dv_download(build_id)

@app.route('/api/v1/hitbox/build', methods=['POST'])
def v1_hitbox_build():
    is_auth, auth_msg = check_request_auth(request)
    if not is_auth:
        return jsonify({'success': False, 'error': f"Unauthorized: {auth_msg}"}), 403
    return build_cache()

@app.route('/api/v1/hitbox/download/<build_id>', methods=['GET'])
def v1_hitbox_download(build_id):
    return download_build(build_id)

@app.route('/api/v1/security/report_violation', methods=['POST'])
def v1_report_security_violation():
    try:
        data = request.get_json(silent=True) or {}
        hwid = data.get('hwid', '').strip()
        reason = data.get('reason', 'Phát hiện can thiệp nhị phân dylib').strip()
        client_ip = request.remote_addr or ''
        if hwid:
            db_manager.block_hwid(hwid, f"Auto-Ban: {reason} [IP: {client_ip}]")
            print(f"[SECURITY ALERT] Auto-blocked HWID: {hwid} | Reason: {reason} | IP: {client_ip}")
            return jsonify({'success': True, 'blocked': True, 'message': 'HWID Blacklisted'})
        return jsonify({'success': False, 'error': 'Thiếu HWID'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# -------------------------------------------------------------
# 6. AVATAR MOD (MAKE AVATAR / ASSETINDEXER)
# -------------------------------------------------------------
@app.route('/api/avatar/presets', methods=['GET'])
@app.route('/api/v1/avatar/presets', methods=['GET'])
def api_avatar_presets():
    return jsonify({
        'success': True,
        'presets': avatar_core.PRESETS
    })

@app.route('/api/avatar/build', methods=['POST'])
@app.route('/api/v1/avatar/build', methods=['POST'])
def api_avatar_build():
    try:
        is_auth, auth_msg = check_request_auth(request)
        if not is_auth:
            return jsonify({'success': False, 'error': f"Từ chối quyền: {auth_msg}"}), 403

        # Verify VIP 2 requirement for Make Avatar
        api_key = request.headers.get('X-API-Key')
        if not api_key:
            data_req = request.get_json(silent=True) or {}
            api_key = data_req.get('api_key') or request.args.get('api_key')

        conn = db_manager.get_db()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT u.role, u.is_blocked 
            FROM users u 
            JOIN api_keys a ON a.owner = u.username 
            WHERE a.key = ?
        ''', (api_key,))
        user_row = cursor.fetchone()
        conn.close()

        if not user_row or user_row['is_blocked'] == 1:
            return jsonify({'success': False, 'error': 'Tài khoản không hợp lệ hoặc đã bị khóa!'}), 403

        raw_r = user_row['role']
        try:
            role_val = int(raw_r)
        except Exception:
            s = str(raw_r).strip().lower()
            role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)

        if role_val < 2:
            return jsonify({
                'success': False, 
                'error': 'Tính năng Make Avatar (AssetIndexer) độc quyền yêu cầu tài khoản VIP 2! Vui lòng liên hệ Admin MeoNxt để nâng cấp gói VIP 2.'
            }), 403

        data = request.get_json(silent=True) or {}
        custom_file_b64 = data.get('custom_file_base64')
        raw_bytes = None
        if custom_file_b64:
            try:
                import base64
                raw_bytes = base64.b64decode(custom_file_b64)
            except Exception:
                raw_bytes = None

        mod_bytes, filename, sha256, applied_changes = avatar_core.build_avatar_mod(raw_bytes, data)
        build_id = f"avatar_{int(time.time() * 1000)}"
        AVATAR_BUILDS[build_id] = {
            'bytes': mod_bytes,
            'filename': filename,
            'sha256': sha256,
            'time': time.strftime("%Y-%m-%d %H:%M:%S"),
            'changes': applied_changes
        }
        if len(AVATAR_BUILDS) > 20:
            del AVATAR_BUILDS[list(AVATAR_BUILDS.keys())[0]]

        import base64
        data_b64 = base64.b64encode(mod_bytes).decode('ascii')

        return jsonify({
            'success': True,
            'build_id': build_id,
            'download_url': f'/api/avatar/download/{build_id}',
            'data_b64': data_b64,
            'sha256': sha256,
            'size': len(mod_bytes),
            'filename': filename,
            'changes': applied_changes,
            'changes_count': len(applied_changes)
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400

@app.route('/api/avatar/download/<build_id>', methods=['GET'])
@app.route('/api/v1/avatar/download/<build_id>', methods=['GET'])
def api_avatar_download(build_id):
    if build_id not in AVATAR_BUILDS:
        return "Bản build Avatar không tồn tại hoặc đã hết hạn!", 404

    item = AVATAR_BUILDS[build_id]
    return send_file(
        io.BytesIO(item['bytes']),
        mimetype='application/octet-stream',
        as_attachment=True,
        download_name=item['filename']
    )


if __name__ == '__main__':
    local_ip = get_local_ip()

    print("=======================================================")
    print("  REG MOD - FREE FIRE MOD STUDIO & CONTROLLER")
    print(f"  • VPS Public Host  : http://103.238.234.204:{PORT}")
    print(f"  • Admin Controller : http://103.238.234.204:{PORT}/meonxt (Pass: 222007)")
    print(f"  • Local Machine    : http://127.0.0.1:{PORT}")
    print("=======================================================")
    app.run(host='0.0.0.0', port=PORT, debug=False)
