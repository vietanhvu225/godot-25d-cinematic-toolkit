# AGENTS.MD — INSTRUCTIONS & CODE CONVENTIONS FOR GODOT 2.5D CINEMATIC TOOLKIT

> **File này dành riêng cho tất cả các AI Coding Agent (Antigravity, Claude Code, Cursor, Codex, Gemini...) khi thao tác trong repository `godot-25d-cinematic-toolkit`.**  
> Mọi agent bắt buộc phải tuân thủ nghiêm ngặt các quy chuẩn dưới đây khi viết GDScript, tạo Shader, dựng Scene và thiết kế cơ chế gameplay.

---

## 🎯 1. MỤC TIÊU DỰ ÁN (PROJECT SCOPE)

* Xây dựng một **Framework & Starter Kit 2.5D cinematic** hoàn chỉnh trên **Godot 4.x** tái lập trải nghiệm điều khiển, giải đố vật lý và không khí điện ảnh theo phong cách đặc trưng của Playdead (*INSIDE* / *Limbo*).
* Cung cấp các module độc lập, có khả năng tái sử dụng cao, sạch sẽ và sẵn sàng mở rộng cho bất kỳ tựa game 2.5D puzzle-platformer nào.

---

## 🗺️ 2. PHÂN ĐỊNH RANH GIỚI THƯ MỤC (DIRECTORY BOUNDARIES)

Tuyệt đối tuân thủ cấu trúc thư mục phân cấp, **KHÔNG** tạo script lung tung ở thư mục gốc của repo:

```
godot-25d-cinematic-toolkit/
├── docs/                        <-- Tài liệu kiến trúc & cẩm nang hệ thống nâng cao
├── scenes/                      <-- Màn chơi mẫu (test_gym.tscn, puzzle rooms)
├── scripts/                     <-- Toàn bộ mã nguồn GDScript chia theo module:
│   ├── player/                  <-- Character controller, procedural IK, chân vấp ngã
│   ├── camera/                  <-- Camera điện ảnh 2.5D, deadzone, camera triggers
│   ├── physics/                 <-- Tương tác kéo đẩy thùng gỗ, softbody, bập bênh
│   ├── ai/                      <-- Hành vi kẻ địch (chó săn Dog Guard, quái vật dưới nước)
│   └── systems/                 <-- Streaming màn chơi, checkpoint, save game
├── shaders/                     <-- Bộ shader phong cách Playdead (fog, bounce light, palette)
└── project.godot                <-- Cấu hình chính thức của engine
```

---

## 🎮 3. TIÊU CHUẨN LẬP TRÌNH GDSCRIPT 2.0 (HARD CODING RULES)

Khi viết hoặc chỉnh sửa mã GDScript, Agent **BẮT BUỘC** tuân thủ:

1. **Static Typing 100% (Bắt buộc khai báo kiểu dữ liệu rõ ràng):**
   - Mọi biến, tham số hàm và giá trị trả về đều phải có static type hint:
     ```gdscript
     var run_speed: float = 6.8
     var is_grounded: bool = false
     var current_velocity: Vector3 = Vector3.ZERO

     func apply_impulse(force: Vector3, point: Vector3 = Vector3.ZERO) -> void:
     ```
2. **Khóa trục $Z$ tuyệt đối cho chuyển động 2.5D:**
   - Mọi diễn hoạt và tính toán va chạm diễn ra trong không gian 3D, nhưng nhân vật và các thực thể 2.5D phải luôn cố định trên mặt phẳng $XY$:
     ```gdscript
     velocity.z = 0.0
     global_position.z = 0.0
     ```
3. **Quy ước đặt tên (Naming Conventions):**
   - **Tên file & thư mục:** `snake_case` (ví dụ: `inside_player_controller_25d.gd`).
   - **Tên Node & Class:** `PascalCase` (ví dụ: `class_name InsidePlayerController25D extends CharacterBody3D`).
   - **Tên hàm & biến:** `snake_case` (ví dụ: `_update_grab_physics()`).
   - **Hằng số:** `UPPER_SNAKE_CASE` (ví dụ: `const DEFAULT_GRAVITY: float = 24.0`).
   - **Tín hiệu (Signals):** Viết ở dạng thì quá khứ (ví dụ: `signal jumped()`, `signal crate_grabbed(crate: RigidBody3D)`).

---

## 🎬 4. CÔNG THỨC THẨM MỸ & CẢM GIÁC GAME (PLAYDEAD FEEL FORMULA)

Khi tinh chỉnh thông số vật lý và đồ họa, luôn đảm bảo các nguyên tắc:

* **Trọng lực bất đối xứng (Asymmetric Gravity):**
  - Tốc độ rơi luôn lớn hơn tốc độ bay lên để nhân vật tiếp đất dứt khoát, không bị cảm giác "bay bổng":
    `fall_gravity_multiplier = 1.6 - 2.0 * jump_gravity`.
* **Cơ chế tha thứ khi nhảy (Forgiving Platforming Controls):**
  - Luôn tích hợp **Coyote Time** (~0.1 - 0.12s) cho phép nhảy sau khi vừa rời khỏi gờ tường.
  - Luôn tích hợp **Jump Buffer** (~0.1s) ghi nhận thao tác bấm nhảy trước khi chạm đất.
* **Camera điện ảnh (Cinematic Camera):**
  - Không bao giờ gắn cứng camera thẳng vào nhân vật.
  - Luôn sử dụng vùng chết hình chữ nhật (**Deadzone**) và độ trễ làm mượt (**Smooth Lerp / Damping**).
* **Màu sắc & Ánh sáng:**
  - Tông màu lạnh, giảm bão hòa (desaturated), u tối, tối giản.
  - Sử dụng đèn viền (**Rim Light**) để nhân vật tách biệt khỏi nền đen.
  - Tích hợp **Volumetric Fog Dithering** để tạo chiều sâu sương mù.

---

## 🛠️ 5. QUY TRÌNH KIỂM THỬ TỰ ĐỘNG (VERIFICATION)

- Mỗi khi thêm hoặc sửa đổi file trong repo này, Agent cần kiểm tra tính hợp lệ bằng lệnh:
  ```bash
  godot --headless --check-only
  ```
- Đảm bảo scene mẫu `scenes/test_gym.tscn` luôn tải được và không phát sinh cảnh báo đứt gãy node path.
