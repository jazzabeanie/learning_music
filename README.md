# Music tools

## Random note generator

To run `awk -f generate_random_notes.awk <<< 'A,B,C,D,E,F,G'`. The notes to randomise are provided in the string at the end.

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
