# 👑 FLORK MOD STUDIO (ALL-IN-ONE)
### 🔫 Mod Màu Súng Dây Vàng & 🎯 Mod Hitbox Free Fire (Web • REST API • iOS App IPA)

![Banner](https://img.shields.io/badge/Platform-iOS%20%7C%20Web%20%7C%20REST%20API-00f2fe?style=for-the-badge)
![Swift](https://img.shields.io/badge/Swift-5.0%20(SwiftUI)-orange?style=for-the-badge&logo=swift)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=for-the-badge&logo=python)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-Auto%20Build%20IPA-2088FF?style=for-the-badge&logo=githubactions)

Dự án toàn diện bao gồm:
1. **Web Studio (`app.py`)**: Giao diện Web trực quan, trực quan hóa màu súng Canvas 2 màu và Hitbox.
2. **REST API Chuẩn Hóa (`api/`)**: Máy chủ API độc lập với đầy đủ endpoints cho việc vá file nhị phân, xuất tải file và tích hợp với bên thứ ba.
3. **Source App iOS Native (`FlorkModStudio_iOS/`)**: Dự án SwiftUI tương thích iOS 15.0 - 17.x+, hỗ trợ vá nhị phân Offline ngay trên iPhone + TrollStore 1-Click Inject trực tiếp vào game!
4. **CI/CD Tự Động Build File `.ipa` (`.github/workflows/build-ipa.yml`)**: Tự động build và đóng gói file `.ipa` trên máy ảo macOS của GitHub Actions mà không cần bạn phải sở hữu máy Mac!

---

## 🌟 1. Tính Năng Nổi Bật

### 🔫 A. Mod Màu Súng Dây Vàng (Shaders)
- **Hỗ trợ 2 bản game**:
  - `Free Fire Thường (FFT)`: `shaders.HPt9DZviTSXL9hpGW9QNOMigNLA~3D`
  - `Free Fire MAX (FFM)`: `shaders.RXqs706xmtWYhbN9TqDzP8LDRzk~3D`
- **Công nghệ phối 2 màu độc lập**:
  - **Vị trí 1 (Màu thân súng M4A1)**: Thay đổi `_OutLineColor` tại các offset nhị phân `0x24eb55, 0x4fddf5, 0x9a4ddd`.
  - **Vị trí 2 (Mảng nền poster phía sau)**: Thay đổi `_XRayColor` tại các offset `0x24eabd, 0x4fdd5d, 0x9a4d45`.
  - **Độ dày viền**: Tinh chỉnh `_OutLineWidth` từ 0.5px đến 8.0px.
- **Preset màu 1 chạm**: Vàng Chanh + Trắng Tuyết (Chuẩn trong ảnh), Đỏ Lửa + Trắng, Xanh Neon + Trắng, Xanh Lá + Trắng, Tím Plasma + Trắng, Vàng + Đen Tuyền.

### 🎯 B. Mod Hitbox & Đạn (Cache Res)
- **File tác động**: `cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D` (63,056 bytes).
- **Công thức 1 chạm cực đỉnh**:
  - 🎯 **Ghim Headshot (`cheast`)**: Đầu to +68%, kéo nhẹ cổ/ngực (-0.011m).
  - 💥 **Bắn Thân = Headshot (`body`)**: Kéo tâm đầu tụt xuống giữa bụng (+0.121m).
  - 🔮 **Magic Bullet (`magic`)**: Hitbox thân phình to 1.07 mét bao quanh toàn thân.
  - 👑 **Combo Siêu Cấp**: Ghim đầu + Hitbox thân 1.07m.
  - 🔄 **Khôi phục gốc**: Đưa toàn bộ về chỉ số chuẩn của Garena.
- **Bộ điều khiển chi tiết (Fine-Tuning)**: Bán kính, chiều cao, tọa độ X/Y/Z của Nam & Nữ kèm nút đồng bộ tự động.

---

## 📱 2. Source App iOS (SwiftUI) & Đóng Gói IPA

Thư mục: `FlorkModStudio_iOS/`

### Cấu Trúc Dự Án:
```
FlorkModStudio_iOS/
├── FlorkModStudio.xcodeproj       # Cấu hình dự án Xcode
└── FlorkModStudio/
    ├── App/
    │   └── FlorkModStudioApp.swift
    ├── Models/
    │   ├── ShaderModels.swift      # Cấu trúc màu, preset, offset shader
    │   └── HitboxModels.swift      # Cấu trúc offset, preset hitbox
    ├── Services/
    │   ├── BinaryPatcher.swift     # Engine vá nhị phân Little-Endian thuần Swift
    │   ├── APIService.swift        # Client kết nối REST API máy chủ từ xa
    │   └── GameInjector.swift      # TrollStore/Jailbreak Inject & Lưu vào Tệp
    ├── Views/
    │   ├── GunPreviewCanvas.swift  # Canvas vẽ súng M4A1 trực quan thời gian thực
    │   ├── GunModView.swift        # Giao diện Mod Màu Súng
    │   ├── HitboxModView.swift     # Giao diện Mod Hitbox & Đạn
    │   ├── GameGuideView.swift     # Hướng dẫn chi tiết cho TrollStore / Sideload
    │   ├── SettingsView.swift      # Cài đặt chế độ Offline/Online
    │   └── ContentView.swift       # Tab bar điều hướng chính
    └── Resources/
        ├── Info.plist              # Cấu hình app iOS (Document sharing, ATS)
        └── cache_res.CfnFf...      # File cache gốc đính kèm
```

### Cách Tải File IPA Tự Động Từ GitHub Actions:
1. Đẩy mã nguồn lên GitHub.
2. Vào tab **Actions** -> Chọn workflow **Build Flork Mod Studio IPA**.
3. Bấm **Run workflow**.
4. GitHub Actions sẽ tự khởi động máy ảo macOS, biên dịch mã nguồn Swift và tạo file `FlorkModStudio.ipa` trong mục **Artifacts** và **Releases** để bạn tải về cài vào điện thoại!

---

## 🚀 3. REST API Service

Thư mục: `api/` (Xem chi tiết tại [api/README.md](api/README.md))

### Khởi Chạy API Nhanh:
```bash
# Cài đặt thư viện
pip install -r api/requirements.txt

# Khởi chạy server
python api/api_server.py
```

### Endpoints Chính:
- `GET /api/v1/health`: Kiểm tra trạng thái server.
- `GET /api/v1/gun/status`: Lấy danh sách preset và trạng thái shader.
- `POST /api/v1/gun/build`: Vá và xuất file shader theo màu tùy biến.
- `GET /api/v1/gun/download/<build_id>`: Tải file shader đã mod.
- `GET /api/v1/hitbox/info`: Đọc thông số và offset của `cache_res`.
- `POST /api/v1/hitbox/build`: Vá file cache theo công thức hoặc custom offset.
- `GET /api/v1/hitbox/download/<build_id>`: Tải file `cache_res` đã mod.

---

## 🛠️ 4. Chạy Web Studio Trên Máy Tính

Chạy file batch:
```cmd
run_web.bat
```
Hoặc:
```bash
python app.py
```
- Mở trình duyệt: `http://127.0.0.1:5678`
- Mở trên điện thoại cùng mạng Wi-Fi: `http://<IP-May-Tinh>:5678`

---

## 📄 Bản Quyền & Giấy Phép
Dự án được xây dựng phục vụ nghiên cứu cấu trúc tệp nhị phân và phát triển công cụ phần mềm.
Mọi thắc mắc và đóng góp vui lòng mở Issue hoặc Pull Request trên GitHub!
