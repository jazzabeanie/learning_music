# Music tools

## Getting started

1. Clone this repo and `cd` into it. The note WAV files are already included in `./notes/`.
2. Install the tools listed under Dependencies below.
3. Run the practice wizard:

   ```sh
   ./practice.py
   ```

   Answer the prompts (Enter accepts the default shown in brackets) - see "practice.py — the app" below for what each question does.

## Dependencies

- **Python 3** - standard library only, no pip packages required.
- **`say`** - text-to-speech command used to announce each note/chord. macOS ships this built in. On Linux there's no equivalent by default, so you'll need to provide your own `say` on the `PATH` (e.g. a small script wrapping `espeak-ng` or a local TTS engine such as Piper).
- **`ffplay`** (from `ffmpeg`) - plays the note's WAV file so you can check yourself. Install with `sudo apt install ffmpeg` (Ubuntu/Debian) or `brew install ffmpeg` (macOS).
- **`aseqdump`** (from `alsa-utils`) - only needed if you pick MIDI controller as the advance mode. Install with `sudo apt install alsa-utils`, then run `aseqdump -l` to list available controllers.

The legacy shell scripts described further down have their own extra setup notes under "Playing sounds".

## practice.py — the app

A single interactive app (Python 3 standard library; see Dependencies above for the external tools it shells out to) that replaces the `play_*.sh` scripts below. Run it and answer the prompts (Enter accepts the default shown in brackets):

```sh
./practice.py
```

If you've run it before, it first shows a summary of your last session's settings and asks if you want to continue with them - answer yes to skip straight to practicing, or no to go through the questions below (saved to `last_session.json` for next time).

It walks you through:

- **Which strings** to practice (all, or e.g. `2,3,4`)
- **Notes or chords** — chord qualities available: major, minor, diminished, augmented, major 7, minor 7, 7, diminished 7, augmented 7. Chords are prompted with a root string, e.g. "C minor 7, string 5".
- **Starting finger** (chords only) — practice starting on particular fretting fingers: all, none (default), or a comma-separated list of `i` (index), `m` (middle), `r` (ring), `p` (pinky), e.g. `i,m`.
- **Include sharps?** (default no)
- **Practice mode** — endless random, one full pass through everything, or *focused* (your 20 slowest recent items from `time_taken_log.csv`)
- **Advance mode** — automatically (default 1s between items), key press, or MIDI controller (default XTONE; `aseqdump -l` lists controllers)
- **Announce-to-play delay** (default 0.5s)

Each round announces the note/chord (and starting finger, if chosen), waits, then plays the note WAV so you can check yourself (for chords it plays the root note — playing the full chord/arpeggio is a future TODO). In key press and MIDI modes your time-to-answer is logged to `time_taken_log.csv`, which feeds focused mode.

To start focused mode from a blank slate (e.g. after changing instrument or making real progress), clear the time taken log — it asks for confirmation first:

```sh
./practice.py --clear-log
```

See `./practice.py --help` for details on how the time taken log works.

To practice a specific list instead of the generated pool:

```sh
./practice.py difficult_guitar_notes.csv
```

Watch prompts from another pane with `tail -f /tmp/notes.log`.

The shell scripts below still work and will be removed once practice.py is proven.

## How to use

- Run, or play [the video](https://www.youtube.com/watch?v=O_uywf68d1E).
- It will say the note and string number, find it on your guitar and play it
- The note is played so you can check if you got it right
- play with parameter or change video speed as required

## Random note generator

This was made to randomise the exercises in this video: https://www.youtube.com/watch?v=PJddQ6Q0UDo

This video will substitute for installing if you just want basic use: https://www.youtube.com/watch?v=O_uywf68d1E

To run `awk -f generate_random_notes.awk <<< 'A,B,C,D,E,F,G'`. The notes to randomise are provided in the string at the end.

## Difficult note generator

Difficult notes are saved in a csv file: `./difficult_notes.csv`.

View them in a random order: `awk 'NR>1{print $0}' difficult_notes.csv | shuf`

To run continuously: `while true; do; awk 'NR>1{print $0}' difficult_notes.csv | shuf | head -n 1; sleep 2; done`

## Random note and string generator

To generate an individual note and string: `awk -f generate_random_notes_and_string.awk <<< ""`

To run continuously: `while true; do; awk -f generate_random_notes_and_string.awk <<< ""; sleep 2; clear; done`. Run this, find the note, then look up and find the latest note on the screen.

## Playing sounds

`sudo apt-get install gnustep-gui-runtime`

I think the note wav files came from one of the keyboards on Ableton.

### Ubuntu:

Play continuously with sound (note process must be killed to stop): `while true; do; awk -f generate_random_notes_and_string.awk <<< "" | tee >(xargs echo && echo "") | awk '{print "./notes/" tolower($1) ".wav" }' | xargs ffplay -autoexit -nodisp | sleep 3; clear; don e`

or say the note: `./play_random_note.sh`. Pass a number as the first parameter to wait that many seconds before doing the next note.

Previously say the note with: `while true; do; awk -f generate_random_notes_and_string.awk <<< "" | tee >(xargs say) | awk '{print "./notes/" tolower($1) ".wav" }' | xargs ffplay -autoexit -nodisp | sleep 3; clear; done`

Play all notes in random order:

`./play_all_notes.sh` or to play a specific list of notes: `./play_all_notes.sh difficult_guitar_notes.csv`

To see the notes, open a new pane and run `tail -f /tmp/notes.log`

If you have a midi footswitch, you can run `./play_on_midi.sh`. Note - you will need to edit the file with the name of your controller. `aseqdump -l` to see available controllers.

This lets you press a midi key to trigger the next sound. It will also log the time it has taken for you to figure out the note and log it to `./time_taken_log.csv`. To fucus on just the worst notes when you practice, run `./play_on_midi.sh --focused`. Or add `--exclude PATTERN` to remove lines that match the patter. For example `./play_on_midi.sh --exclude 1` would skip notes on the 1st string.

### WSL:

install sox: `sudo apt install sox`

if on WSL, install PulseAudio: `TODO`

Configure PulseAudio:

    Open the etc\pulse\default.pa file in the PulseAudio directory.
    Add these lines to make PulseAudio accept connections from your WSL2 environment:

    java

    load-module module-native-protocol-tcp auth-anonymous=1

    Save and close the file.

Start PulseAudio:

    Run pulseaudio.exe from the command prompt or create a shortcut to make it easier to start in the future.

