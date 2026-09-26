# 🚀 FLORK MOD STUDIO REST API DOCUMENTATION

Tài liệu hướng dẫn và đặc tả kỹ thuật toàn diện cho REST API của Flork Mod Studio (Mod Màu Súng Dây Vàng & Mod Hitbox Đạn Free Fire).

---

## 1. Tổng Quan & Base URL

- **Local Dev**: `http://127.0.0.1:5678`
- **Docker / Production**: `http://<your-server-ip>:5678`
- **Định dạng dữ liệu**: `application/json`
- **Mã hóa nhị phân file download**: `application/octet-stream`

---

## 2. Danh Sách Endpoint

### 🟢 2.1 Kiểm tra trạng thái máy chủ (Health Check)
- **URL**: `/api/v1/health`
- **Phương thức**: `GET`
- **Phản hồi mẫu**:
```json
{
  "status": "online",
  "app_name": "Flork Mod Studio REST API",
  "version": "v1.0.0",
  "modules": {
    "gun_shader": "Active (Dây Vàng FFT & FFM)",
    "hitbox_cache": "Active (Hitbox & Magic Bullet)"
  }
}
```

---

### 🔫 2.2 Mod Màu Súng Dây Vàng (Shader Modding)

#### a) Lấy danh sách preset & thông tin shader
- **URL**: `/api/v1/gun/status`
- **Phương thức**: `GET`
- **Phản hồi**: Trả về trạng thái file gốc, file mod của 2 bản FFT (Thường) và FFM (MAX), danh sách mã màu chuẩn (Vàng Chanh, Đỏ, Xanh Neon, v.v.).

#### b) Tạo file shader mod
- **URL**: `/api/v1/gun/build`
- **Phương thức**: `POST`
- **Headers**: `Content-Type: application/json`
- **Payload Request**:
```json
{
  "version": "fft",
  "mode": "mod",
  "options": {
    "outline_color": [255.0, 255.0, 0.0, 1.0],
    "xray_color": [255.0, 255.0, 255.0, 1.0],
    "outline_width": 2.0
  }
}
```
- **Phản hồi mẫu**:
```json
{
  "success": true,
  "build_id": "gun_fft_mod_1710000000000",
  "filename": "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA~3D",
  "size": 13178417,
  "sha256": "3a8b...",
  "applied_changes": [
    "Màu Dây Viền (_OutLineColor) -> RGB(255, 255, 0)",
    "Màu Thân X-Ray (_XRayColor) -> RGB(255, 255, 255)",
    "Độ Dày Dây Viền (_OutLineWidth) -> 2.0 px"
  ],
  "download_url": "http://127.0.0.1:5678/api/v1/gun/download/gun_fft_mod_1710000000000"
}
```

#### c) Tải file shader
- **URL**: `/api/v1/gun/download/<build_id>`
- **Phương thức**: `GET`
- **Phản hồi**: Trả về trực tiếp binary stream của file `shaders...` để client lưu vào máy.

---

### 🎯 2.3 Mod Hitbox & Đạn (Cache Res)

#### a) Lấy thông số hitbox gốc & presets
- **URL**: `/api/v1/hitbox/info`
- **Phương thức**: `GET`
- **Phản hồi**: Trả về các giá trị bán kính, chiều cao, tọa độ x, y, z hiện tại của Nam/Nữ và các công thức mod (`cheast`, `body`, `magic`, `combo_cheast_magic`).

#### b) Tạo file cache_res mod
- **URL**: `/api/v1/hitbox/build`
- **Phương thức**: `POST`
- **Headers**: `Content-Type: application/json`
- **Payload Request (Theo Preset)**:
```json
{
  "preset": "combo_cheast_magic"
}
```
- **Payload Request (Tùy biến Custom Coordinates)**:
```json
{
  "custom_params": {
    "male_head": {
      "radius": 0.09908871,
      "center_x": -0.0106145
    },
    "male_spine": {
      "radius": 1.07034874,
      "height": 1.07034874
    }
  }
}
```
- **Phản hồi mẫu**:
```json
{
  "success": true,
  "build_id": "hitbox_1710000000000",
  "filename": "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
  "size": 63056,
  "sha256": "5c4d...",
  "changes_count": 4,
  "download_url": "http://127.0.0.1:5678/api/v1/hitbox/download/hitbox_1710000000000"
}
```

#### c) Tải file cache_res
- **URL**: `/api/v1/hitbox/download/<build_id>`
- **Phương thức**: `GET`
- **Phản hồi**: Binary stream file `cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D` 63,056 bytes.

---

## 3. Chạy Khởi Động API

```bash
# Cài đặt thư viện
pip install -r api/requirements.txt

# Chạy server
python api/api_server.py
```
Hoặc chạy bằng Docker:
```bash
docker build -t flork-mod-api -f api/Dockerfile .
docker run -p 5678:5678 flork-mod-api
```
