# Music tools

This was done with awk just because that's what I've been learning lately.

## Random note generator

This was made to randomise the exercises in this video: https://www.youtube.com/watch?v=PJddQ6Q0UDo

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

