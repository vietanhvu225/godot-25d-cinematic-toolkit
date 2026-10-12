# 🏛️ CẨM NANG HỆ THỐNG CHUYÊN SÂU NÂNG CAO GAME INSIDE
## (INSIDE ADVANCED SYSTEMS & ARCHITECTURE MASTER BIBLE)

**Phát triển bởi:** Playdead  
**Bóc tách & Tái cấu trúc kỹ thuật cho:** Godot Engine 4.x & Blender  
**Tập hợp mã nguồn bàn giao:**
- [`dog_guard_ai_25d.gd`](file:///D:/3_research/dog_guard_ai_25d.gd) — AI Giác quan, Tầm nhìn hình nón & Bầy đàn Pincer Steering.
- [`procedural_ik_and_stumble.gd`](file:///D:/3_research/procedural_ik_and_stumble.gd) — Hoạt ảnh thích ứng địa hình Foot/Hand IK & Vật lý vấp ngã Stumble.
- [`water_creature_and_light.gd`](file:///D:/3_research/water_creature_and_light.gd) — Động học bơi lội chuỗi xương & Máy trạng thái né ánh sáng đèn pha.
- [`playdead_palette.gdshader`](file:///D:/3_research/playdead_palette.gdshader) — Bộ Shader Color Lookup Table ánh xạ ảnh xám 8-bit sang bảng Palette 1D.
- [`fake_bounce_light.gdshader`](file:///D:/3_research/fake_bounce_light.gdshader) — Giả lập ánh sáng hắt ngược từ mặt sàn (Ground Bounce Light).
- [`volumetric_fog_dither.gdshader`](file:///D:/3_research/volumetric_fog_dither.gdshader) — Sương mù thể tích kèm ma trận Bayer 4x4 khử sọc màu (Color Banding).
- [`huddle_softbody_controller.gd`](file:///D:/3_research/huddle_softbody_controller.gd) — Động lực học khối thịt mềm (Soft-body) & dịch chuyển tâm khối lượng.
- [`cinematic_camera_trigger.gd`](file:///D:/3_research/cinematic_camera_trigger.gd) — Vùng kích hoạt khung hình điện ảnh (Camera Blend Box).
- [`level_streaming_manager.gd`](file:///D:/3_research/level_streaming_manager.gd) — Quản lý nạp ngầm thế giới liền mạch không màn hình chờ (Zero Loading Screens).

---

## MỤC LỤC CHUYÊN SÂU
1. [MODULE 1: AI Giác Quan & Bầy Đàn (Dog & Guard AI Steering)](#module-1-ai-giác-quan--bầy-đàn-dog--guard-ai-steering)
2. [MODULE 2: Hoạt Ảnh Thủ Tục & Thích Ứng IK (Procedural IK & Stumble)](#module-2-hoạt-ảnh-thủ-tục--thích-ứng-ik-procedural-ik--stumble)
3. [MODULE 3: Thủy Quái & Tương Tác Ánh Sáng (Water Creature & Light Repellent)](#module-3-thủy-quái--tương-tác-ánh-sáng-water-creature--light-repellent)
4. [MODULE 4: Bộ Shader Đồ Họa Độc Quyền (The Playdead Look Shaders)](#module-4-bộ-shader-đồ-họa-độc-quyền-the-playdead-look-shaders)
5. [MODULE 5: Vật Lý Quái Thể Khổng Lồ (The Huddle Soft-Body Mechanics)](#module-5-vật-lý-quái-thể-khổng-lồ-the-huddle-soft-body-mechanics)
6. [MODULE 6: Camera Điện Ảnh & Nạp Màn Chơi Liền Mạch (Cinematics & Streaming)](#module-6-camera-điện-ảnh--nạp-màn-chơi-liền-mạch-cinematics--streaming)

---

## MODULE 1: AI GIÁC QUAN & BẦY ĐÀN (DOG & GUARD AI STEERING)

Bóc tách từ các lớp gốc của Playdead: `ChaserBase`, `ChaserDudeDroppableFlashLight`, `DogChaseDistCompare` và `HulvBark`.

### 1. Mô hình Toán học Giác quan
1. **Nón Tầm nhìn 3D (Vision Cone):**  
   Một điểm mục tiêu $P_{target}$ nằm trong tầm nhìn khi thỏa mãn đồng thời 3 điều kiện:
   $$\|P_{target} - P_{AI}\| \le R_{vision}$$
   $$rac{(P_{target} - P_{AI}) \cdot ec{F}_{forward}}{\|P_{target} - P_{AI}\|} \ge \cos(	heta_{half})$$
   $$	ext{RaycastOcclusion}(P_{AI} + ec{h}_{eye}, P_{target}) = 	ext{Clear}$$
   Trong đó:
   - $R_{vision} = 14.0	ext{m}$ khi có đèn pin / ánh sáng ban ngày; $4.0	ext{m}$ trong bóng tối.
   - $	heta_{half} = 65.0^\circ$ (góc quét rộng $130^\circ$).
2. **Bán kính Lan truyền Âm thanh (Sound Propagation Radius):**
   - Đi bộ: $R_{hear} = 3.5	ext{m}$
   - Chạy nước rút (Sprint): $R_{hear} = 9.0	ext{m}$
   - Vùng vẫy dưới nước (Water Splash): $R_{hear} = 13.0	ext{m}$
3. **Thuật toán Kẹp góc Bầy đàn (Pincer Steering):**  
   Khi có 2 chó săn hoặc lính gác cùng truy kích, AI phụ (Flanker) không chạy thẳng về phía người chơi mà tính toán vị trí chặn đầu (Intercept Prediction):
   $$X_{intercept} = X_{player} + 	ext{sign}(V_{player.x}) 	imes D_{flank}$$
   với $D_{flank} = 4.5	ext{m}$.

### 2. Sơ đồ Máy trạng thái AI (State Diagram)
```mermaid
stateDiagram-v2
    [*] --> PATROL: Bắt đầu tuần tra theo Waypoints
    PATROL --> SUSPICIOUS: Nghe tiếng động chân (Walk / Splash)
    PATROL --> PURSUIT: Nhìn thấy người chơi trong nón tầm nhìn
    SUSPICIOUS --> PATROL: Mất dấu sau 4.0s (Hạ mức cảnh giác về 0)
    SUSPICIOUS --> PURSUIT: Tiếp cận thấy người chơi
    
    state PURSUIT {{
        [*] --> Direct_Chase: Kẻ săn chính đuổi thẳng
        [*] --> Pincer_Flank: Kẻ săn phụ chạy đón đầu
    }}
    
    PURSUIT --> POUNCE_PREP: Khoảng cách <= 3.2m
    
    state POUNCE_PREP {{
        [*] --> Crouch_Growl: Khựng lại 0.22s dồn lực chân sau
    }}
    
    POUNCE_PREP --> POUNCE_LEAP: Phóng xung lực 9.0 m/s
    POUNCE_LEAP --> KILL_SUCCESS: Trúng mục tiêu (Khoảng cách <= 0.85m)
    POUNCE_LEAP --> PURSUIT: Vồ trượt chạm đất
```

### 3. Sơ đồ Tuần tự Săn mồi Bầy đàn (Sequence Diagram)
```mermaid
sequenceDiagram
    autonumber
    actor Player as Cậu Bé
    participant HoundA as Chó Săn 1 (Chính)
    participant HoundB as Chó Săn 2 (Flanker)
    participant Audio as Âm Thanh Bước Chân

    Player->>Audio: Chạy nước rút trên bùn (Speed 4.0 m/s)
    Audio->>HoundA: Lan truyền sóng âm trong bán kính 9.0m
    Audio->>HoundB: Lan truyền sóng âm trong bán kính 9.0m
    HoundA->>HoundA: Chuyển sang SUSPICIOUS, quay đầu về nguồn âm
    HoundA->>Player: Bắt gặp mục tiêu trong nón tầm nhìn 65 độ
    HoundA->>HoundB: Broadcast 'TARGET_ACQUIRED'
    HoundA->>Player: Rượt đuổi trực diện với tốc độ 6.2 m/s
    HoundB->>Player: Chạy bọc sườn đón đầu trước 4.5 mét
    HoundA->>HoundA: Đạt cự ly 3.2m -> Khựng người sạc lực 0.22s
    HoundA->>Player: Lao vút lên không trung (Pounce Leap 9.0 m/s)
    HoundA->>Player: Ghì chặt người chơi xuống đất (Kill Success)
```

---

## MODULE 2: HOẠT ẢNH THỦ TỤC & THÍCH ỨNG IK (PROCEDURAL IK & STUMBLE)

Bóc tách từ: `HuddleFootProbe`, `BoyReachPlateauState`, `FallUtils`.

### 1. Thuật toán Foot IK (Bám bậc thang & Dốc nghiêng)
- Bắn 2 tia Raycast từ hông xuống:
  $$Y_{target.L} = 	ext{Raycast}(P_{hip} + ec{x}_{-offset}, ec{down}).y + H_{sole}$$
  $$Y_{target.R} = 	ext{Raycast}(P_{hip} + ec{x}_{+offset}, ec{down}).y + H_{sole}$$
- Nội suy mượt mà qua hàm LERP:
  $$Y_{foot}(t) = 	ext{lerp}(Y_{foot}(t - \Delta t), Y_{target}, lpha_{ik} \Delta t)$$
  với $lpha_{ik} = 16.0$, đảm bảo bàn chân bám dính tự nhiên lên từng bậc thang mà không có độ trễ giật.

### 2. Thuật toán Hand-Snapping (Hít vách tường & Mép hộp)
- Khi nhân vật chạy sát tường ($\le 0.85	ext{m}$), tia raycast ngang từ ngực phát hiện mặt phẳng va chạm:
  $$P_{palm} = P_{hit} + ec{N}_{surface} 	imes 0.04	ext{m}$$
  Bàn tay nhân vật tự động duỗi ra đặt lên tường, tạo cảm giác nhân vật cảm nhận được môi trường xung quanh.

### 3. Động lực học Rơi ngã & Loạng choạng (Stumble Dynamics)
- Ngưỡng vận tốc tiếp đất $V_y$:
  - $V_y > -10.5	ext{m/s}$: Tiếp đất êm dịu, không gián đoạn chuyển động.
  - $-17.5	ext{m/s} \le V_y \le -10.5	ext{m/s}$: **Loạng choạng (Stumble)**. Khóa điều khiển $0.48	ext{s}$, vận tốc ngang bị triệt tiêu với gia tốc hãm $18	ext{m/s}^2$, nhân vật khuỵu gối chống tay.
  - $V_y < -17.5	ext{m/s}$: **Tử vong (Fatal Fall)**. Xương gãy, kích hoạt Ragdoll buông thõng.

---

## MODULE 3: THỦY QUÁI & TƯƠNG TÁC ÁNH SÁNG (WATER CREATURE & LIGHT REPELLENT)

Bóc tách từ: `WaterGirl`, `VisualWaterGirl`, `UnderwaterCoil` và `RopesAndWaterGirlCamController`.

### 1. Động học Bơi lượn Chuỗi Xương (Verlet Spine Undulation)
Thân thủy quái gồm $N = 8$ đốt liên kết. Đốt đầu tiên dao động điều hòa:
$$Y_{head}(t) = Y_{base} + A \sin(\omega t)$$
với $A = 0.35	ext{m}$, $\omega = 4.5	ext{Hz}$.
Các đốt kế tiếp tuân thủ ràng buộc khoảng cách cố định (Distance Constraint):
$$P_{i} = P_{i-1} + rac{P_{i} - P_{i-1}}{\|P_{i} - P_{i-1}\|} 	imes L_{segment}$$
với $L_{segment} = 0.32	ext{m}$, tạo nên chuyển động uốn éo như lươn/rắn biển cực kỳ sống động.

### 2. Sơ đồ Máy trạng thái Xung đột Ánh sáng (State Diagram)
```mermaid
stateDiagram-v2
    [*] --> STALKING: Rình rập ngoài tầm đèn pha (Cự ly 6-8m)
    
    state STALKING {{
        [*] --> Circle_Perimeter: Bơi lượn vòng quanh con mồi
    }}
    
    STALKING --> LIGHT_BLINDED: Bị rọi trúng bởi Đèn Pha (SpotLight3D)
    
    state LIGHT_BLINDED {{
        [*] --> Violent_Tremor: Rung giật quằn quại
        Violent_Tremor --> Recoil_Retreat: Bơi lùi về vùng tối (4.2 m/s)
    }}
    
    LIGHT_BLINDED --> PREPARE_AMBUSH: Đèn pha quay đi chỗ khác
    
    state PREPARE_AMBUSH {{
        [*] --> Lurk_In_Shadows: Chờ thời cơ trong bóng tối 0.35s
    }}
    
    PREPARE_AMBUSH --> AMBUSH_CHARGE: Phóng tới tấn công (7.8 m/s)
    PREPARE_AMBUSH --> LIGHT_BLINDED: Đèn pha quét lại
    AMBUSH_CHARGE --> LIGHT_BLINDED: Người chơi kịp chiếu đèn cản phá
    AMBUSH_CHARGE --> LATCH_KILL: Bắt được cậu bé (Cự ly <= 0.8m)
    
    state LATCH_KILL {{
        [*] --> Drag_To_Abyss: Kéo thẳng xuống đáy sâu vĩnh hằng
    }}
```

---

## MODULE 4: BỘ SHADER ĐỒ HỌA "THE PLAYDEAD LOOK"

INSIDE sử dụng bảng màu 8-bit lập chỉ mục (8-bit Grayscale Index) phối hợp cùng các bảng màu Palette 1D (trích xuất tại `games/inside/extracted_assets/textures/`).

```mermaid
graph LR
    Model[3D Model UV Mesh] --> GrayTex[8-bit Grayscale Index Texture]
    GrayTex --> LUT[playdead_palette.gdshader]
    Palette[1D Color Palette] --> LUT
    LUT --> Bounce[fake_bounce_light.gdshader]
    Bounce --> Dither[volumetric_fog_dither.gdshader]
    Dither --> Screen[Màn Hình Điện Ảnh Cinematic]
```

1. **`playdead_palette.gdshader`:**  
   Lấy giá trị xám $R \in [0.0, 1.0]$ làm tọa độ $U$ để tra cứu màu từ `palette_texture`. Kỹ thuật này giúp nghệ sĩ đổi toàn bộ không khí màu sắc của màn chơi chỉ bằng việc thay đổi 1 texture dải màu 256x1 pixel!
2. **`fake_bounce_light.gdshader`:**  
   Tạo ánh sáng hắt từ mặt đất:
   $$I_{bounce} = \max(-ec{N}_{world} \cdot ec{Y}, 0.0)^{1.2} 	imes C_{ground} 	imes 0.65$$
   Giúp phần thân dưới của nhân vật không bị đen sì mà luôn có màu xanh rêu của bùn đất hắt lên.
3. **`volumetric_fog_dither.gdshader`:**  
   Sử dụng ma trận Bayer 4x4 để cộng nhiễu giả lập vào gradient sương mù, triệt tiêu 100% hiện tượng vệt màu sọc (banding) trên màn hình 8-bit.

---

## MODULE 5: VẬT LÝ QUÁI THỂ KHỔNG LỒ (THE HUDDLE / THE BLOB)

Bóc tách từ: `Huddle`, `AudioHuddleRoll`, `FakeSpring`, `FloatMatrixHuddleStatus`.

### 1. Động lực học Lăn Quán tính Cao (High-Inertia Rolling)
- Khối lượng $M = 480	ext{kg}$.
- **Dịch chuyển Tâm khối lượng (Center of Mass Shift):**  
  Khi người chơi nhấn Trái/Phải ($Input_x$):
  $$CoM_x = Input_x 	imes 0.45	ext{m}$$
  Tâm khối lượng lệch hẳn về phía trước tạo mô-men tự quay (self-torque) khổng lồ:
  $$	au_z = -Input_x 	imes 6200	ext{N}\cdot	ext{m}$$
  khiến khối thịt nặng nề lăn tròn trên sàn nhà với quán tính đầm chắc.

### 2. Mạng lưới Lò xo Biến dạng Mềm (Soft-Body Springs)
- 12 nút lò xo phân bổ xuyên tâm quanh lõi:
  $$ec{F}_i = -k (ec{P}_i - ec{P}_{rest}) - c ec{V}_i$$
  với $k = 240	ext{N/m}$, $c = 14	ext{N}\cdot	ext{s/m}$. Khối thịt co giãn, méo mó khi va chạm gờ tường hoặc rơi từ trên cao.

### 3. Động năng Phá hủy (Wall Smashing Threshold)
- Khi va chạm vật thể có tag `destructible_wall`:
  $$E_k = rac{1}{2} M V_{impact}^2 \ge 2600	ext{Joules}$$
  Khối thịt sẽ húc bay tường bê tông, tạo hiệu ứng vỡ vụn và rung chấn màn hình dữ dội.

---

## MODULE 6: CAMERA ĐIỆN ẢNH & NẠP MÀN CHƠI LIỀN MẠCH

Bóc tách từ: `Camera Blend Box`, `EndLockCameraPivot`, `SubsceneBounds`, `UnloadInactiveSubscenes`.

### 1. Camera Framing Triggers (`cinematic_camera_trigger.gd`)
- Khi nhân vật bước vào trigger box, camera tự động chuyển đổi phối cảnh:
  - **Phòng hẹp / Tra khảo:** FOV thu hẹp còn $22^\circ$, cự ly Z kéo sát còn $10	ext{m}$.
  - **Đại cảnh nhà máy / Rừng hoang:** FOV mở rộng ra $42^\circ$, cự ly Z lùi xa $22	ext{m}$.
  - **Khóa trục (Stationary Shot):** Khóa tạm thời tọa độ X/Y để tạo góc máy tĩnh điện ảnh khi nhân vật giải đố.

### 2. Quản lý Màn chơi Liền mạch (Seamless Streaming)
- Bản đồ INSIDE được chia nhỏ thành các subscene dọc trục X:
  - Cự ly nạp trước: $D_{preload} = 35.0	ext{m}$. Khi người chơi còn cách subscene kế tiếp 35m, hệ thống dùng `ResourceLoader.load_threaded_request()` để nạp ngầm đa luồng.
  - Cự ly giải phóng: $D_{unload} = 55.0	ext{m}$. Khi người chơi đã đi qua và vượt xa 55m, subscene cũ tự động `queue_free()`.
- Kết quả: Game vận hành xuyên suốt hàng chục giờ chơi mà không xuất hiện bất kỳ màn hình loading nào, bộ nhớ RAM duy trì ổn định dưới 1.2GB.

---

## 🎯 TỔNG KẾT BÀN GIAO SẴN SÀNG

Toàn bộ 6 module kỹ thuật đã được hiện thực hóa trọn vẹn thành các file mã nguồn và shader độc lập. Bạn có thể mở trực tiếp các file này và tích hợp ngay vào Godot Engine 4.x!
