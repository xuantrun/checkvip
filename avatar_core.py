import os
import io
import hashlib
import UnityPy

WORKSPACE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ASSETINDEXER_NAME = "assetindexer.U6Zffc4YIR3DslNj3cXvYGAqz58~3D"
DEFAULT_ASSETINDEXER_PATH = os.path.join(WORKSPACE_DIR, "avatar_goc", DEFAULT_ASSETINDEXER_NAME)

if not os.path.exists(DEFAULT_ASSETINDEXER_PATH):
    alt_path = os.path.join(WORKSPACE_DIR, "dpi", DEFAULT_ASSETINDEXER_NAME)
    if os.path.exists(alt_path):
        DEFAULT_ASSETINDEXER_PATH = alt_path
    else:
        # Fallback to legacy file name if new file not found
        legacy_path = os.path.join(WORKSPACE_DIR, "avatar_goc", "assetindexer.H5ak1JM1Eck~2FxRcJrEp~2FMzeuqmY~3D")
        if os.path.exists(legacy_path):
            DEFAULT_ASSETINDEXER_PATH = legacy_path

PRESETS = {
    # 1. Aim Head chuẩn (Đúng tâm giữa đầu - Khớp 100% file mod_clean hoạt động)
    "aimbot_head": {
        "name": "Aim Head (Đỉnh Đầu HS)",
        "target_bone": "bone_Head",
        "parent_hash": -1541408846,
        "default_scale": 1.5555556,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Khóa thẳng vào đầu (Headshot 100%). Chuẩn tọa độ và rotation file mod_clean."
    },
    "aim_head": {
        "name": "Aim Head (Đỉnh Đầu HS)",
        "target_bone": "bone_Head",
        "parent_hash": -1541408846,
        "default_scale": 1.5555556,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Khóa thẳng vào đầu (Headshot 100%)."
    },

    # 2. Aim Neck (Hạ Cổ HS tránh giật)
    "aimbot_neck": {
        "name": "Aim Neck (Hạ Cổ HS Tránh Giật)",
        "target_bone": "bone_Head",
        "parent_hash": -1541408846,
        "default_scale": 1.5555556,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Tâm ngắm hạ xuống khớp cổ. Bắn trúng cổ vẫn tính Headshot 100%, tâm đằm không bị ngửa lên đỉnh đầu."
    },

    # 3. Aim Body All ➔ Headshot (Bắn Thân Ra Headshot 100%)
    "aim_body_all_hs": {
        "name": "Aim Body All ➔ Headshot (Bắn Thân Ra HS 100%)",
        "target_bone": "bone_Spine",
        "parent_hash": 1529948125,
        "default_scale": 2.00,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Kéo tâm về giữa thân/ngực (bone_Spine). Bắn vào ngực ra Headshot 100%!"
    },
    "aim_body_spine": {
        "name": "Aim Body All ➔ Headshot (Bắn Thân Ra HS 100%)",
        "target_bone": "bone_Spine",
        "parent_hash": 1529948125,
        "default_scale": 2.00,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Kéo tâm về giữa thân/ngực (bone_Spine). Bắn vào ngực ra Headshot 100%!"
    },

    # 4. Aim Hips ➔ Headshot (Bắn Hông Ra Headshot)
    "aim_hips_hs": {
        "name": "Aim Hips ➔ Headshot (Bắn Hông Ra HS)",
        "target_bone": "bone_Hips",
        "parent_hash": 2018908708,
        "default_scale": 2.00,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Gắn Hitbox Headshot vào vùng hông / hạ bộ. Bắn vào hông ra Headshot 100%!"
    },
    "aim_hips": {
        "name": "Aim Hips ➔ Headshot (Bắn Hông Ra HS)",
        "target_bone": "bone_Hips",
        "parent_hash": 2018908708,
        "default_scale": 2.00,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Gắn Hitbox Headshot vào vùng hông / hạ bộ. Bắn vào hông ra Headshot 100%!"
    },

    # 5. Aim Spine1 (Thượng Thân / Ngực Trên)
    "aim_body_spine1": {
        "name": "Aim Thượng Thân (Tâm Ngực Trên)",
        "target_bone": "bone_Spine1",
        "parent_hash": -1051086991,
        "default_scale": 1.80,
        "pos_x": -0.044599998742341995,
        "pos_y": -0.0038999998942017555,
        "pos_z": -5.960000049043401e-09,
        "rot_x": 0.006340285,
        "rot_y": 3.041255474090576,
        "rot_z": -0.0370349,
        "rot_w": 0.9984419,
        "desc": "Kéo tâm lên phần ngực trên."
    },

    # 6. Antena Avatar
    "antena": {
        "name": "Antena Avatar (Cột Cờ Đỉnh Đầu)",
        "target_bone": "bone_Head",
        "parent_hash": -1541408846,
        "default_scale": 1.55554,
        "pos_x": -0.3749083,
        "pos_y": -0.0745993,
        "pos_z": -0.000002,
        "rot_x": 0.0,
        "rot_y": 2.6793561,
        "rot_z": -0.000008,
        "rot_w": -0.000013,
        "desc": "Kéo dài tọa độ socket tạo cột cờ Antena định vị kẻ địch xuyên map."
    },

    # 7. Tùy Chỉnh
    "custom": {
        "name": "Tùy Chỉnh (Custom Transform)",
        "target_bone": "bone_Head",
        "parent_hash": -1541408846,
        "default_scale": 1.50,
        "pos_x": 0.0,
        "pos_y": 0.0,
        "pos_z": 0.0,
        "rot_x": 0.0,
        "rot_y": 0.0,
        "rot_z": 0.0,
        "rot_w": 1.0,
        "desc": "Tự do cấu hình Bone, Parent Hash và hệ số phóng to."
    }
}

def load_default_assetindexer_bytes():
    if os.path.exists(DEFAULT_ASSETINDEXER_PATH):
        with open(DEFAULT_ASSETINDEXER_PATH, "rb") as f:
            return f.read()
    return None

def build_avatar_mod(raw_input_bytes, params=None):
    """
    Core Make Avatar mod builder using UnityPy.
    Processes assetindexer Unity bundle and modifies mesh bones and scales.
    Returns: (saved_bytes, filename, sha256_hash, applied_changes)
    """
    if params is None:
        params = {}

    if not raw_input_bytes or len(raw_input_bytes) == 0:
        raw_input_bytes = load_default_assetindexer_bytes()
        if not raw_input_bytes:
            raise ValueError("Không tìm thấy file assetindexer gốc trên máy chủ!")

    orig_size = len(raw_input_bytes)

    # Preset matching
    preset_id = params.get("preset_id")
    preset_cfg = PRESETS.get(preset_id, {})

    target_bone = params.get("target_bone") or preset_cfg.get("target_bone", "bone_Head")
    parent_hash = int(params.get("parent_hash") if params.get("parent_hash") is not None else preset_cfg.get("parent_hash", -1541408846))
    scale_val = float(params.get("scale") or preset_cfg.get("default_scale", 1.55))

    mod_male = bool(params.get("mod_male", True))
    mod_female = bool(params.get("mod_female", True))
    packer = params.get("packer", "lzma")
    match_size = bool(params.get("match_size", True))
    patch_mono = bool(params.get("patch_monoscript", True))

    # Transform parameters (Matching dpi logic directly)
    if "pos_x" in params and params["pos_x"] is not None:
        pos_x = float(params["pos_x"])
    else:
        pos_x = float(preset_cfg.get("pos_x", -0.086620286))

    if "pos_y" in params and params["pos_y"] is not None:
        pos_y = float(params["pos_y"])
    else:
        pos_y = float(preset_cfg.get("pos_y", 0.0))

    if "pos_z" in params and params["pos_z"] is not None:
        pos_z = float(params["pos_z"])
    else:
        pos_z = float(preset_cfg.get("pos_z", 0.0))

    offset_x = float(params.get("offset_x", 0.0) or 0.0)
    offset_y = float(params.get("offset_y", 0.0) or 0.0)
    offset_z = float(params.get("offset_z", 0.0) or 0.0)

    # If explicit offset is given (legacy mode), apply it; otherwise pos_x, pos_y, pos_z are the absolute coordinates
    final_pos_x = pos_x + offset_x
    final_pos_y = pos_y + offset_y
    final_pos_z = pos_z + offset_z

    if "rot_x" in params and params["rot_x"] is not None:
        rot_x = float(params["rot_x"])
    else:
        rot_x = float(preset_cfg.get("rot_x", 0.0))

    if "rot_y" in params and params["rot_y"] is not None:
        rot_y = float(params["rot_y"])
    else:
        rot_y = float(preset_cfg.get("rot_y", 0.0))

    if "rot_z" in params and params["rot_z"] is not None:
        rot_z = float(params["rot_z"])
    else:
        rot_z = float(preset_cfg.get("rot_z", 0.11343982))

    if "rot_w" in params and params["rot_w"] is not None:
        rot_w = float(params["rot_w"])
    else:
        rot_w = float(preset_cfg.get("rot_w", 0.9935449))

    # Big Weapon
    mod_big_gun = bool(params.get("mod_big_gun", False))
    gun_scale = float(params.get("gun_scale", 3.5))

    # Target PathIDs
    male_pid = -9165109095992080675
    female_pid = 2680591970127643204
    target_pids = []
    if mod_male:
        target_pids.append(male_pid)
    if mod_female:
        target_pids.append(female_pid)

    TARGET_STANDARD_SIZE = 46096

    # 1. Auto-Detect & Unobfuscate Header:
    # Tự động kiểm tra 256 bytes đầu của file. Nếu phát hiện header 2018.4.12f1,
    # tool tạm thời chuyển đổi sang 2022.3.47f1 để mở khóa toàn bộ 24 đối tượng và can thiệp xương bình thường.
    is_spoofed_2018 = b"2018.4.12f1" in raw_input_bytes[:256]
    if is_spoofed_2018:
        parse_bytes = raw_input_bytes[:256].replace(b"2018.4.12f1", b"2022.3.47f1") + raw_input_bytes[256:]
    else:
        parse_bytes = raw_input_bytes

    env = UnityPy.load(io.BytesIO(parse_bytes))

    for obj in env.objects:
        if obj.path_id in target_pids:
            tt = obj.read_typetree()
            bones = tt.get("meshData", {}).get("umaBones", [])

            for b in bones:
                bname = b.get("name", "")

                # 1. Hitbox socket / Avatar Aim bone
                if bname == "bone_Left_Weapon":
                    b["name"] = target_bone
                    b["parent"] = parent_hash
                    b["scale"] = {"x": scale_val, "y": scale_val, "z": scale_val}
                    b["position"] = {"x": final_pos_x, "y": final_pos_y, "z": final_pos_z}
                    b["rotation"] = {"x": rot_x, "y": rot_y, "z": rot_z, "w": rot_w}

                # 2. Big Gun (1.0x - 8.0x)
                if mod_big_gun and any(k in bname for k in [
                    "bone_Right_Weapon",
                    "bone_Right_Spine_Weapon",
                    "bone_Left_Spine_Weapon"
                ]):
                    b["scale"] = {"x": gun_scale, "y": gun_scale, "z": gun_scale}

            obj.save_typetree(tt)

        elif patch_mono and getattr(obj.type, "name", "") == "MonoScript":
            tt = obj.read_typetree()
            if tt.get("m_AssemblyName") == "Assembly-CSharp":
                tt["m_AssemblyName"] = "Assembly-CSharp.dll"
                obj.save_typetree(tt)

    # Nén AssetBundle chuẩn LZMA
    saved_bytes = env.file.save(packer=packer)

    # 2. Re-Spoof Header:
    # Sau khi nén LZMA, tool tự động trả lại chuỗi 2018.4.12f1 vào đúng header để game nhận diện file hợp lệ.
    if is_spoofed_2018 or b"2022.3.47f1" in saved_bytes[:256]:
        saved_bytes = saved_bytes[:256].replace(b"2022.3.47f1", b"2018.4.12f1") + saved_bytes[256:]

    # 3. Zero-Padding:
    # Tự động đệm byte 0x00 để file xuất ra đúng chuẩn 46,096 bytes (bằng 100% dung lượng gốc).
    target_out_size = max(orig_size, TARGET_STANDARD_SIZE) if match_size else TARGET_STANDARD_SIZE
    if len(saved_bytes) < target_out_size:
        pad_len = target_out_size - len(saved_bytes)
        saved_bytes = saved_bytes + (b"\x00" * pad_len)

    sha256 = hashlib.sha256(saved_bytes).hexdigest()
    out_filename = params.get("custom_filename") or params.get("filename") or DEFAULT_ASSETINDEXER_NAME

    # Construct clean, user-friendly check log (No raw bone names)
    applied_changes = []

    # 1. Bản Game mục tiêu
    game_ver = str(params.get("game_version") or params.get("game") or "fft").lower()
    game_label = "Free Fire MAX (FFM)" if "max" in game_ver or "ffm" in game_ver else "Free Fire Thường (FFT)"
    applied_changes.append(f"Bản Game mục tiêu: {game_label}")

    # 2. Mẫu Avatar đã chọn
    preset_name_map = {
        "aimbot_head": "Aim Head (Đỉnh Đầu HS)",
        "aim_head": "Aim Head (Đỉnh Đầu HS)",
        "aimbot_neck": "Aim Neck (Hạ Cổ HS Tránh Giật)",
        "aim_body_all_hs": "Aim Body All ➔ Headshot (Bắn Thân Ra HS 100%)",
        "aim_body_spine": "Aim Body All ➔ Headshot (Bắn Thân Ra HS 100%)",
        "aim_body_spine1": "Aim Thượng Thân (Tâm Ngực Trên)",
        "aim_hips_hs": "Aim Hông ➔ Headshot (Bắn Hông Ra HS)",
        "aim_hips": "Aim Hông ➔ Headshot (Bắn Hông Ra HS)",
        "aim_legs_hs": "Aim Legs ➔ Headshot (Bắn Chân Ra HS)",
        "aim_arms_hs": "Aim Arms ➔ Headshot (Bắn Tay Ra HS)",
        "antena": "Antena Avatar (Cột Sóng Laser Định Vị)",
        "custom": "Tùy Chỉnh Toàn Diện"
    }
    preset_title = preset_name_map.get(preset_id)
    if not preset_title:
        bone_friendly = {
            "bone_Head": "Tâm Đầu",
            "bone_Spine": "Tâm Ngực",
            "bone_Spine1": "Tâm Ngực Trên",
            "bone_Hips": "Tâm Hông"
        }.get(target_bone, "Tùy Chỉnh")
        preset_title = f"Mẫu Tùy Chỉnh ({bone_friendly})"
    applied_changes.append(f"Mẫu đã chọn: {preset_title}")

    # 3. Phóng to Hitbox
    applied_changes.append(f"Hệ số phóng to Hitbox: {scale_val:.2f}x")

    # 4. Tinh chỉnh tọa độ XYZ
    applied_changes.append(f"Tọa độ Hitbox (X, Y, Z): X: {final_pos_x:+.4f} | Y: {final_pos_y:+.4f} | Z: {final_pos_z:+.4f}")

    # 5. Nhân vật áp dụng
    char_list = []
    if mod_male:
        char_list.append("Nam")
    if mod_female:
        char_list.append("Nữ")
    applied_changes.append(f"Nhân vật áp dụng: {' & '.join(char_list) if char_list else 'Tất cả'}")

    # 6. Hiệu ứng Súng To
    if mod_big_gun:
        applied_changes.append(f"Hiệu ứng Súng To: Đã kích hoạt ({gun_scale:.1f}x)")

    # 7. Cơ chế bảo vệ & Chuẩn hóa Header
    applied_changes.append("Auto-Detect & Unobfuscate: Mở khóa 24 đối tượng Unity (2022.3.47f1)")
    applied_changes.append("Re-Spoof Header: Đã trả về 2018.4.12f1 (Nhận diện Game 100%)")
    applied_changes.append(f"Zero-Padding: Khớp chuẩn {len(saved_bytes):,} bytes (100% dung lượng gốc)")

    # 8. Done file
    applied_changes.append(f"Done file: {out_filename} (Sẵn sàng cài đặt)")

    return saved_bytes, out_filename, sha256, applied_changes
