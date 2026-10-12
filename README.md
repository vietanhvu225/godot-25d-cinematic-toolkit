# 🎮 Godot 2.5D Cinematic Platformer Toolkit (INSIDE-Style)

[![Godot Version](https://img.shields.io/badge/Godot-4.7%2B-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![MCP Protocol](https://img.shields.io/badge/MCP-Antigravity%20%2F%20Cursor%20Ready-purple.svg)](#-ai-pair-programming-via-mcp)
[![Clean Room](https://img.shields.io/badge/Design-Clean--Room%20Reimplementation-blue.svg)](https://github.com/vietanhvu225/inside-engine-deconstruction)

> **Bộ khung làm game phiêu lưu giải đố 2.5D điện ảnh (Cinematic Puzzle-Platformer) hoàn chỉnh cho Godot 4.7+.**  
> Tái hiện chuẩn xác phong cách điều khiển, hoạt ảnh thủ tục (Procedural Animation), camera điện ảnh và ánh sáng đặc trưng của *INSIDE / LIMBO / Little Nightmares*, tích hợp sẵn quy trình hỗ trợ AI Agent qua **Model Context Protocol (MCP)**.

---

## 📌 MỤC LỤC
1. [Khởi Động Nhanh Trên Mọi Máy Tính (Quickstart)](#-khởi-động-nhanh-trên-mọi-máy-tính-quickstart)
2. [Hệ Thống Phím Bấm Điều Khiển (Input Controls)](#-hệ-thống-phím-bấm-điều-khiển)
3. [Tổng Quan 6 Module Kỹ Thuật Chuyên Sâu](#-tổng-quan-6-module-kỹ-thuật-chuyên-sâu)
4. [Bộ 3 Shaders Thẩm Mỹ "Playdead Look"](#-bộ-3-shaders-thẩm-mỹ-playdead-look)
5. [Cấu Hình AI Pair-Programming Qua MCP (Antigravity / Cursor)](#-cấu-hình-ai-pair-programming-qua-mcp)
6. [Cấu Trúc Thư Mục Dự Án (Project Hierarchy)](#-cấu-trúc-thư-mục-dự-án)
7. [Tài Liệu Kỹ Thuật Đi Kèm (Technical Bibles)](#-tài-liệu-kỹ-thuật-đi-kèm)

---

## 🚀 KHỞI ĐỘNG NHANH TRÊN MỌI MÁY TÍNH (QUICKSTART)

Dự án này là một **Godot Project độc lập**, không phụ thuộc vào plugin trả phí hay runtime phức tạp. Bạn có thể clone về bất kỳ máy tính nào (Windows, macOS, Linux) và chạy ngay:

### 1. Chuẩn bị Engine:
* Tải [Godot Engine 4.7+ (Standard Version)](https://godotengine.org/download) — Không cần bản .NET/C#.

### 2. Tải mã nguồn:
```bash
git clone https://github.com/vietanhvu225/godot-25d-cinematic-toolkit.git
cd godot-25d-cinematic-toolkit
```

### 3. Mở & Chạy thử:
1. Mở Godot Engine, bấm **Import**, trỏ vào thư mục vừa clone và chọn file `project.godot`.
2. Bấm nút **Play (F5)** trên góc phải (hoặc mở scene [`scenes/test_gym.tscn`](scenes/test_gym.tscn)).
3. Trải nghiệm ngay phòng gym thử nghiệm vật lý với:
   - Nhân vật nhảy qua vực, bám dốc bằng Raycast Foot IK.
   - Đẩy/kéo khối hộp vật lý.
   - Vùng chuyển góc máy Cinematic Camera Blend Box ($32^\circ \leftrightarrow 42^\circ$ FOV).

---

## 🕹️ HỆ THỐNG PHÍM BẤM ĐIỀU KHIỂN

| Hành động (Action) | Bàn phím (Keyboard) | Tay cầm (Gamepad) | Mô tả cơ chế |
| :--- | :--- | :--- | :--- |
| **Di chuyển Trái/Phải** | `A` / `D` hoặc `←` / `→` | D-Pad / Cần Left Stick | Khóa cứng trục $Z=0.0$, quán tính trượt chân $0.18\text{s}$. |
| **Nhảy (Jump)** | `Space` hoặc `W` / `↑` | Nút `A` (Xbox) / `✕` (PS) | Lực nhảy $5.2\text{m/s}$, hỗ trợ Coyote Time ($120\text{ms}$) & Buffer ($150\text{ms}$). |
| **Chạy nước rút (Sprint)** | Giữ `Shift` | Nút `Left Trigger` / `L3` | Tăng tốc từ $2.7\text{m/s}$ (đi bộ) lên $4.0\text{m/s}$ (nước rút). |
| **Kéo / Đẩy hộp (Drag)** | Giữ `E` hoặc `Ctrl` cạnh hộp | Nút `X` (Xbox) / `▢` (PS) | Tự động hạ tốc độ còn $1.3\text{m/s}$ để mô phỏng lực cản vật lý $420\text{N}$. |

---

## 🧩 TỔNG QUAN 6 MODULE KỸ THUẬT CHUYÊN SÂU

Toàn bộ logic được chia thành các script GDScript mô-đun hóa cao, dễ dàng nhúng vào bất kỳ game 2.5D nào:

### 1. 2.5D Character Controller ([`scripts/player/inside_player_controller_25d.gd`](scripts/player/inside_player_controller_25d.gd))
- Khóa chuyển động nghiêm ngặt trên mặt phẳng 2.5D ($Z = 0$).
- **Physics Tuning chuẩn Playdead:** Gia tốc mặt đất $18.0\text{ m/s}^2$, lực cản ma sát $22.0$, gia tốc trên không $9.0$.
- **Gravity Weighting:** Nhân trọng lực $\times 1.35$ khi rơi xuống giúp cú nhảy có sức nặng; giảm trọng lực ($0.6\times$) ở đỉnh nhảy (Apex Damping) tạo cảm giác bay lơ lửng.

### 2. Procedural IK & Stumble ([`scripts/player/procedural_ik_and_stumble.gd`](scripts/player/procedural_ik_and_stumble.gd))
- **Foot IK:** 2 tia Raycast quét mặt sàn dưới chân để tự động nâng hạ bàn chân theo dốc hoặc bậc thang.
- **Hand-Snapping:** Khi chạy sát mép tường hoặc chướng ngại vật, nhân vật tự vươn tay chạm nhẹ vào bề mặt.
- **Stumble:** Tự động phát hiện va chạm tiếp đất từ độ cao lớn ($v_y < -9.5\text{m/s}$) để kích hoạt trạng thái lảo đảo/khụy chân.

### 3. Hound / Dog Guard AI ([`scripts/ai/dog_guard_ai_25d.gd`](scripts/ai/dog_guard_ai_25d.gd))
- **Giác quan kép:** Nón tầm nhìn $65^\circ$ (cự ly $14\text{m}$ có đèn, $4\text{m}$ trong tối) kết hợp cảm biến nghe tiếng bước chân (bán kính $3.5\text{m} - 13.0\text{m}$).
- **Bầy đàn kẹp góc (Pincer Steering):** Con đầu đàn săn thẳng, con phụ chạy đón đầu phía trước $4.5\text{m}$.
- **Vồ mồi (Pounce Leap):** Khựng đà $0.22\text{s}$ rồi phóng xung lực $9.0\text{m/s}$ vồ ngã nhân vật.

### 4. Thủy Quái Uốn Lượn & Phản Ứng Đèn ([`scripts/ai/water_creature_and_light.gd`](scripts/ai/water_creature_and_light.gd))
- Mô phỏng bơi lượn uốn khúc chuỗi xương 8 đốt (Verlet Kinematics).
- Máy trạng thái né ánh sáng: Khi bị đèn pha `SpotLight3D` chiếu trúng, thủy quái quằn quại rung giật và tháo lui $4.2\text{m/s}$ về vùng tối; khi đèn tắt thì lao phục kích $7.8\text{m/s}$.

### 5. Quái Thể The Huddle Soft-Body ([`scripts/physics/huddle_softbody_controller.gd`](scripts/physics/huddle_softbody_controller.gd))
- Mô phỏng khối sinh vật biến dạng mềm khối lượng $480\text{kg}$ với mạng lưới 12 lò xo xuyên tâm.
- Dịch chuyển tâm khối lượng (Center of Mass shift $0.45\text{m}$) tạo mô-men xoay tự lăn $6200\text{N}\cdot\text{m}$, tự động vươn tay bám mặt sàn và húc sập tường chắn vỡ vụn khi động năng $\ge 2600\text{J}$.

### 6. Cinematic Camera & Level Streaming
- [`scripts/camera/cinematic_camera_trigger.gd`](scripts/camera/cinematic_camera_trigger.gd): Vùng kích hoạt chuyển góc máy mượt mà (chuyển đổi FOV, cự ly Z và khóa trục camera tĩnh).
- [`scripts/systems/level_streaming_manager.gd`](scripts/systems/level_streaming_manager.gd): Quản lý nạp trước màn chơi con ngầm đa luồng ở cự ly $35\text{m}$ và giải phóng ở cự ly $55\text{m}$, triệt tiêu 100% hiện tượng khựng khung hình.

---

## 🎨 BỘ 3 SHADERS THẨM MỸ "PLAYDEAD LOOK"

1. [`shaders/playdead_palette.gdshader`](shaders/playdead_palette.gdshader): Ánh xạ ảnh thang độ xám (Grayscale) sang bảng màu gradient 1D (Palette LUT), mang lại tông màu u tối, lạnh lẽo đặc trưng.
2. [`shaders/fake_bounce_light.gdshader`](shaders/fake_bounce_light.gdshader): Giả lập tia sáng gián tiếp hắt ngược từ mặt sàn lên phần dưới cơ thể nhân vật mà không tốn chi phí chiếu sáng toàn cục (GI).
3. [`shaders/volumetric_fog_dither.gdshader`](shaders/volumetric_fog_dither.gdshader): Sương mù thể tích kèm ma trận Bayer 4x4 dither giúp loại bỏ triệt để hiện tượng vệt sọc màu (Color Banding) trong bóng tối.

---

## 🤖 CẤU HÌNH AI PAIR-PROGRAMMING QUA MCP

Bộ công cụ này được thiết kế để bạn lập trình cặp (Pair-Programming) cùng AI Agent (Google Antigravity, Cursor, Claude Code) thông qua giao thức **Model Context Protocol (MCP)**:

### Cách kích hoạt:
1. Đảm bảo máy tính có Python 3.10+ (hoặc trỏ tới đường dẫn Python trên máy bạn).
2. Mở file cấu hình MCP của IDE (ví dụ: `mcp_config.json`):
```json
{
  "mcpServers": {
    "godot": {
      "command": "python",
      "args": [
        "addons/gamedev_ai/mcp/godot_mcp.py"
      ],
      "env": {
        "GODOT_HOST": "127.0.0.1",
        "GODOT_PORT": "6543"
      }
    }
  }
}
```
3. Khởi động plugin trong Godot: AI Agent bên ngoài sẽ tự động nhận diện cây Scene Tree đang mở, hỗ trợ tạo Node, kiểm tra lỗi LSP thời gian thực và tự sửa bug console.

---

## 📂 CẤU TRÚC THƯ MỤC DỰ ÁN

```text
godot-25d-cinematic-toolkit/
├── project.godot                  # File cấu hình engine Godot 4.7
├── mcp_config.json                # Cấu hình kết nối MCP cho AI Agent
├── scenes/
│   └── test_gym.tscn              # Màn chơi thử nghiệm vật lý & camera
├── scripts/
│   ├── player/
│   │   ├── inside_player_controller_25d.gd
│   │   └── procedural_ik_and_stumble.gd
│   ├── ai/
│   │   ├── dog_guard_ai_25d.gd
│   │   └── water_creature_and_light.gd
│   ├── physics/
│   │   └── huddle_softbody_controller.gd
│   ├── camera/
│   │   └── cinematic_camera_trigger.gd
│   └── systems/
│       └── level_streaming_manager.gd
├── shaders/
│   ├── playdead_palette.gdshader
│   ├── fake_bounce_light.gdshader
│   └── volumetric_fog_dither.gdshader
└── docs/
    ├── INSIDE_ADVANCED_SYSTEMS_BIBLE.md
    └── GODOT_MCP_COMPREHENSIVE_ANALYSIS.md
```

---

## 📚 TÀI LIỆU KỸ THUẬT ĐI KÈM

- 📖 [**INSIDE Advanced Systems Bible**](docs/INSIDE_ADVANCED_SYSTEMS_BIBLE.md): Toàn bộ công thức toán học, sơ đồ tuần tự Mermaid, giải thích từng hệ số vật lý.
- 📖 [**Godot MCP Comprehensive Analysis**](docs/GODOT_MCP_COMPREHENSIVE_ANALYSIS.md): Báo cáo đánh giá so sánh các giải pháp MCP (gamedev_ai, godot-mcp-enhanced, gitot).
- 🔬 [**Hồ Sơ Reverse Engineering Gốc (Repo 1)**](https://github.com/vietanhvu225/inside-engine-deconstruction): Kết quả bóc tách nhị phân và giải mã FSM PlayMaker của game gốc.

---
*Phát triển và bảo trì bởi vietanhvu225. Giấy phép MIT License - Tự do sử dụng cho mục đích cá nhân và thương mại.*
