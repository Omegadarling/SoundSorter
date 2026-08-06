# SoundSorter

A single-file, fully local web app for ordering a folder of audio files by ear (and by eye).

Point it at a directory of sound effects or music stingers, audition each file, compare
their waveforms side by side, and drag them into your preferred order — small subtle
sounds first, grand triumphant finale last. Then save renamed copies with the sort order
baked into the filenames (`01_whoosh.wav`, `02_hit.wav`, … or `name_01.wav`, or a full
rename like `impact_01.wav`).

## Use it

Open `index.html` in a browser. No build step, no server, no dependencies, nothing
uploaded — everything runs locally.

- **Chrome / Edge**: full experience — pick a folder, then "Save to folder…" writes the
  renamed copies wherever you choose.
- **Firefox / Safari**: folder picking works; exports download as a ZIP instead.

## Features

- **Waveform per file**, drawn at true relative amplitude — loud files visibly tower over
  quiet ones, so you can compare sounds at a glance. Click a waveform to play from that spot.
- **Loudness analysis** (max RMS over a 400 ms window, dBFS) with color-coded chips, plus
  one-click starting sorts: *quiet → loud* (the "small to grand finale" order), duration,
  name, shuffle.
- **Drag to reorder**, with keyboard support (arrows to select, ⌥/⌘+arrows to move,
  Space to play/pause, Backspace to remove from the list).
- **Play all** auditions the whole sequence in order; a play-mode toggle picks what
  happens when a sound ends — auto-play the next, loop the current one, or stop.
- **Per-sound volume**: drag any loudness chip left or right to turn that sound down or
  up (double-click resets). Playback previews the change, the waveform rescales, and
  exports apply it — adjusted files are re-rendered as 24-bit WAV at their original
  sample rate, with a warning if the gain clips; untouched files are copied byte-for-byte.
- **Flexible naming**: number as prefix or suffix, custom separator, start number, digit
  padding, or replace every name with a new base name.
- **AIFF support everywhere**: Chrome and Firefox can't play or decode `.aif`/`.aiff`
  natively, so the app ships its own AIFF decoder (PCM including `sowt`/`twos`,
  float32/64) — waveforms, loudness, gain, and playback (transcoded on the fly) all work.
- **Non-destructive**: originals are never touched — exports are copies (folder or ZIP).
