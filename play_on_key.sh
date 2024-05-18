#!/bin/bash

# Check for required commands
for cmd in awk say ffplay; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "I require $cmd but it's not installed. Aborting."; exit 1; }
done

FILE=${1:-"./guitar_notes.csv"}
NUMBER_OF_NOTES=${2:-"20"}


if [ "$1" = "focused" ]; then
  # Prepare focused list
  # process_command='tail --lines 175 time_taken_log.csv | awk 'BEGIN{FS=","; OFS=","}{print $3, $1, $2}' | sort -r | sed 's/..//' | uniq | head -n \$NUMBER_OF_NOTES | shuf'
  process_command=$(cat << EOM
tail --lines 175 time_taken_log.csv | awk 'BEGIN{FS=","; OFS=","}{print $3, $1, $2}' | sort -r | sed 's/..//' | uniq | head -n $NUMBER_OF_NOTES | shuf
EOM
)
else
  # Prepare all notes in shuffled lines
  process_command="awk 'NR>1{print $0}' \"$FILE\" | shuf"
fi

echo "process_command: $process_command"

clear
say "Press a button to play a note"

# Loop over each line in the output of the command
while IFS= read -r line
do
  # Wait for a key press
  read -n 1 -s -r -p "Press any key to continue..." < /dev/tty
  clear
  if ! [[ -z $START_TIME ]]; then
    TIME_ELAPSED=$(($(date +%s) - START_TIME))
    echo "$note_and_string,$TIME_ELAPSED" >> ./time_taken_log.csv
  fi
  note_and_string="$line"
  echo ""
  echo "$note_and_string"
  echo ""
  echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say
  START_TIME=$(date +%s)
  sleep 1
  echo ${note_and_string##*,} | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp
done < <(awk 'NR>1{print $0}' "$FILE" | shuf)

echo "No more lines to process."
say "finished all notes"
sleep 0.5
exit 0
