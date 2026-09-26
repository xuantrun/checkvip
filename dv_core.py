import os
import hashlib
import struct

WORKSPACE_DIR = os.path.dirname(os.path.abspath(__file__))

DV_FILES = {
    "fft": {
        "id": "fft",
        "name": "Free Fire Thường (FFT)",
        "filename": "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA~3D",
        "desc": "File shader dành cho bản Free Fire Original / Thường",
        "goc_path": os.path.join(WORKSPACE_DIR, "dv goc", "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA~3D"),
        "mod_path": os.path.join(WORKSPACE_DIR, "dv mod", "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA~3D"),
    },
    "ffm": {
        "id": "ffm",
        "name": "Free Fire MAX (FFM)",
        "filename": "shaders.RXqs706xmtWYhbN9TqDzP8LDRzk~3D",
        "desc": "File shader dành cho bản Free Fire MAX",
        "goc_path": os.path.join(WORKSPACE_DIR, "dv goc", "shaders.RXqs706xmtWYhbN9TqDzP8LDRzk~3D"),
        "mod_path": os.path.join(WORKSPACE_DIR, "dv mod", "shaders.RXqs706xmtWYhbN9TqDzP8LDRzk~3D"),
    }
}

DV_OFFSETS = {
    'fft': {
        'outline_color': [0x24eb55, 0x4fddf5, 0x9a4ddd],
        'xray_color': [0x24eabd, 0x4fdd5d, 0x9a4d45],
        'outline_width': [0x24eb09, 0x4fdda9, 0x9a4d91],
    },
    'ffm': {
        'outline_color': [0x24eb51, 0x4fddf1, 0x9a4dd9],
        'xray_color': [0x24eab9, 0x4fdd59, 0x9a4d41],
        'outline_width': [0x24eb05, 0x4fdda5, 0x9a4d8d],
    }
}

DV_COLOR_PRESETS = [
    {"id": "cyan", "name": "Xanh Băng Glow (Chuẩn Trong Ảnh)", "hex": "#00f2fe", "rgba": [0.0, 242.0, 254.0, 1.0]},
    {"id": "green", "name": "Xanh Lá Dạ Quang (Toxic Glow)", "hex": "#00ff66", "rgba": [0.0, 255.0, 102.0, 1.0]},
    {"id": "yellow", "name": "Vàng Chanh Rực Sáng (Gold Glow)", "hex": "#ffff00", "rgba": [255.0, 255.0, 0.0, 1.0]},
    {"id": "red", "name": "Đỏ Lửa Neon (Crimson Glow)", "hex": "#ff0033", "rgba": [255.0, 0.0, 51.0, 1.0]},
    {"id": "purple", "name": "Tím Plasma (Plasma Glow)", "hex": "#b026ff", "rgba": [176.0, 38.0, 255.0, 1.0]},
    {"id": "pink", "name": "Hồng Dạ Quang (Cyber Pink)", "hex": "#ff007f", "rgba": [255.0, 0.0, 127.0, 1.0]},
    {"id": "white", "name": "Trắng Tuyết Phát Quang (White Glow)", "hex": "#ffffff", "rgba": [255.0, 255.0, 255.0, 1.0]},
    {"id": "orange", "name": "Cam Lửa Rực Rỡ (Magma Glow)", "hex": "#ff6600", "rgba": [255.0, 102.0, 0.0, 1.0]},
]

def get_dv_status():
    res = {}
    for k, v in DV_FILES.items():
        goc_exists = os.path.exists(v['goc_path'])
        mod_exists = os.path.exists(v['mod_path'])
        goc_size = os.path.getsize(v['goc_path']) if goc_exists else 0
        mod_size = os.path.getsize(v['mod_path']) if mod_exists else 0
        
        res[k] = {
            'id': v['id'],
            'name': v['name'],
            'filename': v['filename'],
            'desc': v['desc'],
            'goc_exists': goc_exists,
            'mod_exists': mod_exists,
            'goc_size': goc_size,
            'mod_size': mod_size,
        }
    return {
        'versions': res,
        'presets': DV_COLOR_PRESETS
    }

def get_dv_bytes(game_version="fft", mode="mod", options=None):
    """
    game_version: 'fft' or 'ffm'
    mode: 'mod' or 'goc'
    options: {
        'outline_color': [r, g, b, a],
        'xray_color': [r, g, b, a],
        'outline_width': float
    }
    """
    if game_version not in DV_FILES:
        raise ValueError(f"Phiên bản không hợp lệ: {game_version}")
        
    v = DV_FILES[game_version]
    path = v['mod_path'] if mode == 'mod' else v['goc_path']
    
    if not os.path.exists(path):
        raise FileNotFoundError(f"Không tìm thấy file tại: {path}")
        
    with open(path, 'rb') as f:
        data = bytearray(f.read())
        
    applied_changes = []
    
    if mode == 'mod' and options:
        offsets = DV_OFFSETS.get(game_version, {})
        
        # 1. Custom Outline Color (Màu Dây Viền)
        if 'outline_color' in options and options['outline_color']:
            c = options['outline_color']
            r, g, b = float(c[0]), float(c[1]), float(c[2])
            a = float(c[3]) if len(c) > 3 else 1.0
            for off in offsets.get('outline_color', []):
                struct.pack_into('<ffff', data, off, r, g, b, a)
            applied_changes.append(f"Màu Dây Viền (_OutLineColor) -> RGB({int(r)}, {int(g)}, {int(b)})")
            
        # 2. Custom X-Ray Color (Màu Thân X-Ray)
        if 'xray_color' in options and options['xray_color']:
            xc = options['xray_color']
            xr, xg, xb = float(xc[0]), float(xc[1]), float(xc[2])
            xa = float(xc[3]) if len(xc) > 3 else 1.0
            for off in offsets.get('xray_color', []):
                struct.pack_into('<ffff', data, off, xr, xg, xb, xa)
            applied_changes.append(f"Màu Thân X-Ray (_XRayColor) -> RGB({int(xr)}, {int(xg)}, {int(xb)})")
            
        # 3. Custom Outline Width (Độ Dày Dây Viền)
        if 'outline_width' in options and options['outline_width'] is not None:
            w = float(options['outline_width'])
            for off in offsets.get('outline_width', []):
                struct.pack_into('<f', data, off, w)
            applied_changes.append(f"Độ Dày Dây Viền (_OutLineWidth) -> {w} px")
            
    out_bytes = bytes(data)
    sha256 = hashlib.sha256(out_bytes).hexdigest()
    return out_bytes, v['filename'], sha256, applied_changes
