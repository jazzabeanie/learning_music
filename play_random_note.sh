#!/bin/bash

# TODO: get the first parameter
SLEEP_TIME=$1

if [ -z "$SLEEP_TIME" ]; then
    echo "Pass a number as the first argument to specify the sleep time between notes. or pass --key to wait for a key press between notes."
    exit
fi

# Define a function named 'play_random_notes'
play_random_notes() {
    while true; do
        # Generate a random note and string, speak it
        note_and_string=$(awk -f generate_random_notes_and_string.awk <<< "")
        echo "$note_and_string"
        echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say

        # Sleep for 1 second after saying the note
        sleep 1

        # Play the corresponding audio file
        echo "$note_and_string" | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp

        if [ "$SLEEP_TIME" = "--key" ]; then
            # Wait for a key press before playing the next note
            read -n 1 -s -r -p "Press any key to continue..."
        else
            # Sleep for the specified time before playing the next note
            sleep $SLEEP_TIME
        fi

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
