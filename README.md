# Mikan the Desktop Cat 🐱

A tiny orange cat that lives on your desktop. She walks along the bottom of your
screen, stops to rest, falls asleep if you leave her alone — and you can pick her
up, carry her around, and drop her (she falls gently back to the floor).

Built with **Godot 4.4** for [Hack Club Playground](https://playground.hackclub.com/) 🛝

## What she does

- **Walks** left and right along the bottom of your screen, turning around at the edges
- **Idles** — sits and breathes (2-frame idle animation)
- **Naps** — after a while she curls up and sleeps with little `z`s
- **Drag & drop** — pick her up with the mouse (she looks surprised!), carry her
  anywhere, and drop her: she falls back down to the floor
- **Click-through** — only the cat herself catches mouse clicks; everything else
  passes through to your desktop, so she never blocks your work

## How it works (technical)

- `main.gd` — a small state machine (`WALK / IDLE / SLEEP / FALL / DRAG`)
- Transparent, borderless, always-on-top window (`project.godot`):
  `window/size/transparent=true`, `borderless=true`, `always_on_top=true`
- **Mouse passthrough** is updated every frame with
  `DisplayServer.window_set_mouse_passthrough(poly)` so only the cat's rectangle
  receives clicks
- Sprites are generated pixel art (32×32 at 4× scale), drawn procedurally —
  see `make_sprites.py`

## Run it

```bash
# with Godot 4.4+ installed:
godot --path .
```

Or download the exported build for your OS from the releases / itch.io page.

## Credits

Made by maebahesioru for Hack Club Playground (October 2026).

---

## Changelog

- **v1.0.0** — first release: walk / idle / sleep / drag states, click-through window,
  Windows + Linux exports, itch.io release.
