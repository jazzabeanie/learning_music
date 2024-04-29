echo "Note,String" > guitar_notes.csv
for string in {1..5}
do
  for note in {A..G}
  do
    echo "$note,$string" >> guitar_notes.csv
  done
done
