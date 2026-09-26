// FLORK MODDING SUITE - FRONTEND CONTROLLER (HITBOX + DÂY VÀNG SHADERS)

let state = {
    currentModule: "hitbox",
    sourceName: "cache gốc",
    fileSize: 63056,
    syncGender: true,
    activeTab: "male",
    currentPartTab: "head",
    currentBuildId: null,
    enableMagicBullet: false, // Explicit toggle
    
    // DV Studio state
    dvVersion: "fft", // 'fft' or 'ffm'
    currentDvBuildId: null,
    dvOutlineColor: [255.0, 255.0, 0.0, 1.0], // Yellow by default
    dvOutlineHex: "#ffff00",
    dvOutlineWidth: 2.0,
    dvXRayColor: [255.0, 255.0, 255.0, 1.0], // White by default
    dvXRayHex: "#ffffff",

    // Original values loaded from file
    originalMaleHead: {
        radius: 0.05905882,
        height: 0.12749058,
        center_x: -0.04524504,
        center_y: 0.01705988,
        center_z: -0.00047458
    },
    originalFemaleHead: {
        radius: 0.05915398,
        height: 0.13038424,
        center_x: -0.04077539,
        center_y: 0.00001997,
        center_z: -0.00000000
    },
    originalMaleSpine: {
        radius: 0.07029372,
        height: 0.17991276
    },
    originalFemaleSpine: {
        radius: 0.07028999,
        height: 0.17000000
    },

    // Current working values (being edited)
    maleHead: {
        radius: 0.05905882,
        height: 0.12749058,
        center_x: -0.04524504,
        center_y: 0.01705988,
        center_z: -0.00047458
    },
    femaleHead: {
        radius: 0.05915398,
        height: 0.13038424,
        center_x: -0.04077539,
        center_y: 0.00001997,
        center_z: -0.00000000
    },
    maleSpine: {
        radius: 0.07029372,
        height: 0.17991276
    },
    femaleSpine: {
        radius: 0.07028999,
        height: 0.17000000
    }
};

document.addEventListener('DOMContentLoaded', () => {
    initApp();
    setupEventListeners();
    switchModule('dv'); // Mặc định mở tab Mod Màu Súng cho người dùng!
});

async function initApp() {
    try {
        const res = await fetch('/api/base_info');
        const data = await res.json();
        if (data.success) {
            state.sourceName = data.source_name;
            state.fileSize = data.file_size;
            
            const snEl = document.getElementById('sourceNameDisplay');
            const fsEl = document.getElementById('fileSizeDisplay');
            if (snEl) snEl.innerText = data.source_name;
            if (fsEl) fsEl.innerText = data.file_size.toLocaleString() + ' B';
            
            const vals = data.current_values || {};
            if (vals.male_head) state.maleHead = vals.male_head;
            if (vals.female_head) state.femaleHead = vals.female_head;
            if (vals.male_spine) state.maleSpine = vals.male_spine;
            if (vals.female_spine) state.femaleSpine = vals.female_spine;
            
            if (data.local_ip) {
                const wifiIpEl = document.getElementById('wifiIpText');
                if (wifiIpEl) wifiIpEl.innerText = `${data.local_ip}:${data.port || 5678}`;
            }
            
            syncInputs();
        }
    } catch (e) {
        showToast('Lỗi kết nối máy chủ: ' + e.message, 'error');
    }
}

/* MODULE SWITCHER (USER-CENTRIC: DV, HITBOX, GUIDE) */
function switchModule(mod) {
    state.currentModule = mod;
    const btnDV = document.getElementById('btnModDV');
    const btnHitbox = document.getElementById('btnModHitbox');
    const btnAvatar = document.getElementById('btnModAvatar');
    const btnGuide = document.getElementById('btnModGuide');
    if (btnDV) btnDV.classList.toggle('active', mod === 'dv');
    if (btnHitbox) btnHitbox.classList.toggle('active', mod === 'hitbox');
    if (btnAvatar) btnAvatar.classList.toggle('active', mod === 'avatar');
    if (btnGuide) btnGuide.classList.toggle('active', mod === 'guide');

    const modDV = document.getElementById('moduleDV');
    const modHitbox = document.getElementById('moduleHitbox');
    const modAvatar = document.getElementById('moduleAvatar');
    const modGuide = document.getElementById('moduleGuide');
    if (modDV) modDV.style.display = mod === 'dv' ? 'grid' : 'none';
    if (modHitbox) modHitbox.style.display = mod === 'hitbox' ? 'grid' : 'none';
    if (modAvatar) modAvatar.style.display = mod === 'avatar' ? 'grid' : 'none';
    if (modGuide) modGuide.style.display = mod === 'guide' ? 'grid' : 'none';

    if (mod === 'dv') {
        drawDVGun();
    } else if (mod === 'hitbox') {
        drawMannequin();
    }
}

/* =========================================================
   AVATAR MOD (ASSETINDEXER) FRONTEND CONTROLLER
========================================================= */
let currentAvatarBuildId = null;
let currentAvatarPreset = 'aimbot_head';

function selectAvatarPreset(preset) {
    currentAvatarPreset = preset;
    ['avtPresetHead', 'avtPresetNeck', 'avtPresetBody', 'avtPresetHips'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.classList.remove('active');
    });

    const boneEl = document.getElementById('avtTargetBone');
    const hashEl = document.getElementById('avtParentHash');
    const scaleEl = document.getElementById('avtScale');
    const scaleValEl = document.getElementById('avtScaleVal');

    if (preset === 'aimbot_head') {
        document.getElementById('avtPresetHead')?.classList.add('active');
        if (boneEl) boneEl.value = 'bone_Head';
        if (hashEl) hashEl.value = '-1541408846';
        if (scaleEl) scaleEl.value = '1.55';
        if (scaleValEl) scaleValEl.innerText = '1.55x';
    } else if (preset === 'aimbot_neck') {
        document.getElementById('avtPresetNeck')?.classList.add('active');
        if (boneEl) boneEl.value = 'bone_Head';
        if (hashEl) hashEl.value = '-1541408846';
        if (scaleEl) scaleEl.value = '1.55';
        if (scaleValEl) scaleValEl.innerText = '1.55x';
    } else if (preset === 'aim_body_all_hs') {
        document.getElementById('avtPresetBody')?.classList.add('active');
        if (boneEl) boneEl.value = 'bone_Spine';
        if (hashEl) hashEl.value = '1529948125';
        if (scaleEl) scaleEl.value = '2.00';
        if (scaleValEl) scaleValEl.innerText = '2.00x';
    } else if (preset === 'aim_hips_hs') {
        document.getElementById('avtPresetHips')?.classList.add('active');
        if (boneEl) boneEl.value = 'bone_Hips';
        if (hashEl) hashEl.value = '2018908708';
        if (scaleEl) scaleEl.value = '2.00';
        if (scaleValEl) scaleValEl.innerText = '2.00x';
    }
}

async function triggerAvatarBuild() {
    const btn = document.getElementById('btnBuildAvatar');
    btn.disabled = true;
    btn.innerHTML = `<span>⏳ Đang biên dịch AssetIndexer...</span>`;

    try {
        const authHeaders = getAuthHeaders();
        const payload = {
            preset_id: currentAvatarPreset,
            target_bone: document.getElementById('avtTargetBone')?.value || 'bone_Head',
            parent_hash: parseInt(document.getElementById('avtParentHash')?.value || '-1541408846'),
            scale: parseFloat(document.getElementById('avtScale')?.value || '1.55'),
            mod_male: true,
            mod_female: true,
            mod_big_gun: document.getElementById('avtModBigGun')?.checked || false,
            gun_scale: parseFloat(document.getElementById('avtGunScale')?.value || '3.5'),
            match_size: true,
            patch_monoscript: true
        };

        const res = await fetch('/api/avatar/build', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', ...authHeaders },
            body: JSON.stringify({ ...payload, ...authHeaders })
        });

        if (res.status === 401 || res.status === 403) {
            const errData = await res.json().catch(() => ({}));
            openAuthModal();
            showToast(errData.error || 'Yêu cầu tài khoản VIP 2 để tạo Avatar Mod!', 'error');
            return;
        }

        const data = await res.json();
        if (data.success) {
            currentAvatarBuildId = data.build_id;
            document.getElementById('avtBuildResult').style.display = 'block';
            document.getElementById('avtBuildInfo').innerText = 
                `✓ Tạo thành công ${data.filename} (${data.size.toLocaleString()} bytes) | SHA: ${data.sha256.substring(0, 12)}...`;

            let logText = `[MAKE AVATAR THÀNH CÔNG] File: ${data.filename}\n`;
            logText += `Dung lượng: ${data.size} bytes (Khớp chuẩn gốc 100%)\n`;
            logText += `SHA256: ${data.sha256}\n\n`;
            logText += `DANH SÁCH CAN THIỆP:\n`;
            (data.changes || []).forEach(c => {
                logText += ` • ${c}\n`;
            });
            document.getElementById('avtLogContent').innerText = logText;
            showToast('Biên dịch file Avatar thành công!', 'success');
        } else {
            showToast('Lỗi build: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi mạng: ' + e.message, 'error');
    } finally {
        btn.disabled = false;
        btn.innerHTML = `🚀 TẠO FILE AVATAR MOD (ASSETINDEXER)`;
    }
}

function downloadAvatarBuild() {
    if (!currentAvatarBuildId) {
        showToast('Chưa có bản build Avatar nào để tải!', 'error');
        return;
    }
    window.location.href = `/api/avatar/download/${currentAvatarBuildId}`;
}

function copyWifiUrl() {
    const badgeText = document.getElementById('wifiIpText')?.innerText?.trim();
    let url = badgeText ? (badgeText.startsWith('http') ? badgeText : `http://${badgeText}`) : `http://${window.location.hostname || '127.0.0.1'}:5678`;
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(() => {
            showToast('📋 Đã sao chép link Wi-Fi: ' + url, 'success');
        }).catch(() => {
            prompt('Sao chép đường link này để mở trên điện thoại:', url);
        });
    } else {
        prompt('Sao chép đường link này để mở trên điện thoại:', url);
    }
}

function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => {
            showToast('📋 Đã sao chép đường dẫn!', 'success');
        }).catch(() => {
            prompt('Sao chép:', text);
        });
    } else {
        prompt('Sao chép:', text);
    }
}

function switchPartTab(tab) {
    state.currentPartTab = tab;
    document.getElementById('btnTabHead').classList.toggle('active', tab === 'head');
    document.getElementById('btnTabSpine').classList.toggle('active', tab === 'spine');
    
    document.getElementById('partSectionHead').style.display = tab === 'head' ? 'block' : 'none';
    document.getElementById('partSectionSpine').style.display = tab === 'spine' ? 'block' : 'none';
}

function setupEventListeners() {
    // Sync checkbox
    const syncChk = document.getElementById('syncGender');
    if (syncChk) {
        syncChk.addEventListener('change', (e) => {
            state.syncGender = e.target.checked;
            document.getElementById('genderTabs').style.display = state.syncGender ? 'none' : 'flex';
        });
    }

    // Male Head listeners
    bindInputPair('male_radius', 'male_radius_num', (val) => {
        state.maleHead.radius = parseFloat(val);
        document.getElementById('male_radius_val').innerText = Number(val).toFixed(5) + ' m';
        if (state.syncGender) {
            const ratio = state.originalFemaleHead.radius / (state.originalMaleHead.radius || 1);
            state.femaleHead.radius = state.maleHead.radius * ratio;
            syncInputs();
        }
        drawMannequin();
    });

    bindInputPair('male_center_x', 'male_center_x_num', (val) => {
        state.maleHead.center_x = parseFloat(val);
        document.getElementById('male_center_x_val').innerText = Number(val).toFixed(5) + ' m';
        if (state.syncGender) {
            state.femaleHead.center_x = state.maleHead.center_x;
            syncInputs();
        }
        drawMannequin();
    });

    bindInputPair('male_height', 'male_height_num', (val) => {
        state.maleHead.height = parseFloat(val);
        document.getElementById('male_height_val').innerText = Number(val).toFixed(5) + ' m';
        if (state.syncGender) {
            state.femaleHead.height = state.maleHead.height;
            syncInputs();
        }
        drawMannequin();
    });

    // Spine / Magic Bullet listeners
    bindInputPair('spine_radius', 'spine_radius_num', (val) => {
        state.maleSpine.radius = parseFloat(val);
        state.femaleSpine.radius = parseFloat(val);
        state.enableMagicBullet = (parseFloat(val) > 0.15);
        document.getElementById('spine_radius_val').innerText = Number(val).toFixed(5) + ' m';
        drawMannequin();
    });

    bindInputPair('spine_height', 'spine_height_num', (val) => {
        state.maleSpine.height = parseFloat(val);
        state.femaleSpine.height = parseFloat(val);
        document.getElementById('spine_height_val').innerText = Number(val).toFixed(5) + ' m';
        drawMannequin();
    });
}

function bindInputPair(rangeId, numId, callback) {
    const range = document.getElementById(rangeId);
    const num = document.getElementById(numId);
    if (!range || !num) return;

    range.addEventListener('input', (e) => {
        const val = parseFloat(e.target.value).toFixed(5);
        num.value = val;
        callback(val);
    });
    
    num.addEventListener('input', (e) => {
        const val = parseFloat(e.target.value) || 0;
        range.value = val;
        callback(val.toFixed(5));
    });
}

function syncInputs() {
    // Male Head
    const mrEl = document.getElementById('male_radius');
    const mrnEl = document.getElementById('male_radius_num');
    const mrvEl = document.getElementById('male_radius_val');
    if (mrEl && mrnEl) {
        mrEl.value = state.maleHead.radius;
        mrnEl.value = Number(state.maleHead.radius).toFixed(5);
        if (mrvEl) mrvEl.innerText = Number(state.maleHead.radius).toFixed(5) + ' m';
    }

    const mcxEl = document.getElementById('male_center_x');
    const mcxnEl = document.getElementById('male_center_x_num');
    const mcxvEl = document.getElementById('male_center_x_val');
    if (mcxEl && mcxnEl) {
        mcxEl.value = state.maleHead.center_x;
        mcxnEl.value = Number(state.maleHead.center_x).toFixed(5);
        if (mcxvEl) mcxvEl.innerText = Number(state.maleHead.center_x).toFixed(5) + ' m';
    }

    const mhEl = document.getElementById('male_height');
    const mhnEl = document.getElementById('male_height_num');
    const mhvEl = document.getElementById('male_height_val');
    if (mhEl && mhnEl) {
        mhEl.value = state.maleHead.height;
        mhnEl.value = Number(state.maleHead.height).toFixed(5);
        if (mhvEl) mhvEl.innerText = Number(state.maleHead.height).toFixed(5) + ' m';
    }

    // Spine
    const srEl = document.getElementById('spine_radius');
    const srnEl = document.getElementById('spine_radius_num');
    const srvEl = document.getElementById('spine_radius_val');
    if (srEl && srnEl) {
        srEl.value = state.maleSpine.radius;
        srnEl.value = Number(state.maleSpine.radius).toFixed(5);
        if (srvEl) srvEl.innerText = Number(state.maleSpine.radius).toFixed(5) + ' m';
    }

    const shEl = document.getElementById('spine_height');
    const shnEl = document.getElementById('spine_height_num');
    const shvEl = document.getElementById('spine_height_val');
    if (shEl && shnEl) {
        shEl.value = state.maleSpine.height;
        shnEl.value = Number(state.maleSpine.height).toFixed(5);
        if (shvEl) shvEl.innerText = Number(state.maleSpine.height).toFixed(5) + ' m';
    }
}

function setRadiusQuick(gender, val) {
    state[gender + 'Head'].radius = val;
    if (state.syncGender) {
        const other = gender === 'male' ? 'female' : 'male';
        const ratio = state.originalFemaleHead.radius / (state.originalMaleHead.radius || 1);
        state[other + 'Head'].radius = gender === 'male' ? val * ratio : val / ratio;
    }
    syncInputs();
    drawMannequin();
}

function setCenterPos(gender, val) {
    state[gender + 'Head'].center_x = val;
    if (state.syncGender) {
        const other = gender === 'male' ? 'female' : 'male';
        state[other + 'Head'].center_x = val;
    }
    syncInputs();
    drawMannequin();
}

function setSpineQuick(radius, height) {
    state.maleSpine.radius = radius;
    state.maleSpine.height = height;
    state.femaleSpine.radius = radius;
    state.femaleSpine.height = height;
    state.enableMagicBullet = (radius > 0.15);
    syncInputs();
    drawMannequin();
}

function applyFormula(type) {
    if (type === 'nhe_tam') {
        // EXACT WORKING MEDIAFIRE FILE FORMULA
        state.maleHead.radius = 0.09905890;
        state.maleHead.center_x = 0.05524504;
        state.femaleHead.radius = 0.09915388;
        state.femaleHead.center_x = 0.05077528;
        state.maleSpine = { ...state.originalMaleSpine };
        state.femaleSpine = { ...state.originalFemaleSpine };
        state.enableMagicBullet = false;
        switchPartTab('head');
        showToast('Đã áp dụng Mod Nhẹ Tâm (Khớp chuẩn 100% file MediaFire)!', 'success');
    } else if (type === 'goc') {
        // RESET ALL
        state.maleHead = { ...state.originalMaleHead };
        state.femaleHead = { ...state.originalFemaleHead };
        state.maleSpine = { ...state.originalMaleSpine };
        state.femaleSpine = { ...state.originalFemaleSpine };
        state.enableMagicBullet = false;
        switchPartTab('head');
        showToast('Đã khôi phục toàn bộ thông số gốc chuẩn game!', 'info');
    } else if (type === 'cheast') {
        // CHEAST HEADSHOT (AND RESET SPINE TO PREVENT MAGIC OVERLAY)
        state.maleHead.radius = 0.09908871;
        state.maleHead.center_x = -0.01061450;
        state.femaleHead.radius = 0.09913578;
        state.femaleHead.center_x = -0.01093376;
        state.maleSpine = { ...state.originalMaleSpine };
        state.femaleSpine = { ...state.originalFemaleSpine };
        state.enableMagicBullet = false;
        switchPartTab('head');
        showToast('Đã áp dụng Ghim Headshot (Đã tắt Magic Bullet)!', 'success');
    } else if (type === 'body') {
        // BODY HEADSHOT (AND RESET SPINE TO PREVENT MAGIC OVERLAY)
        state.maleHead.radius = 0.09903787;
        state.maleHead.center_x = 0.12103459;
        state.maleHead.center_y = 0.02009277;
        state.femaleHead.radius = 0.09903276;
        state.femaleHead.center_x = 0.12074338;
        state.femaleHead.center_y = 0.01723830;
        state.maleSpine = { ...state.originalMaleSpine };
        state.femaleSpine = { ...state.originalFemaleSpine };
        state.enableMagicBullet = false;
        switchPartTab('head');
        showToast('Đã áp dụng Bắn Thân = Headshot (Đã tắt Magic Bullet)!', 'success');
    } else if (type === 'magic') {
        // MAGIC BULLET ONLY (AND RESET HEAD TO ORIGINAL)
        state.maleHead = { ...state.originalMaleHead };
        state.femaleHead = { ...state.originalFemaleHead };
        state.maleSpine.radius = 1.07034874;
        state.maleSpine.height = 1.07034874;
        state.femaleSpine.radius = 1.07034874;
        state.femaleSpine.height = 1.07034874;
        state.enableMagicBullet = true;
        switchPartTab('spine');
        showToast('Đã kích hoạt Magic Bullet (Thân to 1.07 mét)!', 'success');
    } else if (type === 'combo_cheast_magic') {
        // BOTH HEAD AND SPINE
        state.maleHead.radius = 0.09908871;
        state.maleHead.center_x = -0.01061450;
        state.femaleHead.radius = 0.09913578;
        state.femaleHead.center_x = -0.01093376;
        state.maleSpine.radius = 1.07034874;
        state.maleSpine.height = 1.07034874;
        state.femaleSpine.radius = 1.07034874;
        state.femaleSpine.height = 1.07034874;
        state.enableMagicBullet = true;
        showToast('Đã kích hoạt Combo: Headshot + Magic Bullet!', 'success');
    }

    syncInputs();
    drawMannequin();
}

/* =========================================================
   FILE UPLOAD HANDLER
========================================================= */
async function handleFileUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    showToast(`Đang nạp file: ${file.name}...`, 'info');
    try {
        const res = await fetch('/api/upload_base', {
            method: 'POST',
            body: formData
        });
        const data = await res.json();
        if (data.success) {
            state.sourceName = data.source_name;
            state.fileSize = data.file_size;
            document.getElementById('sourceNameDisplay').innerText = data.source_name;
            document.getElementById('fileSizeDisplay').innerText = data.file_size.toLocaleString() + ' B';

            const vals = data.current_values || {};
            if (vals.male_head) {
                state.originalMaleHead = { ...vals.male_head };
                state.maleHead = { ...vals.male_head };
            }
            if (vals.female_head) {
                state.originalFemaleHead = { ...vals.female_head };
                state.femaleHead = { ...vals.female_head };
            }
            if (vals.male_spine) {
                state.originalMaleSpine = { ...vals.male_spine };
                state.maleSpine = { ...vals.male_spine };
            }
            if (vals.female_spine) {
                state.originalFemaleSpine = { ...vals.female_spine };
                state.femaleSpine = { ...vals.female_spine };
            }

            syncInputs();
            drawMannequin();
            showToast(`Đã nạp file: ${file.name}`, 'success');
        } else {
            showToast('Lỗi: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi tải file: ' + e.message, 'error');
    }
}

/* =========================================================
   2D HITBOX MANNEQUIN RENDERER
========================================================= */
function drawMannequin() {
    const canvas = document.getElementById('hitboxCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const w = canvas.width;
    const h = canvas.height;

    ctx.clearRect(0, 0, w, h);

    // Background Grid
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.03)';
    ctx.lineWidth = 1;
    for (let x = 0; x < w; x += 20) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, h);
        ctx.stroke();
    }
    for (let y = 0; y < h; y += 20) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(w, y);
        ctx.stroke();
    }

    const centerX = w / 2;
    const headParam = (state.activeTab === 'female' && !state.syncGender) ? state.femaleHead : state.maleHead;
    const origHead = (state.activeTab === 'female' && !state.syncGender) ? state.originalFemaleHead : state.originalMaleHead;
    const spineParam = (state.activeTab === 'female' && !state.syncGender) ? state.femaleSpine : state.maleSpine;

    // Body reference points
    const headRefY = 80;
    const neckRefY = 120;
    const chestRefY = 170;
    const bellyRefY = 235;
    const hipsRefY = 275;

    // 1. Draw MAGIC BULLET SPHERE ONLY IF ENABLED
    if (state.enableMagicBullet && spineParam.radius > 0.15) {
        ctx.save();
        const spineCenterY = 210;
        const spinePx = Math.min(150, (spineParam.radius / 0.07029) * 16);
        
        ctx.shadowColor = '#a855f7';
        ctx.shadowBlur = 25;
        ctx.strokeStyle = '#a855f7';
        ctx.lineWidth = 2;
        ctx.setLineDash([6, 6]);

        ctx.beginPath();
        ctx.ellipse(centerX, spineCenterY, spinePx, spinePx * 1.1, 0, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(168, 85, 247, 0.12)';
        ctx.fill();
        ctx.stroke();
        
        ctx.fillStyle = '#c084fc';
        ctx.font = '10px "JetBrains Mono"';
        ctx.textAlign = 'center';
        ctx.fillText(`MAGIC BULLET: ${(spineParam.radius).toFixed(2)}m`, centerX, spineCenterY + spinePx * 1.1 + 14);
        ctx.restore();
    }

    // 2. Draw Body Wireframe Mannequin
    ctx.save();
    ctx.strokeStyle = 'rgba(148, 163, 184, 0.35)';
    ctx.lineWidth = 2;

    // Head outline
    ctx.beginPath();
    ctx.ellipse(centerX, headRefY, 26, 32, 0, 0, Math.PI * 2);
    ctx.stroke();

    // Neck
    ctx.beginPath();
    ctx.moveTo(centerX - 10, headRefY + 28);
    ctx.lineTo(centerX - 10, neckRefY);
    ctx.lineTo(centerX + 10, neckRefY);
    ctx.lineTo(centerX + 10, headRefY + 28);
    ctx.stroke();

    // Torso
    ctx.beginPath();
    ctx.moveTo(centerX - 42, neckRefY + 10);
    ctx.lineTo(centerX + 42, neckRefY + 10);
    ctx.lineTo(centerX + 34, bellyRefY);
    ctx.lineTo(centerX + 36, hipsRefY);
    ctx.lineTo(centerX - 36, hipsRefY);
    ctx.lineTo(centerX - 34, bellyRefY);
    ctx.closePath();
    ctx.stroke();

    // Arms
    ctx.beginPath();
    ctx.moveTo(centerX - 42, neckRefY + 10);
    ctx.lineTo(centerX - 68, chestRefY + 30);
    ctx.lineTo(centerX - 72, bellyRefY + 40);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(centerX + 42, neckRefY + 10);
    ctx.lineTo(centerX + 68, chestRefY + 30);
    ctx.lineTo(centerX + 72, bellyRefY + 40);
    ctx.stroke();

    // Legs
    ctx.beginPath();
    ctx.moveTo(centerX - 24, hipsRefY);
    ctx.lineTo(centerX - 28, 360);
    ctx.lineTo(centerX - 30, 420);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(centerX + 24, hipsRefY);
    ctx.lineTo(centerX + 28, 360);
    ctx.lineTo(centerX + 30, 420);
    ctx.stroke();

    ctx.restore();

    // 3. Draw ORIGINAL Hitbox Ghost (dashed outline)
    const baseOffset = -0.045245;
    const origDiff = origHead.center_x - baseOffset;
    const origCenterY = headRefY + (origDiff * 850);
    const origRadiusPx = (origHead.radius / 0.059058) * 28;
    const origHeightPx = Math.max(origRadiusPx * 2, (origHead.height / 0.12749) * 55);

    ctx.save();
    ctx.strokeStyle = 'rgba(0, 242, 254, 0.35)';
    ctx.lineWidth = 1.5;
    ctx.setLineDash([4, 4]);
    const origHalfH = Math.max(0, origHeightPx / 2 - origRadiusPx);
    ctx.beginPath();
    ctx.arc(centerX, origCenterY - origHalfH, origRadiusPx, Math.PI, 0, false);
    ctx.lineTo(centerX + origRadiusPx, origCenterY + origHalfH);
    ctx.arc(centerX, origCenterY + origHalfH, origRadiusPx, 0, Math.PI, false);
    ctx.lineTo(centerX - origRadiusPx, origCenterY - origHalfH);
    ctx.closePath();
    ctx.stroke();
    ctx.restore();

    // 4. Draw MODIFIED Hitbox Capsule (bone_Head)
    const currentDiff = headParam.center_x - baseOffset;
    const currentCenterY = headRefY + (currentDiff * 850);
    const currentRadiusPx = (headParam.radius / 0.059058) * 28;
    const currentHeightPx = Math.max(currentRadiusPx * 2, (headParam.height / 0.12749) * 55);

    let hitColor = '#00f2fe';
    let zoneName = '🎯 Vùng trúng: ĐẦU (HEAD)';
    let zoneTag = 'Đầu (Head)';

    if (headParam.center_x > 0.06) {
        hitColor = '#ff0080';
        zoneName = '💥 Vùng trúng: GIỮA THÂN / BỤNG (BODY)';
        zoneTag = 'Thân (Body)';
    } else if (headParam.center_x > -0.02) {
        hitColor = '#00ff87';
        zoneName = '🎯 Vùng trúng: CỔ / NGỰC TRÊN (CHEST)';
        zoneTag = 'Ngực (Chest)';
    }

    ctx.save();
    ctx.shadowColor = hitColor;
    ctx.shadowBlur = 18;

    const currentHalfH = Math.max(0, currentHeightPx / 2 - currentRadiusPx);
    ctx.beginPath();
    ctx.arc(centerX, currentCenterY - currentHalfH, currentRadiusPx, Math.PI, 0, false);
    ctx.lineTo(centerX + currentRadiusPx, currentCenterY + currentHalfH);
    ctx.arc(centerX, currentCenterY + currentHalfH, currentRadiusPx, 0, Math.PI, false);
    ctx.lineTo(centerX - currentRadiusPx, currentCenterY - currentHalfH);
    ctx.closePath();

    ctx.fillStyle = hexToRgba(hitColor, 0.25);
    ctx.fill();

    ctx.lineWidth = 2.5;
    ctx.strokeStyle = hitColor;
    ctx.stroke();

    // Crosshair
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(centerX - 8, currentCenterY);
    ctx.lineTo(centerX + 8, currentCenterY);
    ctx.moveTo(centerX, currentCenterY - 8);
    ctx.lineTo(centerX, currentCenterY + 8);
    ctx.stroke();

    ctx.restore();

    // Update overlay texts
    document.getElementById('zoneIndicator').innerText = zoneName;
    document.getElementById('zoneIndicator').style.borderColor = hitColor;
    document.getElementById('zoneIndicator').style.color = hitColor;

    document.getElementById('canvasRadius').innerText = (headParam.radius * 100).toFixed(1) + ' cm';
    document.getElementById('canvasSpine').innerText = state.enableMagicBullet ? (spineParam.radius * 100).toFixed(1) + ' cm' : 'Gốc (0.07m)';
    document.getElementById('canvasZone').innerText = zoneTag;
}

function hexToRgba(hex, alpha) {
    if (hex === '#00f2fe') return `rgba(0, 242, 254, ${alpha})`;
    if (hex === '#00ff87') return `rgba(0, 255, 135, ${alpha})`;
    if (hex === '#ff0080') return `rgba(255, 0, 128, ${alpha})`;
    return `rgba(0, 242, 254, ${alpha})`;
}

/* =========================================================
   BUILD & EXPORT ACTIONS (HITBOX)
========================================================= */
async function triggerBuild() {
    const btn = document.getElementById('btnBuild');
    btn.disabled = true;
    btn.innerHTML = `<span>Đang biên dịch từ File Gốc...</span>`;

    try {
        const payload = {
            params: {
                male_head: { ...state.maleHead },
                female_head: { ...state.femaleHead }
            }
        };

        // EXPLICIT CHECK: ONLY send spine if Magic Bullet is enabled!
        if (state.enableMagicBullet) {
            payload.params.male_spine = { ...state.maleSpine };
            payload.params.female_spine = { ...state.femaleSpine };
        } else {
            // Explicitly set to original values to guarantee 0% magic
            payload.params.male_spine = { ...state.originalMaleSpine };
            payload.params.female_spine = { ...state.originalFemaleSpine };
        }

        const authHeaders = getAuthHeaders();
        const res = await fetch('/api/build', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', ...authHeaders },
            body: JSON.stringify({ ...payload, ...authHeaders })
        });
        if (res.status === 401 || res.status === 403) {
            const errData = await res.json().catch(() => ({}));
            openAuthModal();
            showToast(errData.error || 'Yêu cầu đăng nhập và có API Key hợp lệ để build file!', 'error');
            return;
        }

        const data = await res.json();
        if (data.success) {
            state.currentBuildId = data.build_id;

            document.getElementById('buildResult').style.display = 'block';
            document.getElementById('buildInfo').innerText = 
                `Đã áp dụng ${data.changes_count} thay đổi | Dung lượng: ${data.size.toLocaleString()} bytes | SHA: ${data.sha256.substring(0, 12)}...`;

            let logText = `[BUILD XONG] Nguồn: ${state.sourceName} -> Build ID: ${data.build_id}\n`;
            logText += `SHA256: ${data.sha256}\n`;
            logText += `Dung lượng: ${data.size} bytes (Khớp chuẩn 100%)\n\n`;
            logText += `THAY ĐỔI ÁP DỤNG TRỰC TIẾP:\n`;
            data.changes.forEach(c => {
                logText += ` • [${c.offset}] ${c.part} -> ${c.field}: ${c.old_value} => ${c.new_value} (diff: ${c.diff > 0 ? '+' : ''}${c.diff})\n`;
            });

            document.getElementById('logContent').innerText = logText;
            showToast('Biên dịch file cache từ gốc thành công!', 'success');
        } else {
            showToast('Lỗi build: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi mạng: ' + e.message, 'error');
    } finally {
        btn.disabled = false;
        btn.innerHTML = `
            <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2.5" fill="none">
                <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
            </svg>
            <span>BUILD FILE CACHE TỪ GỐC</span>
        `;
    }
}

function downloadCurrentBuild() {
    if (!state.currentBuildId) {
        showToast('Chưa có bản build nào để tải!', 'error');
        return;
    }
    window.location.href = `/api/download/${state.currentBuildId}`;
}

async function overwriteGocFile() {
    if (!state.currentBuildId) {
        showToast('Vui lòng ấn BUILD trước khi ghi đè!', 'error');
        return;
    }

    if (!confirm('Bạn có chắc muốn ghi đè trực tiếp file trong thư mục "cache gốc"? (Hệ thống sẽ tự động tạo file sao lưu .bak)')) {
        return;
    }

    try {
        const res = await fetch('/api/overwrite_goc', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ build_id: state.currentBuildId })
        });
        const data = await res.json();
        if (data.success) {
            showToast('Đã ghi đè thành công vào cache gốc! (Đã sao lưu .bak)', 'success');
        } else {
            showToast('Lỗi ghi đè: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi kết nối: ' + e.message, 'error');
    }
}

async function exportToFolder() {
    if (!state.currentBuildId) {
        showToast('Vui lòng ấn BUILD trước khi xuất thư mục!', 'error');
        return;
    }

    const folderName = document.getElementById('targetFolderName').value.trim() || 'cache mod_output';
    try {
        const res = await fetch('/api/export_folder', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                build_id: state.currentBuildId,
                folder_name: folderName
            })
        });

        const data = await res.json();
        if (data.success) {
            showToast(`Đã xuất file vào thư mục: [${data.folder}]`, 'success');
        } else {
            showToast('Lỗi xuất thư mục: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi kết nối: ' + e.message, 'error');
    }
}

/* =========================================================
   DÂY VÀNG (DV) SHADER STUDIO ACTIONS & COLOR CUSTOMIZATION
========================================================= */
function selectDVVersion(ver) {
    state.dvVersion = ver;
    document.getElementById('cardVerFFT').classList.toggle('active', ver === 'fft');
    document.getElementById('cardVerFFM').classList.toggle('active', ver === 'ffm');

    const overlayVerEl = document.getElementById('dvOverlayVer');
    if (overlayVerEl) overlayVerEl.innerText = ver === 'fft' ? 'FFT (Thường)' : 'FFM (MAX)';

    const btnTextEl = document.getElementById('btnDvModText');
    if (btnTextEl) btnTextEl.innerText = `TẠO & TẢI FILE DÂY VÀNG (${ver.toUpperCase()} 13MB)`;

    drawDVMannequin();
    showToast(`Đã chọn: ${ver.toUpperCase()}`, 'info');
}

function setDVOutlineColor(hex, r, g, b) {
    state.dvOutlineHex = hex;
    state.dvOutlineColor = [r, g, b, 1.0];

    const indEl = document.getElementById('dvOutlineIndicator');
    const hexEl = document.getElementById('dvOutlineHex');
    const pickEl = document.getElementById('dvOutlinePicker');
    if (indEl) indEl.style.background = hex;
    if (hexEl) hexEl.innerText = hex.toUpperCase();
    if (pickEl) pickEl.value = hex;

    const guideGun = document.getElementById('guideBoxGun');
    if (guideGun) {
        guideGun.style.background = hex;
        guideGun.style.boxShadow = `0 0 12px ${hex}`;
    }
    const ovColor = document.getElementById('dvOverlayColor');
    if (ovColor) ovColor.innerText = hex.toUpperCase();

    // Update active color chip
    document.querySelectorAll('.control-group:nth-of-type(3) .color-chip').forEach(chip => {
        const circle = chip.querySelector('.chip-circle');
        if (circle) {
            chip.classList.toggle('active', circle.style.background.toLowerCase() === hex.toLowerCase());
        }
    });

    drawDVGun();
}

function onDVOutlinePickerChange(hex) {
    const rgb = hexToRgb(hex);
    setDVOutlineColor(hex, rgb.r, rgb.g, rgb.b);
}

function setDVWidthQuick(val) {
    onDVWidthChange(val);
}

function onDVWidthChange(val) {
    const num = parseFloat(val) || 2.0;
    state.dvOutlineWidth = num;

    const rangeEl = document.getElementById('dvWidthRange');
    const numEl = document.getElementById('dvWidthNum');
    const valEl = document.getElementById('dvWidthVal');
    if (rangeEl) rangeEl.value = num;
    if (numEl) numEl.value = num;
    if (valEl) valEl.innerText = num.toFixed(1) + ' px';

    drawDVGun();
}

function setDVXRayColor(hex, r, g, b) {
    state.dvXRayHex = hex;
    state.dvXRayColor = [r, g, b, 1.0];

    const indEl = document.getElementById('dvXRayIndicator');
    const hexEl = document.getElementById('dvXRayHex');
    const pickEl = document.getElementById('dvXRayPicker');
    if (indEl) indEl.style.background = hex;
    if (hexEl) hexEl.innerText = hex.toUpperCase();
    if (pickEl) pickEl.value = hex;

    const guideBackdrop = document.getElementById('guideBoxBackdrop');
    if (guideBackdrop) {
        guideBackdrop.style.background = hex;
        guideBackdrop.style.boxShadow = `0 0 12px ${hex}`;
    }
    const ovXRay = document.getElementById('dvOverlayXRay');
    if (ovXRay) ovXRay.innerText = hex.toUpperCase();

    drawDVGun();
}

function onDVXRayPickerChange(hex) {
    const rgb = hexToRgb(hex);
    setDVXRayColor(hex, rgb.r, rgb.g, rgb.b);
}

function hexToRgb(hex) {
    let c = hex.replace('#', '');
    if (c.length === 3) {
        c = c.split('').map(x => x + x).join('');
    }
    const num = parseInt(c, 16);
    return {
        r: (num >> 16) & 255,
        g: (num >> 8) & 255,
        b: num & 255
    };
}

function applyDualColor(gunHex, bgHex, name) {
    const rgbGun = hexToRgb(gunHex);
    state.dvOutlineHex = gunHex;
    state.dvOutlineColor = [rgbGun.r, rgbGun.g, rgbGun.b, 1.0];

    const rgbBg = hexToRgb(bgHex);
    state.dvXRayHex = bgHex;
    state.dvXRayColor = [rgbBg.r, rgbBg.g, rgbBg.b, 1.0];

    const indOut = document.getElementById('dvOutlineIndicator');
    const hexOut = document.getElementById('dvOutlineHex');
    const pickOut = document.getElementById('dvOutlinePicker');
    const guideGun = document.getElementById('guideBoxGun');
    const ovColor = document.getElementById('dvOverlayColor');
    if (indOut) indOut.style.background = gunHex;
    if (hexOut) hexOut.innerText = gunHex.toUpperCase();
    if (pickOut) pickOut.value = gunHex;
    if (guideGun) {
        guideGun.style.background = gunHex;
        guideGun.style.boxShadow = `none`;
    }
    if (ovColor) ovColor.innerText = gunHex.toUpperCase();

    const indXRay = document.getElementById('dvXRayIndicator');
    const hexXRay = document.getElementById('dvXRayHex');
    const pickXRay = document.getElementById('dvXRayPicker');
    const guideBg = document.getElementById('guideBoxBackdrop');
    const ovXRay = document.getElementById('dvOverlayXRay');
    if (indXRay) indXRay.style.background = bgHex;
    if (hexXRay) hexXRay.innerText = bgHex.toUpperCase();
    if (pickXRay) pickXRay.value = bgHex;
    if (guideBg) {
        guideBg.style.background = bgHex;
        guideBg.style.boxShadow = `none`;
    }
    if (ovXRay) ovXRay.innerText = bgHex.toUpperCase();

    // Update active preset chip
    document.querySelectorAll('.combo-colors-grid .combo-chip').forEach(chip => {
        chip.classList.toggle('active', chip.innerText.includes(name.split(' ')[0]));
    });

    drawDVGun();
    showToast(`Đã chọn phối màu: ${name}!`, 'success');
}

// VISUAL DISTINCTION CONTROLS
state.showAnnotations = true;
state.contrastOutline = true;
state.activeBoxHighlight = null;

function toggleAnnotations() {
    state.showAnnotations = !state.showAnnotations;
    const btn = document.getElementById('btnToggleAnnot');
    if (btn) btn.classList.toggle('active', state.showAnnotations);
    drawDVGun();
    showToast(state.showAnnotations ? 'Đã BẬT chú thích mũi tên phân biệt!' : 'Đã TẮT chú thích mũi tên', 'info');
}

function toggleContour() {
    state.contrastOutline = !state.contrastOutline;
    const btn = document.getElementById('btnToggleContour');
    if (btn) btn.classList.toggle('active', state.contrastOutline);
    drawDVGun();
    showToast(state.contrastOutline ? 'Đã BẬT viền đen tách lớp súng & nền!' : 'Đã TẮT viền tách lớp', 'info');
}

function highlightCardBox(type) {
    state.activeBoxHighlight = type;
    const boxGun = document.getElementById('cardBoxGun');
    const boxBg = document.getElementById('cardBoxBackdrop');
    if (boxGun) boxGun.classList.toggle('focused', type === 'gun');
    if (boxBg) boxBg.classList.toggle('focused', type === 'backdrop');

    setTimeout(() => {
        if (boxGun) boxGun.classList.remove('focused');
        if (boxBg) boxBg.classList.remove('focused');
    }, 2000);
}

/* =========================================================
   2D SOLID 2-COLOR IN-GAME ARMORY M4A1 (100% MATCH PHOTO)
========================================================= */
function drawDVGun() {
    const canvas = document.getElementById('dvCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const w = canvas.width;
    const h = canvas.height;

    ctx.clearRect(0, 0, w, h);

    const gunColor = state.dvOutlineHex || '#ffff00';
    const backdropColor = state.dvXRayHex || '#ffffff';

    // 1. In-Game Armory Hangar Background (Sảnh Chờ Tối)
    const bgGrad = ctx.createLinearGradient(0, 0, 0, h);
    bgGrad.addColorStop(0, '#090b14');
    bgGrad.addColorStop(0.5, '#121424');
    bgGrad.addColorStop(0.85, '#16192d');
    bgGrad.addColorStop(1, '#07080f');
    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, w, h);

    // Soft hangar spotlights
    const spotGrad = ctx.createRadialGradient(w / 2, 80, 20, w / 2, 80, 160);
    spotGrad.addColorStop(0, 'rgba(100, 90, 255, 0.12)');
    spotGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
    ctx.fillStyle = spotGrad;
    ctx.fillRect(0, 0, w, 200);

    // 2. Metal Pedestal Floor Platform (Bục Trưng Bày Súng)
    ctx.save();
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(40, 310);
    ctx.lineTo(w - 40, 310);
    ctx.lineTo(w - 15, 360);
    ctx.lineTo(15, 360);
    ctx.closePath();
    ctx.fillStyle = 'rgba(18, 20, 36, 0.7)';
    ctx.fill();
    ctx.stroke();

    // Floor inner ring
    ctx.strokeStyle = 'rgba(168, 85, 247, 0.25)';
    ctx.beginPath();
    ctx.ellipse(w / 2, 325, 110, 20, 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();

    // 3. MÀU 2: 4 MẢNG NỀN POSTER STENCIL RÁCH VIỀN (CHÍNH XÁC NHƯ TRONG ẢNH)
    ctx.save();
    ctx.fillStyle = backdropColor;

    // We render 4 distinct vertical poster panels with jagged cuts between them as in the user's photo
    // PANEL 1: Leftmost block (behind stock)
    ctx.beginPath();
    ctx.moveTo(52, 94);
    ctx.lineTo(92, 92);
    ctx.lineTo(90, 235);
    ctx.lineTo(54, 230);
    ctx.closePath();
    ctx.fill();

    // PANEL 2: Center-left block (behind carrying handle & receiver) with top chevron cut
    ctx.beginPath();
    ctx.moveTo(96, 92);
    ctx.lineTo(135, 90);
    ctx.lineTo(142, 108); // Chevron V-cut top right
    ctx.lineTo(158, 86);
    ctx.lineTo(156, 260);
    ctx.lineTo(94, 255);
    ctx.closePath();
    ctx.fill();

    // PANEL 3: Center-right block (behind handguard)
    ctx.beginPath();
    ctx.moveTo(162, 88);
    ctx.lineTo(208, 92);
    ctx.lineTo(206, 240);
    ctx.lineTo(160, 244);
    ctx.closePath();
    ctx.fill();

    // PANEL 4: Far-right block (behind front sight & barrel)
    ctx.beginPath();
    ctx.moveTo(212, 96);
    ctx.lineTo(262, 98);
    ctx.lineTo(260, 238);
    ctx.lineTo(210, 240);
    ctx.closePath();
    ctx.fill();

    // Splatters, needles, and vertical slash accents around the poster (như trong ảnh chụp)
    ctx.strokeStyle = backdropColor;
    ctx.lineWidth = 1.8;
    const splatters = [
        // Top splatters
        [70, 78, 74, 92],
        [115, 68, 118, 88],
        [138, 74, 142, 84],
        [180, 70, 184, 88],
        [230, 80, 232, 94],
        // Bottom drip needles
        [68, 232, 70, 252],
        [82, 230, 84, 262],
        [135, 258, 137, 282],
        [175, 242, 176, 265],
        [220, 240, 222, 258],
        [250, 236, 252, 252],
        // Side slashes
        [44, 135, 52, 138],
        [262, 120, 272, 122],
        [260, 160, 270, 162]
    ];
    splatters.forEach(([x1, y1, x2, y2]) => {
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
    });
    ctx.restore();

    // 4. MÀU 1: THÂN SÚNG M4A1 & DẢI SỌC NGANG
    ctx.save();

    const gx = 45;
    const gy = 155;

    // Gun Path Function
    function traceM4A1Path() {
        ctx.beginPath();
        // Buttpad
        ctx.moveTo(gx, gy - 8);
        ctx.lineTo(gx + 12, gy - 8);
        ctx.lineTo(gx + 16, gy + 12);
        // Lower stock strut
        ctx.lineTo(gx + 42, gy + 18);
        ctx.lineTo(gx + 46, gy + 12);
        // Buffer tube top
        ctx.lineTo(gx + 78, gy + 12);
        // Upper receiver
        ctx.lineTo(gx + 80, gy + 2);
        // M4A1 Carrying Handle
        ctx.lineTo(gx + 88, gy - 16);
        ctx.lineTo(gx + 128, gy - 16);
        ctx.lineTo(gx + 132, gy - 6);
        ctx.lineTo(gx + 134, gy + 4);
        // Top rail & Delta Ring
        ctx.lineTo(gx + 140, gy + 4);
        // Handguard
        ctx.lineTo(gx + 142, gy - 2);
        ctx.lineTo(gx + 195, gy - 2);
        // M4A1 Front Sight Post (A-Frame Triangular sight)
        ctx.lineTo(gx + 198, gy - 18);
        ctx.lineTo(gx + 204, gy - 18);
        ctx.lineTo(gx + 208, gy + 6);
        // Barrel
        ctx.lineTo(gx + 245, gy + 6);
        // Flash Hider
        ctx.lineTo(gx + 245, gy + 3);
        ctx.lineTo(gx + 258, gy + 3);
        ctx.lineTo(gx + 258, gy + 14);
        ctx.lineTo(gx + 245, gy + 14);
        // Underbarrel
        ctx.lineTo(gx + 208, gy + 12);
        ctx.lineTo(gx + 195, gy + 14);
        // Handguard bottom
        ctx.lineTo(gx + 142, gy + 14);
        ctx.lineTo(gx + 140, gy + 12);
        // STANAG Curved Magazine
        ctx.lineTo(gx + 132, gy + 16);
        ctx.lineTo(gx + 138, gy + 58);
        ctx.lineTo(gx + 116, gy + 62);
        ctx.lineTo(gx + 112, gy + 20);
        // Trigger guard
        ctx.lineTo(gx + 98, gy + 20);
        ctx.lineTo(gx + 98, gy + 32);
        ctx.lineTo(gx + 86, gy + 32);
        ctx.lineTo(gx + 86, gy + 22);
        // Pistol Grip
        ctx.lineTo(gx + 82, gy + 22);
        ctx.lineTo(gx + 66, gy + 62);
        ctx.lineTo(gx + 48, gy + 56);
        ctx.lineTo(gx + 62, gy + 18);
        // Stock tube to buttpad
        ctx.lineTo(gx + 18, gy + 18);
        ctx.lineTo(gx + 12, gy + 34);
        ctx.lineTo(gx, gy + 30);
        ctx.closePath();
    }

    // Horizontal Beam Path
    function traceHorizontalBeam() {
        ctx.beginPath();
        ctx.rect(0, gy + 7, w, 6);
        ctx.closePath();
    }

    // CONTRAST CONTOUR OUTLINE (Tách viền đen giúp súng nổi bần bật trên nền trắng)
    if (state.contrastOutline) {
        ctx.save();
        ctx.strokeStyle = '#05070f';
        ctx.lineWidth = 3.5;
        traceHorizontalBeam();
        ctx.stroke();

        traceM4A1Path();
        ctx.stroke();
        ctx.restore();
    }

    // Fill Gun Color
    ctx.fillStyle = gunColor;
    traceHorizontalBeam();
    ctx.fill();

    traceM4A1Path();
    ctx.fill();

    // Carrying handle cutout
    ctx.save();
    ctx.fillStyle = backdropColor;
    ctx.beginPath();
    ctx.ellipse(gx + 108, gy - 9, 14, 4, 0, 0, Math.PI * 2);
    ctx.fill();
    if (state.contrastOutline) {
        ctx.strokeStyle = '#05070f';
        ctx.lineWidth = 1.5;
        ctx.stroke();
    }
    ctx.restore();

    ctx.restore();

    // 5. ANNOTATION CALLOUT ARROWS & LABELS (CHÚ THÍCH PHÂN BIỆT RÕ RÀNG)
    if (state.showAnnotations) {
        ctx.save();

        // Callout 1: VỊ TRÍ 2 - MẢNG NỀN POSTER (TRẮNG)
        const callout2X = 85;
        const callout2Y = 40;
        const target2X = 110;
        const target2Y = 95;

        // Line
        ctx.strokeStyle = '#38bdf8';
        ctx.lineWidth = 1.5;
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.moveTo(callout2X + 25, callout2Y + 12);
        ctx.lineTo(target2X, target2Y);
        ctx.stroke();
        ctx.setLineDash([]);

        // Target dot
        ctx.fillStyle = '#38bdf8';
        ctx.beginPath();
        ctx.arc(target2X, target2Y, 3.5, 0, Math.PI * 2);
        ctx.fill();

        // Pill Badge 2
        ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
        ctx.strokeStyle = '#38bdf8';
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        ctx.roundRect(callout2X - 60, callout2Y - 10, 150, 22, 11);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 9.5px system-ui, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('⚪ VỊ TRÍ 2: MẢNG NỀN POSTER', callout2X + 15, callout2Y + 1);

        // Callout 2: VỊ TRÍ 1 - THÂN SÚNG M4A1 (VÀNG)
        const callout1X = 230;
        const callout1Y = 285;
        const target1X = 180;
        const target1Y = 175;

        // Line
        ctx.strokeStyle = '#ffff00';
        ctx.lineWidth = 1.5;
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.moveTo(callout1X - 20, callout1Y - 10);
        ctx.lineTo(target1X, target1Y);
        ctx.stroke();
        ctx.setLineDash([]);

        // Target dot
        ctx.fillStyle = '#ffff00';
        ctx.beginPath();
        ctx.arc(target1X, target1Y, 3.5, 0, Math.PI * 2);
        ctx.fill();

        // Pill Badge 1
        ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
        ctx.strokeStyle = '#ffff00';
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        ctx.roundRect(callout1X - 65, callout1Y - 10, 140, 22, 11);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = '#ffff00';
        ctx.font = 'bold 9.5px system-ui, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('🟡 VỊ TRÍ 1: SÚNG M4A1', callout1X + 5, callout1Y + 1);

        ctx.restore();
    }

    // 6. IN-GAME UI BADGES
    // "ĐÃ TRANG BỊ" Button
    ctx.save();
    const btnW = 90;
    const btnH = 24;
    const btnX = (w - btnW) / 2;
    const btnY = 345;
    ctx.fillStyle = 'rgba(234, 179, 8, 0.2)';
    ctx.strokeStyle = '#eab308';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.roundRect(btnX, btnY, btnW, btnH, 4);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = '#eab308';
    ctx.font = 'bold 10px system-ui, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('ĐÃ TRANG BỊ', w / 2, btnY + btnH / 2);
    ctx.restore();

    // Update overlay texts
    const ovColor = document.getElementById('dvOverlayColor');
    const ovXRay = document.getElementById('dvOverlayXRay');
    const dot = document.getElementById('gunStatusDot');
    if (ovColor) ovColor.innerText = gunColor.toUpperCase();
    if (ovXRay) ovXRay.innerText = backdropColor.toUpperCase();
    if (dot) {
        dot.style.background = gunColor;
    }
}

// SETUP INTERACTIVE CANVAS CLICK
function setupCanvasInteractions() {
    const canvas = document.getElementById('dvCanvas');
    if (!canvas) return;

    canvas.addEventListener('click', (e) => {
        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        // Gun is centered around y: 140 - 220
        if (y >= 135 && y <= 225) {
            highlightCardBox('gun');
            const picker = document.getElementById('dvOutlinePicker');
            if (picker) picker.click();
            showToast('🟡 Đang chọn VỊ TRÍ 1: Thân Súng M4A1!', 'info');
        } else if (y >= 80 && y <= 270 && x >= 45 && x <= 275) {
            highlightCardBox('backdrop');
            const picker = document.getElementById('dvXRayPicker');
            if (picker) picker.click();
            showToast('⚪ Đang chọn VỊ TRÍ 2: 4 Mảng Nền Poster!', 'info');
        }
    });
}

// Initialize interactions on page load
setTimeout(setupCanvasInteractions, 200);

// Alias for backwards compatibility
const drawDVMannequin = drawDVGun;

/* =========================================================
   DV BUILD & DOWNLOAD / EXPORT
========================================================= */
async function buildAndDownloadDV(mode) {
    const btn = document.getElementById('btnBuildDV');
    if (btn) btn.disabled = true;

    try {
        const payload = {
            version: state.dvVersion,
            mode: mode,
            options: {
                outline_color: state.dvOutlineColor,
                xray_color: state.dvXRayColor,
                outline_width: state.dvOutlineWidth
            }
        };

        const authHeaders = getAuthHeaders();
        const res = await fetch('/api/dv_build', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', ...authHeaders },
            body: JSON.stringify({ ...payload, ...authHeaders })
        });
        if (res.status === 401 || res.status === 403) {
            const errData = await res.json().catch(() => ({}));
            openAuthModal();
            showToast(errData.error || 'Yêu cầu đăng nhập và có API Key hợp lệ để build shader!', 'error');
            return;
        }

        const data = await res.json();
        if (data.success) {
            state.currentDvBuildId = data.build_id;

            const logBox = document.getElementById('dvLogBox');
            const logContent = document.getElementById('dvLogContent');
            if (logBox && logContent) {
                logBox.style.display = 'block';
                let logText = `[BUILD SHADER XONG] Bản: ${data.version.toUpperCase()} -> ${data.filename}\n`;
                logText += `Dung lượng: ${data.size.toLocaleString()} bytes | SHA256: ${data.sha256.substring(0, 16)}...\n`;
                logText += `CHỈ SỐ ĐÃ MOD VÀO BINARY:\n`;
                if (data.changes && data.changes.length > 0) {
                    data.changes.forEach(c => {
                        logText += ` • ${c}\n`;
                    });
                } else {
                    logText += ` • File Shader Gốc (Chưa chỉnh sửa)\n`;
                }
                logContent.innerText = logText;
            }

            window.location.href = `/api/dv_download/${data.build_id}`;
            showToast(`Đã xuất và tải file [${data.filename}] thành công!`, 'success');
        } else {
            showToast('Lỗi xuất Dây Vàng: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi mạng: ' + e.message, 'error');
    } finally {
        if (btn) btn.disabled = false;
    }
}

async function exportDVFolder() {
    const folderName = document.getElementById('targetDvFolder').value.trim() || 'dv_mod_output';
    try {
        const resBuild = await fetch('/api/dv_build', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                version: state.dvVersion,
                mode: 'mod',
                options: {
                    outline_color: state.dvOutlineColor,
                    xray_color: state.dvXRayColor,
                    outline_width: state.dvOutlineWidth
                }
            })
        });
        const dataBuild = await resBuild.json();
        if (!dataBuild.success) {
            showToast('Lỗi: ' + dataBuild.error, 'error');
            return;
        }

        const res = await fetch('/api/dv_export', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                build_id: dataBuild.build_id,
                folder_name: folderName
            })
        });
        const data = await res.json();
        if (data.success) {
            showToast(`Đã xuất file [${data.filename}] vào thư mục [${data.folder}]`, 'success');
        } else {
            showToast('Lỗi xuất: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Lỗi mạng: ' + e.message, 'error');
    }
}

function showToast(msg, type = 'info') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.innerText = msg;
    toast.className = `toast show ${type}`;
    setTimeout(() => {
        toast.className = 'toast';
    }, 3500);
}



/* =========================================================
   HARDWARE ID (HWID) & AUTH HEADERS
========================================================= */
function getOrGenerateHWID() {
    let hwid = localStorage.getItem('regmod_hwid');
    if (!hwid) {
        hwid = 'WEB-' + ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
            (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
        ).toUpperCase();
        localStorage.setItem('regmod_hwid', hwid);
    }
    return hwid;
}

function getAuthHeaders() {
    return {
        'X-API-Key': localStorage.getItem('regmod_api_key') || '',
        'X-Device-HWID': getOrGenerateHWID()
    };
}

/* =========================================================
   CACHE FILE UPLOAD HANDLER
========================================================= */
async function handleFileUpload(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) return;

    showToast('Đang tải lên và phân tích file cache: ' + file.name, 'info');

    try {
        const formData = new FormData();
        formData.append('file', file);

        const res = await fetch('/api/upload_base', {
            method: 'POST',
            body: formData
        });

        const data = await res.json();
        if (data.success) {
            state.sourceName = data.source_name || file.name;
            state.fileSize = data.file_size || file.size;

            const snEl = document.getElementById('sourceNameDisplay');
            const fsEl = document.getElementById('fileSizeDisplay');
            if (snEl) snEl.innerText = state.sourceName;
            if (fsEl) fsEl.innerText = state.fileSize.toLocaleString() + ' B';

            const vals = data.current_values || {};
            if (vals.male_head) state.maleHead = { ...vals.male_head };
            if (vals.female_head) state.femaleHead = { ...vals.female_head };
            if (vals.male_spine) state.maleSpine = { ...vals.male_spine };
            if (vals.female_spine) state.femaleSpine = { ...vals.female_spine };

            syncInputs();
            drawMannequin();
            showToast(`Đã nạp file '${file.name}' (${state.fileSize} B) thành công!`, 'success');
        } else {
            showToast('Lỗi nạp file: ' + (data.error || 'Thất bại'), 'error');
        }
    } catch (err) {
        showToast('Lỗi mạng khi tải file: ' + err.message, 'error');
    }
}

/* =========================================================
   THEME SWITCHER (DARK / LIGHT / MONOCHROME)
========================================================= */
const THEMES = ['dark', 'light', 'mono'];
let currentThemeIndex = 0;

function initTheme() {
    const saved = localStorage.getItem('regmod_theme') || 'dark';
    currentThemeIndex = THEMES.indexOf(saved);
    if (currentThemeIndex === -1) currentThemeIndex = 0;
    applyTheme(THEMES[currentThemeIndex]);
}

function cycleTheme() {
    currentThemeIndex = (currentThemeIndex + 1) % THEMES.length;
    applyTheme(THEMES[currentThemeIndex]);
}

function applyTheme(theme) {
    localStorage.setItem('regmod_theme', theme);
    document.body.classList.remove('theme-light', 'theme-mono');
    
    const iconEl = document.getElementById('themeIcon');
    const textEl = document.getElementById('themeText');
    
    if (theme === 'light') {
        document.body.classList.add('theme-light');
        if (iconEl) iconEl.innerText = '☀️';
        if (textEl) textEl.innerText = 'Sáng';
    } else if (theme === 'mono') {
        document.body.classList.add('theme-mono');
        if (iconEl) iconEl.innerText = '⚪';
        if (textEl) textEl.innerText = 'OLED';
    } else {
        if (iconEl) iconEl.innerText = '🌑';
        if (textEl) textEl.innerText = 'Tối';
    }
}

/* =========================================================
   LANGUAGE SWITCHER (VN / ENG)
========================================================= */
let currentLang = localStorage.getItem('regmod_lang') || 'vi';

const DICT = {
    vi: {
        subtitle: 'Hệ Thống Tùy Biến Free Fire Chuyên Nghiệp',
        btnDV: 'MOD MÀU SÚNG',
        btnHitbox: 'MOD HITBOX & ĐẠN',
        btnGuide: 'HƯỚNG DẪN CÀI',
        buildCache: 'BUILD FILE CACHE TỪ GỐC',
        buildGun: 'TẢI FILE SÚNG MOD VỀ MÁY (13MB)'
    },
    en: {
        subtitle: 'Professional Free Fire Modding Suite',
        btnDV: 'GUN SHADERS',
        btnHitbox: 'HITBOX & BULLET',
        btnGuide: 'USER GUIDE',
        buildCache: 'GENERATE CACHE MOD',
        buildGun: 'GENERATE SHADER MOD'
    }
};

function toggleLanguage() {
    currentLang = currentLang === 'vi' ? 'en' : 'vi';
    localStorage.setItem('regmod_lang', currentLang);
    applyLanguage();
}

function applyLanguage() {
    const langText = document.getElementById('langText');
    if (langText) langText.innerText = currentLang.toUpperCase();
    
    const d = DICT[currentLang] || DICT.vi;
    const sub = document.getElementById('locSubtitle');
    if (sub) sub.innerText = d.subtitle;
    
    const bDV = document.getElementById('btnModDV');
    if (bDV) bDV.innerText = d.btnDV;
    
    const bHB = document.getElementById('btnModHitbox');
    if (bHB) bHB.innerText = d.btnHitbox;
    
    const bGD = document.getElementById('btnModGuide');
    if (bGD) bGD.innerText = d.btnGuide;
}

/* =========================================================
   AUTH MODAL & SESSION CONTROLLER
========================================================= */
let authMode = 'login'; // 'login' or 'register'

function initAuthUI() {
    const user = localStorage.getItem('regmod_username');
    const key = localStorage.getItem('regmod_api_key');
    const btn = document.getElementById('btnAuthHeader');
    const txt = document.getElementById('authHeaderText');
    
    const hwidDisplay = document.getElementById('displayHWID');
    if (hwidDisplay) hwidDisplay.innerText = getOrGenerateHWID();
    
    if (user && key) {
        if (btn) btn.classList.add('logged-in');
        if (txt) txt.innerText = user;
    } else {
        if (btn) btn.classList.remove('logged-in');
        if (txt) txt.innerText = 'Đăng Nhập';
    }
}

function openAuthModal() {
    const m = document.getElementById('authModal');
    if (m) m.style.display = 'flex';
    const hwidDisplay = document.getElementById('displayHWID');
    if (hwidDisplay) hwidDisplay.innerText = getOrGenerateHWID();
}

function closeAuthModal() {
    const m = document.getElementById('authModal');
    if (m) m.style.display = 'none';
}

function switchAuthTab(mode) {
    authMode = mode;
    const tabL = document.getElementById('tabAuthLogin');
    const tabR = document.getElementById('tabAuthRegister');
    const btn = document.getElementById('btnAuthSubmit');
    
    if (mode === 'register') {
        if (tabL) tabL.classList.remove('active');
        if (tabR) tabR.classList.add('active');
        if (btn) btn.innerText = 'ĐĂNG KÝ TÀI KHOẢN MỚI';
    } else {
        if (tabR) tabR.classList.remove('active');
        if (tabL) tabL.classList.add('active');
        if (btn) btn.innerText = 'ĐĂNG NHẬP';
    }
}

async function handleAuthSubmit(e) {
    e.preventDefault();
    const u = document.getElementById('authUsername').value.trim();
    const p = document.getElementById('authPassword').value.trim();
    const errEl = document.getElementById('authModalError');
    if (errEl) errEl.style.display = 'none';
    
    if (!u || !p) {
        if (errEl) { errEl.innerText = 'Vui lòng điền đầy đủ tài khoản và mật khẩu'; errEl.style.display = 'block'; }
        return;
    }

    const endpoint = authMode === 'register' ? '/api/register' : '/api/login';
    try {
        const res = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                username: u,
                password: p,
                hwid: getOrGenerateHWID()
            })
        });
        const data = await res.json();
        if (data.success) {
            localStorage.setItem('regmod_username', data.data.username);
            localStorage.setItem('regmod_api_key', data.data.api_key);
            initAuthUI();
            closeAuthModal();
            showToast(`Chào mừng ${data.data.username}! API Key: ${data.data.api_key.substring(0, 14)}...`, 'success');
        } else {
            if (errEl) {
                errEl.innerText = data.error || 'Thao tác thất bại';
                errEl.style.display = 'block';
            }
        }
    } catch (ex) {
        if (errEl) {
            errEl.innerText = 'Lỗi kết nối máy chủ: ' + ex.message;
            errEl.style.display = 'block';
        }
    }
}

// Auto run on load
window.addEventListener('DOMContentLoaded', () => {
    initTheme();
    applyLanguage();
    initAuthUI();
});
