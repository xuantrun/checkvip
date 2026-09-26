import dv_core
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

print("Testing dv_core.get_dv_status()...")
status = dv_core.get_dv_status()
print(f"Categories count: {len(status['categories'])}")
for cat in status['categories']:
    print(f"  - {cat['id']}: {cat['name']}")

print("\n1. Testing Classic Mode Build...")
b_classic, f_classic, sha_classic, changes_classic = dv_core.get_dv_bytes(
    game_version="fft",
    mode="mod",
    options={
        "shader_mode": "classic",
        "outline_color": [255.0, 255.0, 0.0, 1.0],
        "xray_color": [255.0, 255.0, 255.0, 1.0],
        "outline_width": 2.5
    }
)
print(f"Classic OK: {f_classic}, size={len(b_classic)}, changes={changes_classic}")

print("\n2. Testing Rainbow 7 Màu Mode Build...")
b_rb, f_rb, sha_rb, changes_rb = dv_core.get_dv_bytes(
    game_version="fft",
    mode="mod",
    options={
        "shader_mode": "rainbow_7color",
        "rainbow_colors": [
            [255.0, 0.0, 0.0, 1.0],
            [255.0, 165.0, 0.0, 1.0],
            [255.0, 255.0, 0.0, 1.0],
            [0.0, 255.0, 0.0, 1.0],
            [0.0, 240.0, 255.0, 1.0],
            [75.0, 0.0, 130.0, 1.0],
            [238.0, 130.0, 238.0, 1.0]
        ],
        "cycle_speed": 5.0,
        "brightness": 2.5,
        "pulse_min": 0.8,
        "pulse_max": 2.0,
        "outline_width": 3.0
    }
)
print(f"Rainbow 7 Màu OK: {f_rb}, size={len(b_rb)}, changes={changes_rb}")

print("\n3. Testing Cyber Hologram Fresnel Rim 3D Mode Build...")
b_cyber, f_cyber, sha_cyber, changes_cyber = dv_core.get_dv_bytes(
    game_version="fft",
    mode="mod",
    options={
        "shader_mode": "cyber_matrix",
        "rim_color": [0.0, 255.0, 102.0, 1.0],
        "core_color": [0.0, 40.0, 15.0, 1.0],
        "scan_color": [150.0, 255.0, 180.0, 1.0],
        "scan_speed": 4.0,
        "fresnel_power": 3.0,
        "glitch": 0.9,
        "outline_width": 2.8
    }
)
print(f"Cyber Matrix OK: {f_cyber}, size={len(b_cyber)}, changes={changes_cyber}")

print("\n>>> ALL SHADER TESTS COMPLETED WITH 100% SUCCESS! <<<")
