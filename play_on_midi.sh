#!/bin/bash

# TODO: change this to something like:
FILE=${1:-"./guitar_notes.csv"}

# use `tail -f /tmp/notes.log` to see the notes as they are being played
echo "" > /tmp/notes.log


# Define a function named 'play_all_notes'
play_all_notes() {
  awk 'NR>1{print $0}' $FILE | shuf | while IFS= read -r note_and_string; do
    echo $note_and_string >> /tmp/notes.log
    echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say
    sleep 1
    echo ${note_and_string##*,} | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp
    sleep 1
    clear
  done
}

# Check for required commands
for cmd in awk say ffplay; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "I require $cmd but it's not installed. Aborting."; exit 1; }
done

# Check if notes directory exists
if [ ! -d "./notes" ]; then
    echo "Directory './notes' not found. Please create it and place the WAV files in it. Aborting."
    exit 1
fi

# Prepare the shuffled lines in advance
mapfile -t lines < <(awk 'NR>1{print $0}' "$FILE" | shuf)

# Counter to track which line to process next
index=0

XTONE_PORT=$(aseqdump -l | grep XTONE | awk '{print $1}')

# Start listening to MIDI device events
aseqdump -p $XTONE_PORT | \
while read press; do
      if [[ $index -lt ${#lines[@]} ]]; then
          if [[ $press == *"Control change"* ]]; then
              clear
              echo "${lines[$index]}"
              echo ""
              note_and_string="${lines[$index]}"
              echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say
              sleep 1
              echo ${note_and_string##*,} | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp
          fi
          ((index++))
      else
          echo "No more lines to process."
          say "Done"
          break
      fi
done