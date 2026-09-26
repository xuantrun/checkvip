import os
import sys
import json
import base64
import urllib.request
import urllib.error

try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

# Các thư mục/file bỏ qua khi upload
IGNORED_NAMES = {
    '__pycache__', '.git', '.github_cache', 'cache mod_output', 'dv_mod_output',
    '.pytest_cache', 'venv', 'env', 'node_modules', '.DS_Store', 'build', 'DerivedData', 'scratch',
    'app_studio.db', 'check_actions.py', 'upload_workflow.py', 'push_update.py', 'update_pbx.py',
    'check_job.py', 'download_and_release.py', 'monitor_run.py', 'update_pbx_covers.py'
}
IGNORED_EXTENSIONS = {'.pyc', '.bak', '.log', '.xcuserstate', '.db', '.sqlite', '.ipa'}

def is_ignored(rel_path):
    parts = rel_path.replace('\\', '/').split('/')
    for p in parts:
        if p in IGNORED_NAMES:
            return True
    _, ext = os.path.splitext(rel_path)
    if ext in IGNORED_EXTENSIONS:
        return True
    return False

def make_gh_request(url, token, method='GET', data=None, max_retries=3):
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'FlorkModStudio-Uploader'
    }
    req_body = json.dumps(data).encode('utf-8') if data is not None else None
    for attempt in range(max_retries):
        req = urllib.request.Request(url, data=req_body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                content = resp.read()
                return resp.status, json.loads(content.decode('utf-8'))
        except urllib.error.HTTPError as e:
            err_body = e.read().decode('utf-8')
            try:
                err_json = json.loads(err_body)
            except Exception:
                err_json = {'message': err_body}
            return e.code, err_json
        except Exception as e:
            if attempt < max_retries - 1:
                time.sleep(2)
                continue
            raise e

def get_authenticated_user(token):
    code, res = make_gh_request('https://api.github.com/user', token)
    if code == 200:
        return res['login']
    raise RuntimeError(f"Lỗi xác thực token GitHub: {res.get('message', 'Không rõ')}")

def upload_project(token, username, repo_name, workspace_dir):
    print("\n[INFO] Dang quet cac file trong du an...")
    files_to_upload = []
    
    for root, dirs, files in os.walk(workspace_dir):
        dirs[:] = [d for d in dirs if d not in IGNORED_NAMES]
        for f in files:
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, workspace_dir)
            if not is_ignored(rel_path):
                files_to_upload.append((full_path, rel_path.replace('\\', '/')))
                
    print(f"[OK] Tim thay {len(files_to_upload)} files hop le de tai len.")
    
    # 1. Tạo blob cho từng file
    tree_items = []
    print("\n[INFO] Dang tai file len GitHub (Git Blobs API)...")
    
    for idx, (full_path, rel_path) in enumerate(files_to_upload, 1):
        file_size = os.path.getsize(full_path)
        print(f"  [{idx}/{len(files_to_upload)}] {rel_path} ({file_size:,} bytes)...", end="", flush=True)
        
        with open(full_path, 'rb') as f:
            content_bytes = f.read()
            
        b64_content = base64.b64encode(content_bytes).decode('utf-8')
        blob_payload = {
            'content': b64_content,
            'encoding': 'base64'
        }
        
        code, blob_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/blobs', token, method='POST', data=blob_payload)
        if code in (200, 201):
            tree_items.append({
                'path': rel_path,
                'mode': '100644',
                'type': 'blob',
                'sha': blob_res['sha']
            })
            print(" [OK]")
        else:
            print(f" [FAIL]: {blob_res.get('message', 'Loi khong xac dinh')}")
            
    # 2. Tạo Git Tree mới
    print("\n[INFO] Dang tao Git Tree...")
    tree_payload = {'tree': tree_items}
    code, tree_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/trees', token, method='POST', data=tree_payload)
    if code not in (200, 201):
        raise RuntimeError(f"Loi tao Git Tree: {tree_res.get('message')}")
    tree_sha = tree_res['sha']
    
    # 3. Lấy commit cha hiện tại (nếu có)
    parent_commit_sha = None
    code, ref_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/refs/heads/main', token)
    if code == 200:
        parent_commit_sha = ref_res['object']['sha']
    else:
        code, ref_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/refs/heads/master', token)
        if code == 200:
            parent_commit_sha = ref_res['object']['sha']
            
    # 4. Tạo Commit
    commit_msg = '🛡️ Reg Mod v2.0.11: Fix Black Screen GUI & Anti-Freeze Security'
    print(f"[INFO] Dang tao Commit: '{commit_msg}'...")
    commit_payload = {
        'message': commit_msg,
        'tree': tree_sha,
        'parents': [parent_commit_sha] if parent_commit_sha else []
    }
    code, commit_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/commits', token, method='POST', data=commit_payload)
    if code not in (200, 201):
        raise RuntimeError(f"Loi tao Commit: {commit_res.get('message')}")
    new_commit_sha = commit_res['sha']
    
    # 5. Cập nhật nhánh main
    print("[INFO] Dang cap nhat branch 'main'...")
    ref_payload = {'sha': new_commit_sha, 'force': True}
    code, update_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/refs/heads/main', token, method='PATCH', data=ref_payload)
    if code != 200:
        create_ref_payload = {'ref': 'refs/heads/main', 'sha': new_commit_sha}
        code, update_res = make_gh_request(f'https://api.github.com/repos/{username}/{repo_name}/git/refs', token, method='POST', data=create_ref_payload)
        
    repo_url = f"https://github.com/{username}/{repo_name}"
    print("\n=======================================================")
    print("[SUCCESS] DA UPLOAD TOAN BO DU AN LEN GITHUB THANH CONG!")
    print(f"Link Repo: {repo_url}")
    print(f"Link Actions (Tu dong build IPA): {repo_url}/actions")
    print("=======================================================")

def main():
    token = sys.argv[1] if len(sys.argv) >= 2 else os.environ.get('GITHUB_TOKEN')
    repo_name = sys.argv[2] if len(sys.argv) >= 3 else os.environ.get('GITHUB_REPO', 'cacheshader')
    
    if not token:
        print("[ERROR] Vui long cung cap token!")
        return
        
    try:
        username = get_authenticated_user(token)
        print(f"[OK] Da xac thuc tai khoan GitHub: @{username}")
        workspace_dir = os.path.dirname(os.path.abspath(__file__))
        upload_project(token, username, repo_name, workspace_dir)
    except Exception as e:
        print(f"\n[ERROR] Loi: {e}")

if __name__ == '__main__':
    main()
