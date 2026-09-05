# Gridded

![example workflow](https://github.com/gentlespoon/gridded/actions/workflows/build.yml/badge.svg)

[⬇️ Download - for macOS 14.0+ (universal)](https://github.com/gentlespoon/Gridded/releases/latest)

**Gridded** is a modern window management app for macOS that brings powerful, grid-based window snapping to your desktop. With a focus on simplicity and speed, Gridded lets you quickly and intuitively layout windows using just your mouse or keyboard.

Unlike traditional window managers that restrict you to binary splits or fixed quadrants, **Gridded empowers you to create dynamic layouts** on a customizable grid. Effortlessly span a window across multiple grid cells — combine, stack, or size windows exactly how you want, all on the fly.

<img src="demo.gif" width="100%" />

### How It Works

- **Right-click while dragging** a window to enter snapping mode.
- **Or, hold down the Space key** (ideal for trackpads) to activate snapping.
- Once activated, simply drag to select a region of the grid — your window will snap to fill the selected cells.

This gives new utility to an otherwise unused gesture — right-clicking while moving — and opens up a new level of control and fluidity in window management.

_Gridded is in early development and may still be unstable. Feedback and testing are appreciated!_

### Features

- Customizable grid dimensions (rows and columns)
- Multi-screen support
- Preview overlay

#### Custom layouts

Open **Preferences → Layouts** to create, duplicate, and select named layouts.
Each column (left to right) and row (top to bottom) can use **Equal share** or a
**Fixed size** in macOS points. Equal shares divide the space remaining after
fixed sizes. For example, on a usable workspace 3840 points wide, columns set to
Equal share, Equal share, and Fixed size 906 resolve to 1467, 1467, and 906.

Choose a preview display to see its usable workspace and calculated sizes. Use
the arrow buttons to reorder entries, then **Save Layout** to apply edits or
**Revert** to discard them. Selecting a saved layout activates it globally;
its dimensions are calculated separately for each display. Keep at least one
Equal share per axis. If a display is too small for a layout's fixed sizes,
snapping falls back to equal cells on that display. The Dock and menu bar are
excluded from the workspace. Existing grid preferences become the Default layout.

Geometry checks can be run without Xcode:

```sh
swiftc Gridded/GridLayout.swift Tests/GridLayoutTests.swift -o /tmp/gridded-layout-tests
/tmp/gridded-layout-tests
```

### Work In Progress

-

### Known Issue

- Revoking accessibility permission while the app is running may freeze the computer.
- If window is moved (without resize) the operation may not be honored by Accessibility.

### Requirements

- macOS 14.0 or later
- Xcode 16.0 or later (for development)

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

MIT Licensed
