#!/bin/bash

echo "String,Note" > guitar_notes.csv
for string in {1..5};
  do
    for note in {A..G};
      do
        echo "$string,$note" >> guitar_notes.csv
      done
done
