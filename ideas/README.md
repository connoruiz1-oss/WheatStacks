# Ideas

Backlog of features and experiments that are not part of the active
configuration. Anything in this folder is documented well enough that a
future-you (or a future agent) can pick it up and implement it without
re-deriving the concept.

Rules for this folder:

1. **Nothing here is loaded by any config.** Symlink scripts, `source`
   directives, and `exec` lines all live elsewhere. This folder is
   pure documentation. Adding a file here cannot break a working
   system.
2. **Each idea is one file.** Self-contained. If implementing one idea
   touches another, cross-link them.
3. **Capture intent, mapping, and an implementation sketch.** Not just
   "I want this", but enough technical scaffolding that picking it up
   later costs minutes, not hours.
4. **When implemented, move the file out.** Either delete it (the live
   config and a comment that points at the relevant commit are now
   the source of truth) or move it to `ideas/done/` if the rationale
   is worth keeping around.

## Current ideas

- [wheatstacks-rotation.md](wheatstacks-rotation.md) — Auto-rotate the
  desktop wallpaper through Monet's Wheatstacks series based on time
  of day and time of year.
