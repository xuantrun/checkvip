import os
import sqlite3
import hashlib
import time
import secrets
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app_studio.db")

def get_db():
    conn = sqlite3.connect(DB_PATH, timeout=30.0, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # 1. Users Table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        hwid TEXT,
        api_key TEXT UNIQUE,
        is_blocked INTEGER DEFAULT 0,
        role TEXT DEFAULT 'user',
        created_at TEXT,
        last_login TEXT,
        last_ip TEXT
    )
    ''')
    
    # 2. HWID Blacklist
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS hwid_blacklist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hwid TEXT UNIQUE NOT NULL,
        reason TEXT,
        blocked_at TEXT
    )
    ''')
    
    # 3. API Keys Table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS api_keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        owner TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        uses_count INTEGER DEFAULT 0
    )
    ''')
    
    # 4. Login Logs Table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS login_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        hwid TEXT,
        ip TEXT,
        status TEXT,
        timestamp TEXT
    )
    ''')
    
    # 5. System Settings Table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS system_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT
    )
    ''')
    
    conn.commit()
    
    # Seed default Master API Key if not exists
    master_key = "REGMOD-PRO-2026-VIP"
    cursor.execute('SELECT id FROM api_keys WHERE key = ?', (master_key,))
    if not cursor.fetchone():
        cursor.execute(
            'INSERT INTO api_keys (key, owner, is_active, created_at, uses_count) VALUES (?, ?, 1, ?, 0)',
            (master_key, 'System Master', datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        )
        conn.commit()

    # Seed default free_cache_enabled = 1 if not exists
    cursor.execute('SELECT value FROM system_settings WHERE key = ?', ('free_cache_enabled',))
    if not cursor.fetchone():
        cursor.execute(
            'INSERT INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)',
            ('free_cache_enabled', '1', datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        )
        conn.commit()
        
    conn.close()

def get_setting(key: str, default: str = "") -> str:
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('SELECT value FROM system_settings WHERE key = ?', (key,))
        row = cursor.fetchone()
        return row['value'] if row else default
    except Exception:
        return default
    finally:
        conn.close()

def set_setting(key: str, value: str) -> bool:
    conn = get_db()
    cursor = conn.cursor()
    try:
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute(
            'INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)',
            (key, str(value), now)
        )
        conn.commit()
        return True
    except Exception as e:
        print(f"Error setting {key}:", e)
        return False
    finally:
        conn.close()

def is_free_cache_enabled() -> bool:
    val = get_setting('free_cache_enabled', '1')
    return val in ('1', 'true', 'True', 'yes', 'on')

def set_free_cache_enabled(enabled: bool) -> bool:
    return set_setting('free_cache_enabled', '1' if enabled else '0')

def get_user_role_by_api_key(api_key: str) -> int:
    if not api_key:
        return 0
    key_clean = api_key.strip()
    if key_clean == "REGMOD-PRO-2026-VIP":
        return 2
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            SELECT u.role, u.is_blocked 
            FROM users u 
            JOIN api_keys a ON LOWER(TRIM(a.owner)) = LOWER(TRIM(u.username)) 
            WHERE a.key = ?
        ''', (key_clean,))
        row = cursor.fetchone()
        if not row or row['is_blocked'] == 1:
            return 0
        raw_r = row['role']
        try:
            return int(raw_r)
        except Exception:
            s = str(raw_r).strip().lower()
            return 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
    except Exception:
        return 0
    finally:
        conn.close()

def hash_password(password: str) -> str:
    salt = "regmod_vps_security_salt_2026"
    return hashlib.sha256((password + salt).encode('utf-8')).hexdigest()

def generate_api_key(username: str) -> str:
    token = secrets.token_hex(12).upper()
    return f"REGMOD-{username.upper()[:6]}-{token}"

# --- HWID Operations ---
def is_hwid_blocked(hwid: str) -> bool:
    if not hwid:
        return False
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM hwid_blacklist WHERE LOWER(hwid) = LOWER(?)', (hwid.strip(),))
    res = cursor.fetchone()
    conn.close()
    return res is not None

def block_hwid(hwid: str, reason: str = "Quản trị viên chặn qua Admin Panel"):
    if not hwid:
        return False
    conn = get_db()
    cursor = conn.cursor()
    try:
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute(
            'INSERT OR REPLACE INTO hwid_blacklist (hwid, reason, blocked_at) VALUES (?, ?, ?)',
            (hwid.strip(), reason, now)
        )
        # Also mark any users with this HWID as blocked
        cursor.execute('UPDATE users SET is_blocked = 1 WHERE LOWER(hwid) = LOWER(?)', (hwid.strip(),))
        conn.commit()
        return True
    except Exception as e:
        print("Error blocking HWID:", e)
        return False
    finally:
        conn.close()

def unblock_hwid(hwid: str):
    if not hwid:
        return False
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('DELETE FROM hwid_blacklist WHERE LOWER(hwid) = LOWER(?)', (hwid.strip(),))
        cursor.execute('UPDATE users SET is_blocked = 0 WHERE LOWER(hwid) = LOWER(?)', (hwid.strip(),))
        conn.commit()
        return True
    except Exception as e:
        print("Error unblocking HWID:", e)
        return False
    finally:
        conn.close()

def get_all_blocked_hwids():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hwid_blacklist ORDER BY id DESC')
    rows = [dict(r) for r in cursor.fetchall()]
    conn.close()
    return rows

# --- User Operations ---
def register_user(username, password, hwid="", ip="", role=0):
    username = username.strip().lower()
    if len(username) < 3:
        return False, "Tên tài khoản tối thiểu 3 ký tự"
    if len(password) < 4:
        return False, "Mật khẩu tối thiểu 4 ký tự"
        
    if hwid and is_hwid_blocked(hwid):
        log_login(username, hwid, ip, "FAILED: HWID Blocked")
        return False, "Thiết bị này (HWID) đã bị quản trị viên chặn truy cập!"
        
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('SELECT id FROM users WHERE username = ?', (username,))
        if cursor.fetchone():
            return False, "Tên tài khoản đã tồn tại"
            
        pwd_h = hash_password(password)
        api_key = generate_api_key(username)
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        try:
            role_val = int(role)
        except Exception:
            s = str(role).strip().lower()
            role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
        
        cursor.execute('''
        INSERT INTO users (username, password_hash, hwid, api_key, is_blocked, role, created_at, last_login, last_ip)
        VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?)
        ''', (username, pwd_h, hwid, api_key, role_val, now, now, ip))
        
        # Also register API key
        cursor.execute(
            'INSERT INTO api_keys (key, owner, is_active, created_at, uses_count) VALUES (?, ?, 1, ?, 0)',
            (api_key, username, now)
        )
        
        conn.commit()
        log_login(username, hwid, ip, "REGISTER_SUCCESS")
        return True, {
            'username': username,
            'api_key': api_key,
            'hwid': hwid,
            'role': role_val,
            'created_at': now
        }
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def login_user(username, password, hwid="", ip=""):
    username = username.strip().lower()
    
    if hwid and is_hwid_blocked(hwid):
        log_login(username, hwid, ip, "FAILED: HWID Blocked")
        return False, "Thiết bị này (HWID) đã bị chặn truy cập hệ thống!"
        
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('SELECT * FROM users WHERE username = ?', (username,))
        user = cursor.fetchone()
        if not user:
            log_login(username, hwid, ip, "FAILED: User Not Found")
            return False, "Tài khoản hoặc mật khẩu không chính xác"
            
        user = dict(user)
        if user['is_blocked'] == 1:
            log_login(username, hwid, ip, "FAILED: User Blocked")
            return False, "Tài khoản của bạn đã bị quản trị viên tạm khóa!"
            
        if user['password_hash'] != hash_password(password):
            log_login(username, hwid, ip, "FAILED: Wrong Password")
            return False, "Tài khoản hoặc mật khẩu không chính xác"
            
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        raw_r = user.get('role')
        try:
            role_val = int(raw_r)
        except Exception:
            s = str(raw_r).strip().lower()
            role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
        
        # Update last login, IP and HWID if provided
        cursor.execute(
            'UPDATE users SET last_login = ?, last_ip = ?, hwid = COALESCE(NULLIF(?, ""), hwid) WHERE username = ?',
            (now, ip, hwid, username)
        )
        conn.commit()
        
        log_login(username, hwid, ip, "LOGIN_SUCCESS")
        return True, {
            'username': user['username'],
            'api_key': user['api_key'],
            'hwid': hwid or user['hwid'],
            'role': role_val,
            'created_at': user['created_at'],
            'last_login': now
        }
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def set_user_role(username: str, role: int):
    conn = get_db()
    cursor = conn.cursor()
    try:
        try:
            role_val = int(role)
        except Exception:
            s = str(role).strip().lower()
            role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
        cursor.execute('UPDATE users SET role = ? WHERE LOWER(TRIM(username)) = LOWER(TRIM(?))', (role_val, username))
        if cursor.rowcount == 0:
            return False, f"Không tìm thấy tài khoản '{username}' để cấp role"
        conn.commit()
        return True, role_val
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def add_user_by_admin(username, password, role=0, hwid=""):
    return register_user(username, password, hwid=hwid, ip="ADMIN_PANEL", role=role)

def toggle_block_user(username: str):
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('SELECT is_blocked FROM users WHERE LOWER(TRIM(username)) = LOWER(TRIM(?))', (username,))
        row = cursor.fetchone()
        if not row:
            return False, "Không tìm thấy người dùng"
        new_status = 0 if row['is_blocked'] == 1 else 1
        cursor.execute('UPDATE users SET is_blocked = ? WHERE LOWER(TRIM(username)) = LOWER(TRIM(?))', (new_status, username))
        conn.commit()
        return True, new_status
    finally:
        conn.close()

def delete_user(username: str):
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('DELETE FROM users WHERE LOWER(TRIM(username)) = LOWER(TRIM(?))', (username,))
        cursor.execute('DELETE FROM api_keys WHERE LOWER(TRIM(owner)) = LOWER(TRIM(?))', (username,))
        conn.commit()
        return True
    finally:
        conn.close()

def get_all_users():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT id, username, hwid, api_key, is_blocked, role, created_at, last_login, last_ip FROM users ORDER BY id DESC')
    rows = []
    for r in cursor.fetchall():
        d = dict(r)
        raw_r = d.get('role')
        try:
            role_val = int(raw_r)
        except Exception:
            s = str(raw_r).strip().lower()
            role_val = 2 if s in ('2', 'vip2') else (1 if s in ('1', 'vip', 'vip1') else 0)
        d['role'] = role_val
        rows.append(d)
    conn.close()
    return rows

# --- API Key Validation ---
def validate_api_key(key: str, hwid: str = "") -> (bool, str):
    if not key:
        return False, "Thiếu API Key (Vui lòng đăng nhập hoặc nhập key hợp lệ)"
    
    key = key.strip()
    
    if hwid and is_hwid_blocked(hwid):
        return False, "Thiết bị này đã bị chặn (HWID Blacklisted)!"
        
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute('SELECT * FROM api_keys WHERE key = ? AND is_active = 1', (key,))
        row = cursor.fetchone()
        if not row:
            return False, "API Key không hợp lệ hoặc đã bị vô hiệu hóa"
            
        # Check if owner user is blocked
        owner = row['owner']
        if owner and owner != 'System Master':
            cursor.execute('SELECT is_blocked, hwid FROM users WHERE username = ?', (owner,))
            u = cursor.fetchone()
            if u:
                if u['is_blocked'] == 1:
                    return False, "Tài khoản sở hữu API Key này đã bị khóa"
                if u['hwid'] and is_hwid_blocked(u['hwid']):
                    return False, "Thiết bị của tài khoản này đã bị khóa HWID"
                    
        # Increment usage count
        cursor.execute('UPDATE api_keys SET uses_count = uses_count + 1 WHERE key = ?', (key,))
        conn.commit()
        return True, "API Key hợp lệ"
    finally:
        conn.close()

# --- Logging ---
def log_login(username: str, hwid: str, ip: str, status: str):
    try:
        conn = get_db()
        cursor = conn.cursor()
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute(
            'INSERT INTO login_logs (username, hwid, ip, status, timestamp) VALUES (?, ?, ?, ?, ?)',
            (username, hwid, ip, status, now)
        )
        conn.commit()
        conn.close()
    except Exception:
        pass

def get_login_logs(limit=50):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM login_logs ORDER BY id DESC LIMIT ?', (limit,))
    rows = [dict(r) for r in cursor.fetchall()]
    conn.close()
    return rows

# Initialize DB on load
init_db()
