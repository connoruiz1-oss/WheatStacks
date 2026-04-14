# Wheatstacks Rotation

> Status: backlog. Not implemented. This document is the spec.

## The idea

Rotate the desktop wallpaper through Claude Monet's *Wheatstacks*
(*Meules*) series, picking each painting based on the **current time of
day** and **current time of year**. The series exists because Monet
painted the same wheatstacks under different light conditions across
seasons. Mapping his paintings to real time of day and year is what the
series was already doing on his easel; we just translate it to the
desktop.

## Why this is a better fit than a generic slideshow

Most wallpaper rotators pick from a folder at random or on a fixed
interval. The wheatstacks idea is meaningfully different: each painting
*is* a moment, and the desktop becomes a slow clock that reads the
current moment off the painting. Late afternoon in October at the
desktop should look like Monet's late afternoon in October, not like a
random snow scene at noon.

This also resolves the only real downside of swapping swww for
hyprpaper (no fade transitions): hard cuts are appropriate here. The
wallpaper changes when the moment changes, not as decoration.

## Painting catalog

A working subset of the series, mapped to time slots. All paintings are
Monet, 1890-1891, public domain (Met / Art Institute of Chicago / Musée
d'Orsay / Hill-Stead / others). The exact filenames are placeholder;
the actual files live in `~/Pictures/Wallpapers/wheatstacks/` once
sourced.

| File                              | Painting (common title)                          | Season       | Time of day      |
| --------------------------------- | ------------------------------------------------ | ------------ | ---------------- |
| `summer_morning.jpg`              | *Grainstack in the Sunlight*                     | Summer       | Morning          |
| `summer_midday.jpg`               | *Stacks of Wheat (End of Summer)*                | Summer       | Midday           |
| `summer_evening.jpg`              | *Wheatstacks, End of Summer*                     | Summer       | Evening / sunset |
| `autumn_morning.jpg`              | *Stack of Wheat (Sun in the Mist)*               | Autumn       | Morning          |
| `autumn_midday.jpg`               | *Grainstack (Hazy Sunshine)*                     | Autumn       | Midday           |
| `autumn_evening.jpg`              | *Stacks of Wheat (End of Day, Autumn)*           | Autumn       | Evening / sunset |
| `winter_morning.jpg`              | *Wheatstacks, Snow Effect, Morning*              | Winter       | Morning          |
| `winter_midday.jpg`               | *Wheatstacks (Effect of Snow and Sun)*           | Winter       | Midday           |
| `winter_evening.jpg`              | *Stack of Wheat (Sunset, Snow Effect)*           | Winter       | Evening / sunset |
| `spring_morning.jpg`              | *Stack of Wheat (Thaw, Morning)*                 | Spring       | Morning          |
| `spring_midday.jpg`               | *Wheatstacks, Midday* (or generic spring stack)  | Spring       | Midday           |
| `spring_evening.jpg`              | *Stack of Wheat (Thaw, Sunset)*                  | Spring       | Evening / sunset |
| `night.jpg` (any season)          | A darkened version, or omit and reuse `_evening` | Any          | Night            |

Twelve to thirteen paintings cover the 4×4 grid (4 seasons × 4 times
of day) with one image reused at night. Buying the full
~25-painting set is not required; the buckets above are the minimum
viable rotation.

## Bucketing logic

### Time of day

Two options, in order of effort:

1. **Naive (clock-based):** four buckets keyed off the local hour.
   - Morning: 06:00 to 11:59
   - Midday: 12:00 to 16:59
   - Evening: 17:00 to 20:59
   - Night: 21:00 to 05:59

2. **Astronomical (sunrise/sunset):** use `sunwait` or compute via
   coordinates so "morning" actually means "after sunrise" and
   "evening" means "around sunset". This matters because Monet's
   *Snow Effect, Sunset* should appear at 4:30pm in December, not at
   7pm. The `sunwait` package is in the Arch repos.

Start with the naive version. Upgrade to astronomical once the rest
works.

### Season

Naive bucketing on month is fine. Pick whichever boundary you prefer:

- **Meteorological:** Spring = Mar-May, Summer = Jun-Aug, Autumn =
  Sep-Nov, Winter = Dec-Feb. Easy. Recommended.
- **Astronomical:** uses the equinoxes and solstices. More accurate
  but requires a lookup table or library.

## Implementation sketch

Three files. None of them touch the active config.

### 1. The manifest

`~/.config/wheatstacks-rotation/manifest.json`

```json
{
  "wallpaper_dir": "~/Pictures/Wallpapers/wheatstacks",
  "buckets": {
    "summer.morning":  "summer_morning.jpg",
    "summer.midday":   "summer_midday.jpg",
    "summer.evening":  "summer_evening.jpg",
    "autumn.morning":  "autumn_morning.jpg",
    "autumn.midday":   "autumn_midday.jpg",
    "autumn.evening":  "autumn_evening.jpg",
    "winter.morning":  "winter_morning.jpg",
    "winter.midday":   "winter_midday.jpg",
    "winter.evening":  "winter_evening.jpg",
    "spring.morning":  "spring_morning.jpg",
    "spring.midday":   "spring_midday.jpg",
    "spring.evening":  "spring_evening.jpg",
    "any.night":       "night.jpg"
  }
}
```

Why JSON: cheap to edit, easy to extend (add a `weather` key later if
you ever want rain/snow detection from a weather API), and
language-agnostic.

### 2. The selector script

`~/.local/bin/wheatstacks-rotate`

```bash
#!/usr/bin/env bash
# Pick the right Monet wheatstack for right now and apply it via
# hyprpaper. Idempotent: if the right wallpaper is already showing,
# this is essentially a no-op.

set -euo pipefail

MANIFEST="${HOME}/.config/wheatstacks-rotation/manifest.json"
WALL_DIR="$(jq -r '.wallpaper_dir' "$MANIFEST" | sed "s|^~|$HOME|")"

# --- Season bucket (meteorological) ---
month=$(date +%-m)
case $month in
    3|4|5)   season=spring ;;
    6|7|8)   season=summer ;;
    9|10|11) season=autumn ;;
    12|1|2)  season=winter ;;
esac

# --- Time bucket (naive clock) ---
hour=$(date +%-H)
if   [ "$hour" -ge 6  ] && [ "$hour" -lt 12 ]; then time=morning
elif [ "$hour" -ge 12 ] && [ "$hour" -lt 17 ]; then time=midday
elif [ "$hour" -ge 17 ] && [ "$hour" -lt 21 ]; then time=evening
else                                                 time=night
fi

# Night uses the season-agnostic painting.
if [ "$time" = "night" ]; then
    key="any.night"
else
    key="${season}.${time}"
fi

filename=$(jq -r ".buckets[\"${key}\"]" "$MANIFEST")
target="${WALL_DIR}/${filename}"

if [ ! -f "$target" ]; then
    notify-send "Wheatstacks rotation" \
        "Missing painting for ${key}: ${target}"
    exit 1
fi

# Tell hyprpaper to swap. preload is idempotent; wallpaper is the
# actual switch.
hyprctl hyprpaper preload   "$target"        >/dev/null
hyprctl hyprpaper wallpaper ", $target"      >/dev/null
```

### 3. The systemd user timer

`~/.config/systemd/user/wheatstacks-rotate.timer`

```ini
[Unit]
Description=Rotate Monet wheatstacks wallpaper every 30 minutes

[Timer]
OnBootSec=30s
OnUnitActiveSec=30min
Persistent=true

[Install]
WantedBy=timers.target
```

`~/.config/systemd/user/wheatstacks-rotate.service`

```ini
[Unit]
Description=Apply the Monet wheatstack matching the current time

[Service]
Type=oneshot
ExecStart=%h/.local/bin/wheatstacks-rotate
```

Enable with:

```bash
systemctl --user daemon-reload
systemctl --user enable --now wheatstacks-rotate.timer
```

## Sourcing the paintings

The works themselves are public domain. High-resolution scans are
hosted by:

- **Art Institute of Chicago** (chicago.edu / artic.edu): several
  large-format JPEGs, free download.
- **Met Museum**: open-access program, JPEG and TIFF.
- **Musée d'Orsay**: lower resolution, but free.
- **Wikimedia Commons**: aggregated copies of most of the above.

For a desktop wallpaper at 1920x1080 or 4K, the AIC and Met scans are
more than enough. Crop tightly on the haystack itself for the best
desktop framing; full canvas often has a lot of empty foreground.

## Open questions for when this is picked up

1. **Painting rotation within a bucket.** Right now `summer.midday`
   maps to a single file. If you sourced multiple summer-midday
   paintings, do you want the script to cycle through them within
   the bucket, or pick deterministically by date?
2. **Snow detection.** Should `winter.morning` pick *Snow Effect,
   Morning* always, or only when there is actual snow on the ground
   locally? That would require a weather API call and probably is
   not worth it.
3. **Cross-fade.** If hard cuts feel wrong once it is running, this
   is the trigger to migrate back to swww. The selector script's
   final two `hyprctl` lines become one `swww img --transition-type
   fade` line. The rest of the architecture is unchanged.
4. **Calendar effects.** Worth a special wallpaper on, say, the
   summer solstice or the first day of snow? Possible, easy to add
   to the manifest as a `dates` overlay table that wins over the
   season+time lookup.

## Estimated effort to implement

About one focused evening once the paintings are downloaded. Most of
the time goes into sourcing and cropping the images, not writing the
rotation logic. The script and timer together are under 80 lines.
