# 🏛️ Studio Architecture & Prototyping Research

A deep-dive research synthesis of indie game studio engineering postmortems, GDC talks, and Godot 4 modular architecture patterns.

---

## 1. Modular Game Architecture

### Supergiant Games (*Hades*)
- **Primary Source Video**: 🎬 [Noclip: Hades Developing Hell Documentary Series](https://www.youtube.com/playlist?list=PL-THgg8QnvU4JEVov1tMlFThNYS92F8uC)
- **Proprietary Engine:** Built in C/C++, prioritizing multi-threading, cross-platform performance, and custom tooling over generic engine features.
- **Event-Driven System:** Decoupled gameplay state from storytelling. The narrative system independently "peeks" at player variables (health, deaths, specific encounters) to trigger dialogue.

### Heart Machine (*Hyper Light Drifter*)
- **Primary Source Talk**: 🎬 [Hyper Light Drifter Level Design - GDC Talk](https://www.youtube.com/watch?v=9_L5X0U8NqA)
- **Custom Editor Tooling:** Built in GameMaker Studio, using Photoshop layer import scripts to design levels with organic shapes outside rigid tile grids.
- **Visual Logic Decoupling:** Used Z-order sorting and flat color blocks for collision, separating rigid collision logic from aesthetic presentation.

### Radical Fish Games (*CrossCode*)
- **Primary Source Blog**: 📄 [Radical Fish Games Devblog & Postmortem](https://www.cross-code.com/en/blog)
- **Engine Overhaul:** Rewrote ~95% of Impact.js (HTML5/JS) to handle top-down 3D-style collisions and Action RPG mechanics.
- **Performance Decoupling:** Heavy refactoring of data structures to prevent JS V8 engine polymorphism bottlenecks during intense elemental spell FX.

### Godot 4 Modular Patterns
- **Primary Source Doc**: 📄 [Godot 4 Best Practices Guide](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- **Composition Over Inheritance:** Avoid deep class hierarchies. Use independent node components (e.g., `HealthComponent`, `Hitbox`) and lightweight `Resource` files for shared stats.
- **Signal-Based Decoupling:** Follow the **"Call Down, Signal Up"** rule. Children emit signals; parents call methods. Use an Autoload Event Bus (`GameState.gd`) for global communication.

---

## 2. Vertical Slice Prototyping

### Motion Twin (*Dead Cells*)
- **Primary Source Talk**: 🎬 [Dead Cells: What the F*n!? - GDC Talk](https://www.youtube.com/watch?v=vVj_L04K9h0)
- **Primary Source Article**: 📄 [The Anatomy of Game Juice](https://www.gamedeveloper.com/design/the-anatomy-of-game-juice)
- **Iterative Pivot:** The game started as a mobile tower-defense title before pivoting entirely to a hardcore 2D action game.
- **Asset Pipeline as a Slice:** Exported 3D model animations as 2D pixel art sprite sheets to maintain high quality without bottlenecking prototyping.
- **Game Feel Mechanics:** Rapidly iterated on coyote time, 0.03s hit-pause frames, and dynamic hitboxes.

---

## 3. Automated Verification & Agentic Playtest Loops (Godot 4)

- **Primary Source Doc**: 📄 [Godot 4 Command Line Tutorial & Headless CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- **Headless Execution:** Godot 4 runs tests in CI/CD without rendering using the `--headless` flag (`godot --headless --path . --script scripts/bot_playtest_boss.gd`).
- **Input Decoupling:** Decouple physical input from game logic. Both the player controller (`_unhandled_input`) and automated test runner call identical verb functions (`_execute_attack`), enabling test bots to execute exact player code paths.
