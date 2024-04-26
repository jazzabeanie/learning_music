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

### Ubuntu:

Play continuously with sound (note process must be killed to stop): `while true; do; awk -f generate_random_notes_and_string.awk <<< "" | tee >(xargs echo && echo "") | awk '{print "./notes/" tolower($1) ".wav" }' | xargs ffplay -autoexit -nodisp | sleep 3; clear; done`

or say the note: `while true; do; awk -f generate_random_notes_and_string.awk <<< "" | tee >(xargs say) | awk '{print "./notes/" tolower($1) ".wav" }' | xargs ffplay -autoexit -nodisp | sleep 3; clear; done`

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

