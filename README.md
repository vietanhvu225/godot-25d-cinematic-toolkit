# 🎮 Godot 2.5D Cinematic Platformer Toolkit (INSIDE-Style)

[![Godot Version](https://img.shields.io/badge/Godot-4.7%2B-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![MCP Protocol](https://img.shields.io/badge/MCP-Antigravity%20%2F%20Cursor%20Ready-purple.svg)](#-hệ-sinh-thái-mcp--ai-pair-programming-antigravity--cursor)
[![Clean Room](https://img.shields.io/badge/Design-Clean--Room%20Reimplementation-blue.svg)](https://github.com/vietanhvu225/inside-engine-deconstruction)

> **Bộ khung làm game phiêu lưu giải đố 2.5D điện ảnh (Cinematic Puzzle-Platformer) hoàn chỉnh cho Godot 4.7+.**  
> Tái hiện chuẩn xác phong cách điều khiển, hoạt ảnh thủ tục (Procedural Animation), camera điện ảnh và ánh sáng đặc trưng của *INSIDE / LIMBO / Little Nightmares*, tích hợp sẵn quy trình hỗ trợ AI Agent qua **Model Context Protocol (MCP)**.

---

## 📌 MỤC LỤC
1. [Khởi Động Nhanh Trên Mọi Máy Tính (Quickstart)](#-khởi-động-nhanh-trên-mọi-máy-tính-quickstart)
2. [Hệ Thống Phím Bấm Điều Khiển (Input Controls)](#-hệ-thống-phím-bấm-điều-khiển)
3. [Tổng Quan 6 Module Kỹ Thuật Chuyên Sâu](#-tổng-quan-6-module-kỹ-thuật-chuyên-sâu)
4. [Bộ 3 Shaders Thẩm Mỹ "Playdead Look"](#-bộ-3-shaders-thẩm-mỹ-playdead-look)
5. [Hệ Sinh Thái MCP & AI Pair-Programming (Antigravity / Cursor)](#-hệ-sinh-thái-mcp--ai-pair-programming-antigravity--cursor)
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

## 🤖 HỆ SINH THÁI MCP & AI PAIR-PROGRAMMING (ANTIGRAVITY / CURSOR)

Bộ công cụ này được thiết kế theo tư duy **AI-Native Game Development**: lập trình viên phát triển song hành cùng AI Agent (Google Antigravity, Cursor, Claude Code) thông qua giao thức mở **Model Context Protocol (MCP)**.

### 🔍 5.1. Hành Trình Tuyển Chọn Giải Pháp MCP (Từ Gốc Đến Đích)

Để tìm ra giải pháp tối ưu cho Godot 4.7+, chúng tôi đã thực hiện nghiên cứu chuyên sâu qua 2 vòng sàng lọc khắt khe:

* **Vòng 1 (GitHub Ecosystem Scan):** Khảo sát các repo MCP độc lập phổ biến (`Coding-Solo/godot-mcp`, `hi-godot/godot-ai`, `ee0pdt/Godot-MCP`, `IvanMurzak/Godot-MCP`). Nhận thấy đa số giải pháp chỉ hỗ trợ Godot 4.2/4.3 cũ, thiếu cơ chế xác thực hoặc thiếu UI tương tác trực quan trong Editor.
* **Vòng 2 (Official Godot Asset Library Deep-Dive):** Quét toàn bộ các công cụ đã qua kiểm duyệt trên Godot Asset Library (#5086, #5375, #5369, #5193, #5482, #5522). Phát hiện ra các giải pháp thế hệ mới đột phá về độ tương thích Godot 4.7+, tính an toàn và khả năng gỡ lỗi.

---

### 📊 5.2. BẢNG SO SÁNH ROUND 2 VỚI CÁC ỨNG VIÊN ROUND 1

| Tiêu chí kỹ thuật | `fredarts/gamedev_ai` (#5086) ⭐ | `NPGameDev/godot-mcp-toolkit` (#5375) | `TomasLucas/godot-mcp-bridge` (#5369) | `wgt19861219/godot-mcp-enhanced` (#5193) | `hi-godot/godot-ai` (Round 1) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Độ tương thích Godot 4.7.2** | **⭐⭐⭐⭐⭐ (Native 4.7+)** | ⭐⭐⭐⭐☆ (4.2+) | ⭐⭐⭐⭐☆ (4.5+) | ⭐⭐⭐⭐☆ (4.3+) | ⭐⭐⭐⭐☆ (4.3+) |
| **Kiểm duyệt trên Asset Library** | **✅ Có (ID 5086)** | **✅ Có (ID 5375)** | **✅ Có (ID 5369)** | **✅ Có (ID 5193)** | ❌ Chưa (GitHub only) |
| **Giao diện Editor UI tích hợp** | **✅ AI Dock + Visual Diff** | ❌ Không (Thuần MCP) | ❌ Không (Thuần MCP) | ⚠️ Dock tối giản | ⚠️ Chỉ có status dock |
| **Khả năng Step-Debugging** | ⚠️ Đọc log console | ⚠️ Đọc log console | **✅ Đặt Breakpoint DAP** | ⚠️ QA Assertions & GIF | ⚠️ Đọc log console |
| **Tối ưu hóa Token LLM** | ⭐⭐⭐⭐☆ (30+ Tools) | ⭐⭐⭐☆☆ (150+ Tools) | ⭐⭐⭐☆☆ (231 Tools) | ⭐⭐⭐⭐☆ (46 Tools/272 Actions) | **⭐⭐⭐⭐⭐ (Domain Rollups)** |
| **Hỗ trợ Antigravity rõ ràng** | **✅ Nêu danh trong Docs** | ✅ Tương thích chung | ✅ Tương thích chung | ✅ Tương thích chung | ✅ Tương thích chung |
| **Trọng tâm kiến trúc** | **Authoring + Safe Diff + Watch Mode** | Pure MCP Operations | Bi-directional Awareness + DAP | Closed-Loop QA + Auto GIF | Token-optimized Viewport |

---

### 🎯 5.3. Rationale: Tại Sao Chọn `fredarts/gamedev_ai` (#5086) Làm Giải Pháp Trọng Tâm?

1. **Khớp phiên bản 100% (Godot 4.7+):** Đây là công cụ hiếm hoi trên Asset Library gắn nhãn chính thức hỗ trợ **Godot 4.7+**, không bị lỗi deprecation warning của GDScript mới.
2. **Hỗ trợ chính thức Google Antigravity & Cursor:** Tài liệu kỹ thuật của tác giả ghi nhận chuẩn Stdio Bridge qua file Python `godot_mcp.py` kết nối trực tiếp vào JSON-RPC Server nội bộ cổng `6543`.
3. **Mô hình "Dual-Workspace" an toàn nhất:**
   - **Bên ngoài:** Antigravity có thể tự động tạo node, nối signal, sửa script theo vùng chọn.
   - **Bên trong:** Godot hiển thị bảng **Safe Visual Diff** (màu xanh/đỏ) để bạn bấm `Accept` hoặc `Reject` trước khi áp dụng, kèm **Watch Mode** tự động phát hiện lỗi crash ở tab Output để đề xuất sửa lỗi tức thì.

---

### 🛡️ 5.4. Công Cụ Đồng Hành Quản Trị Git: `Gitot` (Asset #5522)

Để quy trình phát triển hoàn chỉnh từ A-Z ngay trong Godot 4.7.2, dự án đề xuất sử dụng kèm:
- **`SigKdev/godot-gitot`** ([Asset #5522](https://godotengine.org/asset-library/asset/5522)): Tiện ích Git đồ họa thuần GDScript chạy trực tiếp trong Editor.
- **Tính năng sống còn:**
  - **Large-File Guard:** Ngăn chặn vô tình commit file 3D/Audio nặng vào Git thường, hỗ trợ 1-click đưa sang Git LFS.
  - **Diff Gutter:** Hiển thị vạch màu xanh lá / cam ngay lề mã nguồn GDScript khi AI vừa sửa code.
  - **Branch Switch Scene Reload:** Đổi nhánh không cần tắt mở lại Godot.

---

### ⚙️ 5.5. Hướng Dẫn Cấu Hình MCP Cho Antigravity / Cursor

1. Đảm bảo máy tính đã cài Python 3.10+ (hoặc trỏ tới đường dẫn Python trên máy bạn).
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

3. Khởi động plugin trong Godot: AI Agent bên ngoài sẽ tự động nhận diện cây Scene Tree đang mở, hỗ trợ tạo Node, kiểm tra lỗi LSP thời gian thực và đồng hành cùng bạn!


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
