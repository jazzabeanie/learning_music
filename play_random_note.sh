#!/bin/bash

# Define a function named 'play_random_notes'
play_random_notes() {
    while true; do
        # Generate a random note and string, speak it
        note_and_string=$(awk -f generate_random_notes_and_string.awk <<< "")
        echo $note_and_string | sed 's/A/Ayee/g' | xargs say

        # Sleep for 1 second after saying the note
        sleep 1

        # Play the corresponding audio file
        echo $note_and_string | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp

        # Sleep for 2 seconds after playing the note
        sleep 1

        # Clear the screen for the next iteration
        clear
    done
}

# Check for required commands
for cmd in awk say ffplay; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "I require $cmd but it's not installed. Aborting."; exit 1; }
done

# Check if AWK script file exists
if [ ! -f generate_random_notes_and_string.awk ]; then
    echo "AWK script file generate_random_notes_and_string.awk not found. Aborting."
    exit 1
fi

# Check if notes directory exists
if [ ! -d "./notes" ]; then
    echo "Directory './notes' not found. Please create it and place the WAV files in it. Aborting."
    exit 1
fi

# Execute the function
play_random_notes
