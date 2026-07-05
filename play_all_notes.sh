#!/bin/bash

# TODO: change this to something like:
FILE=${1:-"./guitar_notes.csv"}

while [ $# -gt 0 ]; do
  case "$1" in
    --exclude)
      STRING_TO_EXCLUDE=$2
      echo "excluding $STRING_TO_EXCLUDE"
      TEMP_FILE=$(mktemp /tmp/temp.XXXXXX.csv)
      grep -v "$STRING_TO_EXCLUDE" "$FILE" > "$TEMP_FILE"
      FILE="$TEMP_FILE"
      echo "Contents of FILE:"
      cat "$FILE"
      shift 2
      ;;
    --key)
      KEY_MODE=true
      shift
      ;;
    *)
      if [ -z "${FIRST_ARG_USED}" ]; then
        FILE=$1
        FIRST_ARG_USED=true
      fi
      shift
      ;;
  esac
done

# use `tail -f /tmp/notes.log` to see the notes as they are being played
echo "" > /tmp/notes.log


# Define a function named 'play_all_notes'
play_all_notes() {
  awk 'NR>1{print $0}' $FILE | shuf | while IFS= read -r note_and_string; do
    echo $note_and_string >> /tmp/notes.log
    echo "$note_and_string" | sed 's/A/Ayee/g' | xargs say
    sleep 1
    echo ${note_and_string##*,} | awk '{print "./notes/" tolower($1) ".wav"}' | xargs ffplay -autoexit -nodisp

    if [ "$KEY_MODE" = true ]; then
      read -n 1 -s -r -p "Press any key to continue..."
    else
      sleep 1
    fi
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

# Execute the function
play_all_notes
