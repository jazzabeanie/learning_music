#!/bin/bash

MIDI_CONTROLLER_NAME="XTONE"

# TODO: change this to something like:
FILE=${1:-"./guitar_notes.csv"}

# use `tail -f /tmp/notes.log` to see the notes as they are being played
echo "" > /tmp/notes.log


# Define a function named 'play_all_notes'
play_all_notes() {
  awk 'NR>1{print $0}' $FILE | shuf | while IFS= read -r note_and_string; do
    echo $note_and_string >> /tmp/notes.log
    echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say
    # sleep 0.5
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

NUMBER_OF_NOTES=${2:-"20"}

if [ $1 = "focused" ]; then
  # prepare focused list
  mapfile -t lines < <(tail --lines 175 time_taken_log.csv | awk 'BEGIN{FS=","; OFS=","}{print $3, $1, $2}' | sort -r | sed 's/..//' | uniq | head -n $NUMBER_OF_NOTES | shuf)
else
  # Prepare all notes in shuffled lines
  mapfile -t lines < <(awk 'NR>1{print $0}' "$FILE" | shuf)
fi

# Counter to track which line to process next
index=0

XTONE_PORT=$(aseqdump -l | grep "$MIDI_CONTROLLER_NAME" | awk '{print $1}')

clear
echo "Press a button to play a note"
say "Press a button to play a note"

# Start listening to MIDI device events
aseqdump -p $XTONE_PORT | \
while read press; do
      if [[ $index -lt ${#lines[@]} ]]; then
          if [[ $press == *"Control change"* ]]; then
              clear
              if ! [[ -z $START_TIME ]]; then
                TIME_ELAPSED=$(($(date +%s) - START_TIME))
                echo "$note_and_string,$TIME_ELAPSED" >> ./time_taken_log.csv
              fi
              echo "${lines[$index]}"
              echo ""
              note_and_string="${lines[$index]}"
              echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say
              START_TIME=$(date +%s)
              sleep 1
              echo ${note_and_string##*,} | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp
          fi
          ((index++))
      else
          echo "No more lines to process."
          say "finished all notes"
          sleep 0.5
          exit 0
      fi
done
