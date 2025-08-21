# SecondLife

A tiny World of Warcraft addon that displays your **remaining health percentage** in a clean, movable window. The bar **shrinks from left → right ** as you lose health, and its color smoothly transitions **Green → Yellow → Red** based on your current HP.


---

## Features

- **Health % at a glance** — big, readable number.
- **Left-to-right health bar** — the colored background shrinks from the right as HP drops.
- **Smart color gradient** — green (full) → yellow → red (low).
- **Always on top of the bar** — percent text overlays the color fill for clarity.
- **Movable & simple** — drag the frame when unlocked; thin border, no clutter.
- **Slash commands** — quick control without menus.
- **Lightweight** — updates only on health-relevant events.

---

## Installation

1. Download or clone this repository.
2. Create the addon folder:
   ```
   [World of Warcraft Path]/_retail_/Interface/AddOns/SecondLife/
   ```
3. Place the files inside that folder:
   - `SecondLife.toc`
   - `SecondLife.lua`
4. Start the game (or `/reload`) and enable **SecondLife** in the AddOns list.

> The `.toc` currently targets the latest retail interface ID used during development. If the game updates, you may need to bump the `## Interface:` number.

---

## Usage

- **Unlock to move**: `/sl unlock` (drag with left mouse button)
- **Lock position**: `/sl lock`
- **Reset position**: `/sl reset`
- **Scale (size)**: `/sl scale 1.2` (example)
- **Help**: `/sl help`

---

## File Overview

```
SecondLife/
├─ SecondLife.toc      # Addon manifest
└─ SecondLife.lua      # All logic, frame creation, events, slash commands
```

## License

GNU 3
