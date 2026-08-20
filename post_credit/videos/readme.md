# Post-Credit Videos

Place converted **OGV** files here for Godot runtime playback.

## Required Files

| File | Phase | Description |
|---|---|---|
| `PC01_RYAN_REALIZATION.ogv` | After gameplay ends | Ryan realizes what he built and what it cost |
| `PC02_REBUILD.ogv` | After Interactive Moment | Ryan returns to the lab and begins rebuilding |

## Conversion (MP4 → OGV)

Use FFmpeg to convert your MP4 source files:

```bash
ffmpeg -i PC01_RYAN_REALIZATION.mp4 \
  -c:v libtheora -q:v 7 \
  -c:a libvorbis -q:a 5 \
  PC01_RYAN_REALIZATION.ogv

ffmpeg -i PC02_REBUILD.mp4 \
  -c:v libtheora -q:v 7 \
  -c:a libvorbis -q:a 5 \
  PC02_REBUILD.ogv
```

## Fallback Behaviour

If OGV files are **not present**, the system automatically shows
a styled placeholder screen with the video's subtitle text.

Press **SPACE** or **ENTER** to advance past a placeholder.

This means you can run and test the entire post-credit sequence
without the videos — the interactive moments and rebuild task
will work exactly as in production.

## Notes

- Do NOT place `.mp4` files here for runtime use — Godot cannot play MP4.
- OGV (Theora) is the only video format natively supported by Godot 4.
- Godot will import `.ogv` files automatically when you open the project.
