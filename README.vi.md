# 🎮 Godot 2.5D Cinematic Platformer Toolkit (INSIDE-Style)

🌐 [English](README.md) | **Tiếng Việt**

[![Godot Version](https://img.shields.io/badge/Godot-4.7%2B-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![MCP Protocol](https://img.shields.io/badge/MCP-Antigravity%20%2F%20Cursor%20Ready-purple.svg)](#-hệ-sinh-thái-mcp--ai-pair-programming-antigravity--cursor)
[![Clean Room](https://img.shields.io/badge/Design-Clean--Room%20Reimplementation-blue.svg)](https://github.com/vietanhvu225/inside-engine-deconstruction)

> **Bộ khung làm game phiêu lưu giải đố 2.5D điện ảnh (Cinematic Puzzle-Platformer) hoàn chỉnh cho Godot 4.7+.**  
> Hướng tới tái hiện phong cách điều khiển, hoạt ảnh thủ tục (Procedural Animation), camera điện ảnh và ánh sáng đặc trưng của *INSIDE / LIMBO / Little Nightmares*, kèm quy trình hỗ trợ AI Agent (tùy chọn) qua **Model Context Protocol (MCP)**.

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
| **Di chuyển Trái/Phải** | `A` / `D` hoặc `←` / `→` | D-Pad / Cần Left Stick | Khóa cứng trục $Z=0.0$, quán tính theo gia tốc/ma sát. |
| **Nhảy (Jump)** | `Space` hoặc `W` / `↑` | Nút `A` (Xbox) / `✕` (PS) | Lực nhảy $5.2\text{m/s}$, hỗ trợ Coyote Time ($120\text{ms}$) & Buffer ($150\text{ms}$). |
| **Chạy nước rút (Sprint)** | Giữ `Shift` | Nút `Left Trigger` / `L3` | Tăng tốc từ $2.7\text{m/s}$ (đi bộ) lên $4.0\text{m/s}$ (nước rút). |
| **Kéo / Đẩy hộp (Drag)** | Giữ `E` hoặc `Ctrl` cạnh hộp | Nút `X` (Xbox) / `▢` (PS) | Tự động hạ tốc độ còn $1.3\text{m/s}$ để thể hiện sức nặng của hộp. |

---

## 🧩 TỔNG QUAN 6 MODULE KỸ THUẬT CHUYÊN SÂU

Toàn bộ logic được chia thành các script GDScript mô-đun hóa cao, dễ dàng nhúng vào bất kỳ game 2.5D nào.

> ℹ️ **Về các con số:** các giá trị trong README này khớp với giá trị mặc định trong script (biến `@export`, chỉnh được trong Inspector). Mọi giá trị (vận tốc, lực, thời gian, khối lượng) là giá trị tuning mục tiêu của chính toolkit, ước lượng để gần với cảm giác chơi INSIDE. Chúng **không** được trích xuất từ game gốc. Xem [trạng thái xác minh](https://github.com/vietanhvu225/inside-engine-deconstruction/blob/HEAD/README.vi.md#-trạng-thái-xác-minh) của repo nghiên cứu.

### 1. 2.5D Character Controller ([`scripts/player/inside_player_controller_25d.gd`](scripts/player/inside_player_controller_25d.gd))
- Khóa chuyển động nghiêm ngặt trên mặt phẳng 2.5D ($Z = 0$).
- **Physics Tuning chuẩn Playdead:** Gia tốc mặt đất $18.0\text{ m/s}^2$, lực cản ma sát $22.0$, gia tốc trên không $9.0$.
- **Gravity Weighting:** Nhân trọng lực $\times 1.35$ khi rơi xuống giúp cú nhảy có sức nặng; giảm trọng lực ($0.6\times$) ở đỉnh nhảy (Apex Damping) tạo cảm giác bay lơ lửng.

### 2. Procedural IK & Stumble ([`scripts/player/procedural_ik_and_stumble.gd`](scripts/player/procedural_ik_and_stumble.gd))
- **Foot IK:** 2 tia Raycast quét mặt sàn dưới chân để tự động nâng hạ bàn chân theo dốc hoặc bậc thang.
- **Hand-Snapping:** Khi chạy sát mép tường hoặc chướng ngại vật, nhân vật tự vươn tay chạm nhẹ vào bề mặt.
- **Stumble:** Tự động phát hiện va chạm tiếp đất từ độ cao lớn ($v_y < -10.5\text{m/s}$; dưới $-17.5\text{m/s}$ là rơi tử vong) để kích hoạt trạng thái lảo đảo/khụy chân.

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
- [`scripts/systems/level_streaming_manager.gd`](scripts/systems/level_streaming_manager.gd): Quản lý nạp trước màn chơi con ngầm đa luồng ở cự ly $35\text{m}$ và giải phóng ở cự ly $55\text{m}$, nhằm tránh hiện tượng khựng khung hình khi chuyển vùng.

---

## 🎨 BỘ 3 SHADERS THẨM MỸ "PLAYDEAD LOOK"

1. [`shaders/playdead_palette.gdshader`](shaders/playdead_palette.gdshader): Ánh xạ ảnh thang độ xám (Grayscale) sang bảng màu gradient 1D (Palette LUT), mang lại tông màu u tối, lạnh lẽo đặc trưng.
2. [`shaders/fake_bounce_light.gdshader`](shaders/fake_bounce_light.gdshader): Giả lập tia sáng gián tiếp hắt ngược từ mặt sàn lên phần dưới cơ thể nhân vật mà không tốn chi phí chiếu sáng toàn cục (GI).
3. [`shaders/volumetric_fog_dither.gdshader`](shaders/volumetric_fog_dither.gdshader): Sương mù thể tích kèm ma trận Bayer 4x4 dither giúp loại bỏ triệt để hiện tượng vệt sọc màu (Color Banding) trong bóng tối.

---

## 🤖 HỆ SINH THÁI MCP & AI PAIR-PROGRAMMING (ANTIGRAVITY / CURSOR)

Bộ công cụ này được thiết kế theo tư duy **AI-Native Game Development**: lập trình viên phát triển song hành cùng AI Agent (Google Antigravity, Cursor, Claude Code) thông qua giao thức mở **Model Context Protocol (MCP)**.

> ℹ️ **MCP là tùy chọn.** Game vẫn chạy bình thường khi không có MCP. Addon MCP (`gamedev_ai`) **không được đóng gói sẵn** trong repo; nếu muốn tích hợp AI Agent, hãy tự cài theo [mục 5.5](#-55-hướng-dẫn-cấu-hình-mcp-cho-antigravity--cursor).
>
> Bảng so sánh bên dưới phản ánh khảo sát tháng 10/2026. Phiên bản hỗ trợ, số lượng tool và tính năng thay đổi nhanh, hãy kiểm tra tài liệu của từng dự án trước khi dựa vào.

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

### 🛡️ 5.4. Công Cụ Đồng Hành Quản Trị Git & LFS: `Gitot` (Asset #5522)

Trong quá trình khảo sát, chúng tôi phân tích công cụ [**`SigKdev/godot-gitot`**](https://github.com/SigKdev/godot-gitot) ([Godot Asset Library #5522](https://godotengine.org/asset-library/asset/5522)) và xác định đây là **mảnh ghép quản trị phiên bản tối quan trọng** khi làm game trên Godot 4.7.2:

#### 1. Bản chất & Nỗi đau của Godot VCS mặc định:
* Godot có hệ thống Git tích hợp sẵn (`godot-git-plugin`), nhưng dựa trên thư viện C++ `libgit2`. Plugin này nổi tiếng là thường xuyên bị crash hoặc hỏng kết nối mỗi khi Godot ra bản cập nhật mới, đồng thời việc cấu hình SSH Key trên Windows rất phức tạp.
* **Giải pháp của Gitot:** Viết bằng **100% thuần GDScript (Pure GDScript)**, tương tác thẳng với file `git.exe` của hệ điều hành thông qua lệnh `OS.execute()`. Do đó, nếu terminal trên máy bạn gõ được lệnh `git`, Gitot sẽ chạy ngay lập tức mà không cần cấu hình lại SSH hay token.

#### 2. Bộ 5 tính năng "cứu cánh" cho Game Developer & AI Workflow:
1. **Large-File Guard & Git LFS tự động:** Khi làm game, dev thường kéo thả các file 3D (`.blend`, `.obj`), âm thanh (`.wav`) hoặc texture nặng từ $50\text{MB} - 500\text{MB}$. Gitot có cơ chế tự động chặn không cho commit file vượt ngưỡng quy định vào Git thường (tránh làm nổ dung lượng repo), đồng thời cung cấp nút **"Track with LFS"** 1-click.
2. **Color Diff Gutter thời gian thực:** Lề trái của trình soạn thảo mã nguồn Godot (Gutter) tự động đổi màu: **xanh lá** cho dòng mới viết, **cam** cho dòng AI vừa sửa. Bấm vào vạch màu là mở ngay bảng so sánh Unified Diff chi tiết.
3. **Chuyển nhánh tự động làm mới Scene (Branch Switch Auto-Reload):** Khi chuyển đổi qua lại giữa các branch tính năng, các file Scene (`.tscn`) đang mở sẽ tự động nạp lại trạng thái mới mà không bắt buộc bạn phải khởi động lại Godot.
4. **Stash Manager (Shelf):** Cho phép "cất nháp" toàn bộ thay đổi thử nghiệm của AI vào ngăn kéo an toàn chỉ với 1 cú click.
5. **Độ tin cậy được kiểm chứng:** Phiên bản v0.17.0 được xây dựng và kiểm thử trực tiếp trên đúng bản **Godot 4.7.2**, vượt qua bộ test tự động [GdUnit4](https://github.com/MikeSchulze/gdUnit4) với **22 test suites, 179 tests, 0 failures**.

> [!TIP]
> **Mô hình phối hợp chuẩn mực cho dự án:**
> - **Lập trình & Điều khiển AI (MCP):** [`fredarts/gamedev_ai`](https://github.com/fredarts/gamedev_ai) (Kết nối Antigravity qua cổng `6543`).
> - **Quản trị mã nguồn & Bảo vệ dung lượng (VCS):** [`SigKdev/godot-gitot`](https://github.com/SigKdev/godot-gitot) (Quản trị commit, LFS và diff trực tiếp trong Godot).

---

### ⚙️ 5.5. Hướng Dẫn Cấu Hình MCP Cho Antigravity / Cursor

1. **Cài addon (không có sẵn trong repo):** trong Godot, mở tab **AssetLib**, tìm `gamedev_ai` ([Asset #5086](https://godotengine.org/asset-library/asset/5086)), tải về và cài vào `addons/gamedev_ai/`. Sau đó bật plugin tại **Project → Project Settings → Plugins**. Kiểm tra file `addons/gamedev_ai/mcp/godot_mcp.py` có tồn tại; nếu cấu trúc addon khác, hãy sửa đường dẫn trong cấu hình bên dưới.
2. Đảm bảo máy tính đã cài Python 3.10+ (hoặc trỏ tới đường dẫn Python trên máy bạn).
3. Mở file cấu hình MCP của IDE (ví dụ: `mcp_config.json`):

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

4. Khi plugin đang chạy trong Godot, AI Agent bên ngoài có thể đọc cây Scene Tree đang mở, hỗ trợ tạo Node và kiểm tra lỗi LSP theo thời gian thực.


---

## 📂 CẤU TRÚC THƯ MỤC DỰ ÁN

```text
godot-25d-cinematic-toolkit/
├── project.godot                  # File cấu hình engine Godot 4.7
├── mcp_config.json                # Cấu hình MCP cho AI Agent (cần addon gamedev_ai tùy chọn, không đóng gói sẵn)
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
