# NemiVision — Changelog

All notable changes to this project will be documented in this file.
Commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/) format:
`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `ci:`

---

## v1.0.0 — 2026-06-06

### ✨ Features
- feat: initial LiDAR 3D point cloud capture with ARKit
- feat: Metal GPU renderer with RGB and depth-rainbow colour modes
- feat: gallery screen with PLY / XYZ / OBJ export
- feat: 3D capture viewer with auto-fit zoom and centroid centering
- feat: rename captures with in-sheet text dialog
- feat: delete captures with confirmation from export sheet
- feat: share PLY, XYZ, OBJ files from gallery and 3D viewer
- feat: capture count badge on gallery button
- feat: point size slider (1–10 px) in live view and capture viewer
- feat: background colour toggle (dark navy / pure black)
- feat: scan mode — long-press capture button to accumulate frames
- feat: scan density boost — 3-frame rolling composite in live view
- feat: Metal-rendered thumbnail snapshot after viewing a capture
- feat: rename app to NemiVision, update icon

### 🔧 Infrastructure & Maintenance
- chore: add GitHub Actions automated release workflow
- chore: add local release notes generator script
- chore: add Excalidraw architecture diagrams (system, data flow, screen flow)

### 👥 Contributors
- Sathishkumar C <Sathishkumar.c@bncmotors.in>

---

*For older entries, see git log.*
