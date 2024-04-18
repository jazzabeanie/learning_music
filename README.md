# Music tools

## Random note generator

To run `awk -f generate_random_notes.awk <<< 'A,B,C,D,E,F,G'`. The notes to randomise are provided in the string at the end.

## Hard note generator

Difficult notes are saved in a csv file: `./difficult_notes.csv`.

View them in a random order: `awk 'NR>1{print $0}' difficult_notes.csv | shuf`

## Playing sounds

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

## Random note and string generator

run with `awk -f generate_random_notes_and_string.awk <<< ""`

run continuously: `while true; do; awk -f generate_random_notes_and_string.awk <<< ""; sleep 2; done`
