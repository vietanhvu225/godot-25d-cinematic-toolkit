# 🎮 Godot 2.5D Cinematic Platformer Toolkit (INSIDE-Style)

🌐 **English** | [Tiếng Việt](README.vi.md)

[![Godot Version](https://img.shields.io/badge/Godot-4.7%2B-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![MCP Protocol](https://img.shields.io/badge/MCP-Antigravity%20%2F%20Cursor%20Ready-purple.svg)](#-mcp-ecosystem--ai-pair-programming-antigravity--cursor)
[![Clean Room](https://img.shields.io/badge/Design-Clean--Room%20Reimplementation-blue.svg)](https://github.com/vietanhvu225/inside-engine-deconstruction)

> **A complete framework for building 2.5D cinematic puzzle-platformers in Godot 4.7+.**  
> Aims to recreate the controls, procedural animation, cinematic camera and signature lighting of *INSIDE / LIMBO / Little Nightmares*, with an optional AI-agent workflow over the **Model Context Protocol (MCP)**.

---

## 📌 TABLE OF CONTENTS
1. [Quickstart on Any Machine](#-quickstart-on-any-machine)
2. [Input Controls](#-input-controls)
3. [Overview of the 6 Core Technical Modules](#-overview-of-the-6-core-technical-modules)
4. [The 3 "Playdead Look" Shaders](#-the-3-playdead-look-shaders)
5. [MCP Ecosystem & AI Pair-Programming (Antigravity / Cursor)](#-mcp-ecosystem--ai-pair-programming-antigravity--cursor)
6. [Project Structure](#-project-structure)
7. [Companion Technical Docs](#-companion-technical-docs)


---

## 🚀 QUICKSTART ON ANY MACHINE

This is a **standalone Godot project** with no paid plugins or complex runtime dependencies. Clone it onto any machine (Windows, macOS, Linux) and run it right away:

### 1. Get the engine:
* Download [Godot Engine 4.7+ (Standard Version)](https://godotengine.org/download). The .NET/C# build is not required.

### 2. Get the source:
```bash
git clone https://github.com/vietanhvu225/godot-25d-cinematic-toolkit.git
cd godot-25d-cinematic-toolkit
```

### 3. Open & run:
1. Open Godot Engine, click **Import**, point it at the cloned folder and select `project.godot`.
2. Press **Play (F5)** in the top-right corner (or open the scene [`scenes/test_gym.tscn`](scenes/test_gym.tscn)).
3. Try out the physics test gym, featuring:
   - A character jumping over gaps and gripping slopes with Raycast Foot IK.
   - Pushing/pulling physics boxes.
   - A Cinematic Camera Blend Box zone ($32^\circ \leftrightarrow 42^\circ$ FOV).

---

## 🕹️ INPUT CONTROLS

| Action | Keyboard | Gamepad | Mechanics |
| :--- | :--- | :--- | :--- |
| **Move Left/Right** | `A` / `D` or `←` / `→` | D-Pad / Left Stick | Hard-locked to $Z=0.0$, with acceleration/friction-based inertia. |
| **Jump** | `Space` or `W` / `↑` | `A` (Xbox) / `✕` (PS) | $5.2\text{m/s}$ jump velocity, with Coyote Time ($120\text{ms}$) & Buffer ($150\text{ms}$). |
| **Sprint** | Hold `Shift` | `Left Trigger` / `L3` | Speeds up from $2.7\text{m/s}$ (walk) to $4.0\text{m/s}$ (sprint). |
| **Push / Pull box (Drag)** | Hold `E` or `Ctrl` next to a box | `X` (Xbox) / `▢` (PS) | Automatically drops speed to $1.3\text{m/s}$ to convey the weight of the box. |

---

## 🧩 OVERVIEW OF THE 6 CORE TECHNICAL MODULES

All logic is split into highly modular GDScript scripts that drop easily into any 2.5D game.

> ℹ️ **About the numbers:** the values in this README match the defaults in the scripts (`@export` variables you can tune in the Inspector). Every value (speeds, forces, timings, masses) is this toolkit's own tuning target, estimated to approximate the feel of INSIDE. They are **not** values extracted from the original game. See the [verification status](https://github.com/vietanhvu225/inside-engine-deconstruction#-verification-status) of the research repo.

### 1. 2.5D Character Controller ([`scripts/player/inside_player_controller_25d.gd`](scripts/player/inside_player_controller_25d.gd))
- Strictly constrains movement to the 2.5D plane ($Z = 0$).
- **Playdead-style physics tuning:** ground acceleration $18.0\text{ m/s}^2$, friction $22.0$, air acceleration $9.0$.
- **Gravity weighting:** gravity is multiplied by $\times 1.35$ while falling to give jumps weight, and reduced ($0.6\times$) at the apex (Apex Damping) for a floaty hang time.

### 2. Procedural IK & Stumble ([`scripts/player/procedural_ik_and_stumble.gd`](scripts/player/procedural_ik_and_stumble.gd))
- **Foot IK:** two raycasts probe the ground under the feet to raise and lower each foot on slopes and stairs.
- **Hand-Snapping:** when running close to a wall or obstacle, the character reaches out and lightly touches the surface.
- **Stumble:** detects hard landings from height ($v_y < -10.5\text{m/s}$; below $-17.5\text{m/s}$ is a fatal fall) and triggers a stumble/knee-buckle state.

### 3. Hound / Dog Guard AI ([`scripts/ai/dog_guard_ai_25d.gd`](scripts/ai/dog_guard_ai_25d.gd))
- **Dual senses:** a $65^\circ$ vision cone ($14\text{m}$ range when lit, $4\text{m}$ in darkness) combined with footstep hearing (radius $3.5\text{m} - 13.0\text{m}$).
- **Pincer Steering:** the pack leader chases directly while followers run ahead to cut off the player $4.5\text{m}$ in front.
- **Pounce Leap:** pauses for $0.22\text{s}$, then launches with a $9.0\text{m/s}$ impulse to knock the player down.

### 4. Undulating Water Creature & Light Reaction ([`scripts/ai/water_creature_and_light.gd`](scripts/ai/water_creature_and_light.gd))
- Simulates sinuous swimming with an 8-segment bone chain (Verlet Kinematics).
- Light-avoidance state machine: when hit by a `SpotLight3D` beam, the creature writhes and retreats at $4.2\text{m/s}$ into darkness; when the light goes off, it lunges into an ambush at $7.8\text{m/s}$.

### 5. The Huddle Soft-Body ([`scripts/physics/huddle_softbody_controller.gd`](scripts/physics/huddle_softbody_controller.gd))
- Simulates a $480\text{kg}$ deformable flesh mass with a network of 12 radial springs.
- Shifting the center of mass ($0.45\text{m}$) produces a $6200\text{N}\cdot\text{m}$ self-rolling torque; it automatically reaches out to grip the floor and smashes through barrier walls when kinetic energy reaches $\ge 2600\text{J}$.

### 6. Cinematic Camera & Level Streaming
- [`scripts/camera/cinematic_camera_trigger.gd`](scripts/camera/cinematic_camera_trigger.gd): trigger zones for smooth camera transitions (FOV changes, Z distance and locked static camera axes).
- [`scripts/systems/level_streaming_manager.gd`](scripts/systems/level_streaming_manager.gd): multithreaded preloading of sub-levels at $35\text{m}$ and unloading at $55\text{m}$, designed to avoid frame hitches during level transitions.

---

## 🎨 THE 3 "PLAYDEAD LOOK" SHADERS

1. [`shaders/playdead_palette.gdshader`](shaders/playdead_palette.gdshader): maps grayscale onto a 1D gradient palette (Palette LUT) for the signature dark, cold tones.
2. [`shaders/fake_bounce_light.gdshader`](shaders/fake_bounce_light.gdshader): fakes indirect light bouncing off the floor onto the character's lower body without the cost of global illumination (GI).
3. [`shaders/volumetric_fog_dither.gdshader`](shaders/volumetric_fog_dither.gdshader): volumetric fog with 4x4 Bayer-matrix dithering to eliminate color banding in dark areas.

---

## 🤖 MCP ECOSYSTEM & AI PAIR-PROGRAMMING (ANTIGRAVITY / CURSOR)

This toolkit is designed around **AI-Native Game Development**: developers work side by side with AI agents (Google Antigravity, Cursor, Claude Code) through the open **Model Context Protocol (MCP)**.

> ℹ️ **MCP is optional.** The game runs without it. The MCP addon (`gamedev_ai`) is **not bundled** in this repo; install it yourself by following [5.5](#-55-configuring-mcp-for-antigravity--cursor) if you want AI-agent integration.
>
> The tool comparison below reflects a survey done in October 2026. Version support, tool counts and features change quickly, so check each project's own docs before relying on them.

### 🔍 5.1. How the MCP Solution Was Chosen

To find the best option for Godot 4.7+, we ran an in-depth survey in two rounds of screening:

* **Round 1 (GitHub ecosystem scan):** surveyed popular standalone MCP repos (`Coding-Solo/godot-mcp`, `hi-godot/godot-ai`, `ee0pdt/Godot-MCP`, `IvanMurzak/Godot-MCP`). Most only supported older Godot 4.2/4.3, lacked authentication, or had no interactive UI inside the Editor.
* **Round 2 (Official Godot Asset Library deep-dive):** scanned the reviewed tools on the Godot Asset Library (#5086, #5375, #5369, #5193, #5482, #5522). Found a newer generation of tools with much better Godot 4.7+ compatibility, safety and debugging.

---

### 📊 5.2. ROUND 2 VS. ROUND 1 CANDIDATES

| Technical criterion | `fredarts/gamedev_ai` (#5086) ⭐ | `NPGameDev/godot-mcp-toolkit` (#5375) | `TomasLucas/godot-mcp-bridge` (#5369) | `wgt19861219/godot-mcp-enhanced` (#5193) | `hi-godot/godot-ai` (Round 1) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Godot 4.7.2 compatibility** | **⭐⭐⭐⭐⭐ (Native 4.7+)** | ⭐⭐⭐⭐☆ (4.2+) | ⭐⭐⭐⭐☆ (4.5+) | ⭐⭐⭐⭐☆ (4.3+) | ⭐⭐⭐⭐☆ (4.3+) |
| **Reviewed on Asset Library** | **✅ Yes (ID 5086)** | **✅ Yes (ID 5375)** | **✅ Yes (ID 5369)** | **✅ Yes (ID 5193)** | ❌ No (GitHub only) |
| **Integrated Editor UI** | **✅ AI Dock + Visual Diff** | ❌ No (pure MCP) | ❌ No (pure MCP) | ⚠️ Minimal dock | ⚠️ Status dock only |
| **Step-debugging** | ⚠️ Reads console log | ⚠️ Reads console log | **✅ DAP breakpoints** | ⚠️ QA Assertions & GIF | ⚠️ Reads console log |
| **LLM token efficiency** | ⭐⭐⭐⭐☆ (30+ tools) | ⭐⭐⭐☆☆ (150+ tools) | ⭐⭐⭐☆☆ (231 tools) | ⭐⭐⭐⭐☆ (46 tools/272 actions) | **⭐⭐⭐⭐⭐ (Domain Rollups)** |
| **Explicit Antigravity support** | **✅ Named in docs** | ✅ General compatibility | ✅ General compatibility | ✅ General compatibility | ✅ General compatibility |
| **Architectural focus** | **Authoring + Safe Diff + Watch Mode** | Pure MCP Operations | Bi-directional Awareness + DAP | Closed-Loop QA + Auto GIF | Token-optimized Viewport |

---

### 🎯 5.3. Rationale: Why `fredarts/gamedev_ai` (#5086) Is the Core Choice

1. **100% version match (Godot 4.7+):** one of the few Asset Library tools officially tagged for **Godot 4.7+**, with no deprecation warnings from the new GDScript.
2. **Official Google Antigravity & Cursor support:** the author's docs describe a standard stdio bridge via the Python file `godot_mcp.py`, connecting directly to an internal JSON-RPC server on port `6543`.
3. **The safest "Dual-Workspace" model:**
   - **Outside:** Antigravity can create nodes, connect signals and edit scripts within a selection automatically.
   - **Inside:** Godot shows a **Safe Visual Diff** panel (green/red) so you can `Accept` or `Reject` changes before they apply, plus a **Watch Mode** that catches crashes in the Output tab and proposes fixes immediately.

---

### 🛡️ 5.4. Companion Git & LFS Tool: `Gitot` (Asset #5522)

During the survey we analysed [**`SigKdev/godot-gitot`**](https://github.com/SigKdev/godot-gitot) ([Godot Asset Library #5522](https://godotengine.org/asset-library/asset/5522)) and identified it as a **critical version-control piece** for game development on Godot 4.7.2:

#### 1. The problem with Godot's default VCS:
* Godot ships with built-in Git (`godot-git-plugin`), but it is based on the C++ library `libgit2`. The plugin is known to crash or lose its connection whenever Godot updates, and configuring SSH keys on Windows is painful.
* **Gitot's approach:** written in **100% pure GDScript**, it calls the OS `git.exe` directly via `OS.execute()`. If `git` works in your terminal, Gitot works immediately with no SSH or token reconfiguration.

#### 2. Five lifesaving features for game developers & AI workflows:
1. **Large-File Guard & automatic Git LFS:** game devs often drag in heavy 3D files (`.blend`, `.obj`), audio (`.wav`) or textures of $50\text{MB} - 500\text{MB}$. Gitot blocks commits of files over a set threshold into regular Git (so the repo doesn't balloon) and offers a 1-click **"Track with LFS"** button.
2. **Real-time color diff gutter:** the left gutter of Godot's script editor changes color, **green** for newly written lines and **orange** for lines the AI just edited. Click a marker to open a detailed unified diff.
3. **Branch Switch Auto-Reload:** when switching between feature branches, open scene files (`.tscn`) reload to the new state without restarting Godot.
4. **Stash Manager (Shelf):** shelve all of the AI's experimental changes safely in one click.
5. **Proven reliability:** v0.17.0 was built and tested directly on **Godot 4.7.2** and passes the [GdUnit4](https://github.com/MikeSchulze/gdUnit4) automated suite with **22 test suites, 179 tests, 0 failures**.

> [!TIP]
> **Recommended setup for this project:**
> - **Coding & AI control (MCP):** [`fredarts/gamedev_ai`](https://github.com/fredarts/gamedev_ai) (connects to Antigravity on port `6543`).
> - **Source control & size protection (VCS):** [`SigKdev/godot-gitot`](https://github.com/SigKdev/godot-gitot) (commits, LFS and diffs right inside Godot).

---

### ⚙️ 5.5. Configuring MCP for Antigravity / Cursor

1. **Install the addon (not included in this repo):** in Godot, open the **AssetLib** tab, search for `gamedev_ai` ([Asset #5086](https://godotengine.org/asset-library/asset/5086)), download it and install into `addons/gamedev_ai/`. Then enable it under **Project → Project Settings → Plugins**. Check that `addons/gamedev_ai/mcp/godot_mcp.py` exists; if the addon's layout differs, adjust the path in the config below.
2. Make sure Python 3.10+ is installed (or point to the Python path on your machine).
3. Open your IDE's MCP config file (e.g. `mcp_config.json`):

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

4. With the plugin running in Godot, the external AI agent can read the open Scene Tree, help create nodes and check LSP errors in real time.


---

## 📂 PROJECT STRUCTURE

```text
godot-25d-cinematic-toolkit/
├── project.godot                  # Godot 4.7 engine config
├── mcp_config.json                # MCP config for AI agents (needs the optional gamedev_ai addon, not bundled)
├── scenes/
│   └── test_gym.tscn              # Physics & camera test level
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

## 📚 COMPANION TECHNICAL DOCS

- 📖 [**INSIDE Advanced Systems Bible**](docs/INSIDE_ADVANCED_SYSTEMS_BIBLE.md): all the math formulas, Mermaid sequence diagrams and an explanation of every physics coefficient.
- 📖 [**Godot MCP Comprehensive Analysis**](docs/GODOT_MCP_COMPREHENSIVE_ANALYSIS.md): comparative evaluation of MCP solutions (gamedev_ai, godot-mcp-enhanced, gitot).
- 🔬 [**Original Reverse Engineering Archive (Repo 1)**](https://github.com/vietanhvu225/inside-engine-deconstruction): binary teardown results and decoded PlayMaker FSMs from the original game.

> Note: the companion docs are currently written in Vietnamese.

---
*Developed and maintained by vietanhvu225. MIT License: free for personal and commercial use.*
