<div align="right">

[한국어](README.ko.md) | **English**

</div>

# Glacier

A compact macOS menu bar manager that hides menu bar items in a small Swift codebase.

[Ice](https://github.com/jordanbaird/Ice) is great, but it's 30,000+ lines with its own settings window, update framework, and accessibility layer. Glacier is a small menu bar app focused on the core job: hide, show, done.

> This README describes the repository's current shipping behavior.
> For an implementation review, see [the Korean code evaluation](docs/code-evaluation.ko.md). For the target product direction, see [the Korean product behavior PRD](docs/product-behavior-prd.ko.md). For document roles, see [the Korean document map](docs/document-map.ko.md).

## Glacier vs Ice

| | Glacier | Ice |
|---|---------|-----|
| Lines of code | Small (core Swift sources) | 30,000+ |
| Dependencies | 0 | Multiple |
| Accessibility layer | None | Included |
| App size | A few MB | ~15 MB |
| Sections | 2 (hidden stash / visible) + one control | 3 |
| macOS 26 Tahoe | Works | [Known issues](https://github.com/jordanbaird/Ice/issues/867) |
| Separate settings window | None | Full settings window |

## How It Works

Glacier places a compact **three-dots** control (**⋯**) and an invisible separator in your menu bar. When collapsed, the separator pushes everything to the left of **⋯** off-screen; one click expands to show **all** of those icons together. Closed: solid dark dots; expanded: compact white pill with thicker dots (black ring, white center).

```
[Hidden icons] ⋯ [Visible icons]
```

| Marker | Role |
|--------|------|
| **⋯** | Click — show or hide every icon to the left of the control |

## Quick Start

After launching Glacier, you'll see a small **⋯** (three dots) in your menu bar. That's your control point.

### 1. Organize your menu bar

Use **Cmd + Drag** to place **⋯** and the invisible separator: everything **left of ⋯** is tucked away until you click **⋯**.

```
[Hidden icons] ⋯ [Visible icons]
                    ↑
              drag this (and the separator)
```

- Items **right of ⋯** → always visible in the bar
- Items **left of ⋯** → hidden together; click **⋯** to slide them in or out

### 2. Control visibility

| Action | Effect |
|--------|--------|
| **Click ⋯** | Show or hide all icons to the left of ⋯ |
| **Option + Click ⋯** | Same as a normal click |
| **Esc** | Collapse when Glacier has keyboard focus (menu bar utility; otherwise click **⋯** or use the 60 s timeout) |
| **60 s idle** | While expanded (not editing), the strip collapses automatically |
| **Right-click ⋯** | Usage / Edit Layout / Reset Layout / Quit |

## Current Notes

- `Edit Layout` keeps the strip expanded while you `Cmd + Drag` **⋯** and the separator.
- `Reset Layout` restores **⋯** and the separator to their default positions.

## Install

### Homebrew

```bash
brew tap junuMoon/tap
brew install --cask --no-quarantine glacier
```

### Download

Download the latest `.zip` from [Releases](../../releases), unzip, and drag `Glacier.app` to `/Applications`.

### Build from Source

Requires Xcode 16+ and macOS 15+.

```bash
git clone https://github.com/junuMoon/Glacier.git
cd Glacier
xcodebuild -scheme Glacier -configuration Release build
```

## Requirements

- macOS 15.0 (Sequoia) or later

## License

MIT
