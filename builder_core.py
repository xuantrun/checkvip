import os
import struct
import hashlib

WORKSPACE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_GOC_NAME = "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D"
LEGACY_GOC_NAME = "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
FILE_NAME = DEFAULT_GOC_NAME
DEFAULT_GOC_PATH = os.path.join(WORKSPACE_DIR, "cache gốc", DEFAULT_GOC_NAME)

if not os.path.exists(DEFAULT_GOC_PATH):
    legacy_path = os.path.join(WORKSPACE_DIR, "cache gốc", LEGACY_GOC_NAME)
    if os.path.exists(legacy_path):
        DEFAULT_GOC_PATH = legacy_path

# Mapped offsets in cache gốc
OFFSETS = {
    "male_head": {
        "pid": 3844969807423664876,
        "name": "Male bone_Head (Đầu Nam)",
        "radius": 0xd304,
        "height": 0xd308,
        "direction": 0xd30c,
        "center_x": 0xd310,
        "center_y": 0xd314,
        "center_z": 0xd318,
    },
    "female_head": {
        "pid": 4273153183181864610,
        "name": "Female bone_Head (Đầu Nữ)",
        "radius": 0xd5f4,
        "height": 0xd5f8,
        "direction": 0xd5fc,
        "center_x": 0xd600,
        "center_y": 0xd604,
        "center_z": 0xd608,
    },
    "male_spine": {
        "pid": 3053026096585174879,
        "name": "Male bone_Spine (Thân Nam / Magic)",
        "radius": 0xcc0c,
        "height": 0xcc10,
        "direction": 0xcc14,
        "center_x": 0xcc18,
        "center_y": 0xcc1c,
        "center_z": 0xcc20,
    },
    "female_spine": {
        "pid": 5673995476223817236,
        "name": "Female bone_Spine (Thân Nữ / Magic)",
        "radius": 0xde9c,
        "height": 0xdea0,
        "direction": 0xdea4,
        "center_x": 0xdea8,
        "center_y": 0xdeac,
        "center_z": 0xdeb0,
    },
    "chest_spine1": {
        "pid": 6325248813538050388,
        "name": "bone_Spine1 (Ngực trên)",
        "radius": 0xe344,
        "height": 0xe348,
        "direction": 0xe34c,
        "center_x": 0xe350,
        "center_y": 0xe354,
        "center_z": 0xe358,
    },
    "sniper_collider": {
        "pid": -3891784277426559989,
        "name": "CapsuleHumanSniperCollider (Hitbox Súng Ngắm Sniper)",
        "radius": 0x800c,
        "height": 0x8010,
        "direction": 0x8014,
        "center_x": 0x8018,
        "center_y": 0x801c,
        "center_z": 0x8020,
    },
    "bone_hips": {
        "pid": -1061848883181629160,
        "name": "bone_Hips (Hông / Trọng tâm thân)",
        "radius": 0x9634,
        "height": 0x9638,
        "direction": 0x963c,
        "center_x": 0x9640,
        "center_y": 0x9644,
        "center_z": 0x9648,
    }
}

MOD_FORMULAS = {
    "nhe_tam": {
        "id": "nhe_tam",
        "name": "Mod Nhẹ Tâm (Chuẩn File Mẫu Có Tác Dụng 100%)",
        "desc": "Bán kính đầu 0.099059m, trục X lên +0.055245m (Nhẹ tâm ghim chuẩn đầu)!",
        "male_head": {"radius": 0.09905890, "center_x": 0.05524504, "center_y": 0.01705988},
        "female_head": {"radius": 0.09915388, "center_x": 0.05077528, "center_y": 0.00001997}
    },
    "cheast": {
        "id": "cheast",
        "name": "Mod Headshot / Cổ-Ngực (cache cheast)",
        "desc": "Bán kính đầu 0.099089m, trục X kéo về -0.010615m chuẩn khớp cổ!",
        "male_head": {"radius": 0.09908871, "center_x": -0.01061450, "center_y": 0.01705988},
        "female_head": {"radius": 0.09913578, "center_x": -0.01093376, "center_y": 0.00001997}
    },
    "body": {
        "id": "body",
        "name": "Mod Bắn Thân = Headshot (cache body)",
        "desc": "Bán kính đầu 0.099038m, kéo tâm đầu tụt xuống giữa bụng/thân (+0.121m)",
        "male_head": {"radius": 0.09903787, "center_x": 0.12103459, "center_y": 0.02009277},
        "female_head": {"radius": 0.09903276, "center_x": 0.12074338, "center_y": 0.01723830}
    },
    "sniper_hitbox": {
        "id": "sniper_hitbox",
        "name": "Mod Sniper Siêu Trúng Đích (AWM / M82B)",
        "desc": "Mở rộng riêng CapsuleHumanSniperCollider lên 1.2 mét: Bắn súng ngắm AWM/M82B/Kar98 lệch cả mét vẫn tự động dính đạn!",
        "sniper_collider": {"radius": 1.200000, "height": 1.800000}
    },
    "magic": {
        "id": "magic",
        "name": "Mod Magic Bullet (magic cache)",
        "desc": "Hitbox thân (bone_Spine) phình to 1.07 mét bao trọn quanh người!",
        "male_spine": {"radius": 1.07034874, "height": 1.07034874},
        "female_spine": {"radius": 1.07034874, "height": 1.07034874}
    },
    "super_magic": {
        "id": "super_magic",
        "name": "Super Magic Bullet 360° (Full Thân + Ngực + Hông)",
        "desc": "Phình to toàn bộ Thân (bone_Spine), Ngực (bone_Spine1) và Hông (bone_Hips) lên 1.07m, bao trọn 360 độ quanh người!",
        "male_spine": {"radius": 1.07034874, "height": 1.07034874},
        "female_spine": {"radius": 1.07034874, "height": 1.07034874},
        "chest_spine1": {"radius": 1.07034874, "height": 1.07034874},
        "bone_hips": {"radius": 1.07034874, "height": 1.07034874}
    },
    "combo_cheast_magic": {
        "id": "combo_cheast_magic",
        "name": "Combo Headshot + Magic Bullet",
        "desc": "Vừa ghim đầu 0.099089m (Cheast) + Vừa hitbox thân khổng lồ 1.07m (Magic)!",
        "male_head": {"radius": 0.09908871, "center_x": -0.01061450, "center_y": 0.01705988},
        "female_head": {"radius": 0.09913578, "center_x": -0.01093376, "center_y": 0.00001997},
        "male_spine": {"radius": 1.07034874, "height": 1.07034874},
        "female_spine": {"radius": 1.07034874, "height": 1.07034874}
    },
    "goc": {
        "id": "goc",
        "name": "Khôi Phục Gốc (Chuẩn Game)",
        "desc": "Đưa tất cả về thông số nguyên bản 100%",
        "male_head": {"radius": 0.059059, "center_x": -0.045245, "center_y": 0.01706},
        "female_head": {"radius": 0.059154, "center_x": -0.040775, "center_y": 0.00002},
        "male_spine": {"radius": 0.070294, "height": 0.179913},
        "female_spine": {"radius": 0.070290, "height": 0.170000}
    }
}

def load_base_file(path=None):
    p = path or DEFAULT_GOC_PATH
    if not os.path.exists(p):
        raise FileNotFoundError(f"Không tìm thấy file gốc tại: {p}")
    with open(p, "rb") as f:
        return bytearray(f.read())

def read_values_from_bytes(b):
    try:
        male_head = {
            'radius': round(struct.unpack('<f', b[0xd304:0xd308])[0], 6),
            'height': round(struct.unpack('<f', b[0xd308:0xd30c])[0], 6),
            'direction': struct.unpack('<I', b[0xd30c:0xd310])[0],
            'center_x': round(struct.unpack('<f', b[0xd310:0xd314])[0], 6),
            'center_y': round(struct.unpack('<f', b[0xd314:0xd318])[0], 6),
            'center_z': round(struct.unpack('<f', b[0xd318:0xd31c])[0], 6),
        }
        female_head = {
            'radius': round(struct.unpack('<f', b[0xd5f4:0xd5f8])[0], 6),
            'height': round(struct.unpack('<f', b[0xd5f8:0xd5fc])[0], 6),
            'direction': struct.unpack('<I', b[0xd5fc:0xd600])[0],
            'center_x': round(struct.unpack('<f', b[0xd600:0xd604])[0], 6),
            'center_y': round(struct.unpack('<f', b[0xd604:0xd608])[0], 6),
            'center_z': round(struct.unpack('<f', b[0xd608:0xd60c])[0], 6),
        }
        male_spine = {
            'radius': round(struct.unpack('<f', b[0xcc0c:0xcc10])[0], 6),
            'height': round(struct.unpack('<f', b[0xcc10:0xcc14])[0], 6),
            'center_x': round(struct.unpack('<f', b[0xcc18:0xcc1c])[0], 6),
            'center_y': round(struct.unpack('<f', b[0xcc1c:0xcc20])[0], 6),
            'center_z': round(struct.unpack('<f', b[0xcc20:0xcc24])[0], 6),
        }
        female_spine = {
            'radius': round(struct.unpack('<f', b[0xde9c:0xdea0])[0], 6),
            'height': round(struct.unpack('<f', b[0xdea0:0xdea4])[0], 6),
            'center_x': round(struct.unpack('<f', b[0xdea8:0xdeac])[0], 6),
            'center_y': round(struct.unpack('<f', b[0xdeac:0xdeb0])[0], 6),
            'center_z': round(struct.unpack('<f', b[0xdeb0:0xdeb4])[0], 6),
        }
        return {
            'success': True,
            'male_head': male_head,
            'female_head': female_head,
            'male_spine': male_spine,
            'female_spine': female_spine
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}

def build_mod_file(base_bytes, params):
    """
    params = {
        'male_head': {'radius': ..., 'center_x': ...},
        'female_head': {...},
        'male_spine': {'radius': ..., 'height': ...}, # only if present
        'female_spine': {'radius': ..., 'height': ...} # only if present
    }
    """
    out = bytearray(base_bytes)
    applied_changes = []
    
    for part_key, part_vals in params.items():
        if part_key not in OFFSETS or not part_vals:
            continue
        part_info = OFFSETS[part_key]
        for field, val in part_vals.items():
            if field in part_info and val is not None:
                off = part_info[field]
                if field == 'direction':
                    val_int = int(val)
                    old_val = struct.unpack('<I', out[off:off+4])[0]
                    struct.pack_into('<I', out, off, val_int)
                    if val_int != old_val:
                        applied_changes.append({
                            'part': part_info['name'],
                            'field': field,
                            'offset': hex(off),
                            'old_value': old_val,
                            'new_value': val_int,
                            'diff': val_int - old_val
                        })
                else:
                    val_flt = float(val)
                    old_val = struct.unpack('<f', out[off:off+4])[0]
                    struct.pack_into('<f', out, off, val_flt)
                    if abs(val_flt - old_val) > 1e-5:
                        applied_changes.append({
                            'part': part_info['name'],
                            'field': field,
                            'offset': hex(off),
                            'old_value': round(old_val, 6),
                            'new_value': round(val_flt, 6),
                            'diff': round(val_flt - old_val, 6)
                        })
                
    # Re-Spoof Header to 2018.4.12f1 for new game version compatibility
    header_chunk = bytes(out[:256])
    if b"2022.3.47f1" in header_chunk:
        spoofed = header_chunk.replace(b"2022.3.47f1", b"2018.4.12f1")
        out[:256] = spoofed
        applied_changes.append({
            'part': 'Header Version',
            'field': 'Re-Spoof',
            'offset': '0x12, 0xb0',
            'old_value': '2022.3.47f1',
            'new_value': '2018.4.12f1',
            'diff': 'Chuẩn Game Mới'
        })

    sha256 = hashlib.sha256(out).hexdigest()
    return bytes(out), sha256, applied_changes
