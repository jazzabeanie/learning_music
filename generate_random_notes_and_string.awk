BEGIN{
  FS=","
  notes[1] = "A"
  notes[2] = "B"
  notes[3] = "C"
  notes[4] = "D"
  notes[5] = "E"
  notes[6] = "F"
  notes[7] = "G"
}
{
  srand()
  string = int(rand() * 6) + 1
  note_index = int(rand() * 7) + 1
  print notes[note_index] " " string
}

