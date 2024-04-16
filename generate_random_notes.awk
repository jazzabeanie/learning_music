function shuffle(array) {
    # Ensure the random seed is initialized
    srand()

    for (i = length(array); i > 1; i--) {
        # Generate a random index from 1 to i
        j = int(rand() * i) + 1

        # Swap elements array[i] and array[j]
        tmp = array[i]
        array[i] = array[j]
        array[j] = tmp
    }
}

BEGIN{
  FS=","
}
{
  for (i=1; i<=NF; i++) {
    notes[i] = $i
  }
  shuffle(notes)
  
  for (i = 1; i <= length(notes); i++) {
      print notes[i]
  }
}

