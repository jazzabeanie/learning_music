#!/usr/bin/env python3
"""Guitar fretboard practice.

Single interactive app replacing play_random_note.sh, play_all_notes.sh,
play_on_key.sh and play_on_midi.sh. Walks you through a few questions,
then announces notes (or chords) for you to find on the guitar, and plays
the note so you can check yourself.

Usage:
    ./practice.py                     # interactive wizard
    ./practice.py difficult_guitar_notes.csv   # practice a specific note list

Watch prompts from another pane with: tail -f /tmp/notes.log

TODO: play the full chord / arpeggio instead of just the root note.
"""

import argparse
import os
import random
import shutil
import subprocess
import sys
import termios
import time
import tty

NOTES_DIR = "./notes"
TIME_LOG = "./time_taken_log.csv"
NOTES_LOG = "/tmp/notes.log"

NATURALS = ["A", "B", "C", "D", "E", "F", "G"]
SHARPS = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
ALL_STRINGS = [1, 2, 3, 4, 5, 6]

CHORD_QUALITIES = [
    "major",
    "minor",
    "diminished",
    "augmented",
    "major 7",
    "minor 7",
    "7",
    "diminished 7",
    "augmented 7",
]

FOCUSED_LOG_LINES = 175  # how far back in the time log focused mode looks
FOCUSED_POOL_SIZE = 20


class Item:
    """One thing to practice: a note or chord rooted on a given string."""

    def __init__(self, string, root, quality=None):
        self.string = string
        self.root = root
        self.quality = quality  # None for plain notes

    @property
    def name(self):
        return f"{self.root} {self.quality}" if self.quality else self.root

    @property
    def display(self):
        return f"{self.name}, string {self.string}"

    @property
    def spoken(self):
        # "A" is misread by say, and "#" should be spoken as "sharp"
        root = self.root.replace("A", "Ayee").replace("#", " sharp")
        name = f"{root} {self.quality}" if self.quality else root
        return f"{name}, string {self.string}"


# ---------------------------------------------------------------------------
# Wizard helpers

def ask(prompt, default):
    answer = input(f"{prompt} [{default}]: ").strip()
    return answer if answer else str(default)


def ask_float(prompt, default):
    while True:
        answer = ask(prompt, default)
        try:
            return float(answer)
        except ValueError:
            print("Please enter a number.")


def ask_yes_no(prompt, default_yes):
    answer = ask(prompt, "y" if default_yes else "n").lower()
    return answer.startswith("y")


def ask_choice(prompt, options, default_index=1):
    """options is a list of labels; returns the chosen index (0-based)."""
    print(prompt)
    for i, label in enumerate(options, 1):
        print(f"  {i}. {label}")
    while True:
        answer = ask("Choose", default_index)
        if answer.isdigit() and 1 <= int(answer) <= len(options):
            return int(answer) - 1
        print(f"Please enter a number between 1 and {len(options)}.")


def ask_numbers(prompt, valid, default="all"):
    """Accepts 'all' or a comma-separated list like '2,3,4'."""
    while True:
        answer = ask(prompt, default).lower()
        if answer == "all":
            return list(valid)
        try:
            picked = [int(n) for n in answer.replace(" ", "").split(",") if n]
        except ValueError:
            picked = []
        if picked and all(n in valid for n in picked):
            return sorted(set(picked))
        print(f"Enter 'all' or numbers from {valid}, e.g. 2,3,4")


# ---------------------------------------------------------------------------
# Sound

def say(text):
    subprocess.run(["say", text])


def play_root(root):
    wav = os.path.join(NOTES_DIR, root.lower() + ".wav")
    if not os.path.isfile(wav):
        print(f"(no wav file for {root}: {wav})")
        return
    # TODO: for chords, play the full chord / arpeggio instead of the root
    subprocess.run(["ffplay", "-autoexit", "-nodisp", "-loglevel", "quiet", wav])


# ---------------------------------------------------------------------------
# Pools

def build_pool(strings, chords, qualities, roots):
    if chords:
        return [Item(s, r, q) for s in strings for r in roots for q in qualities]
    return [Item(s, r) for s in strings for r in roots]


def pool_from_csv(path):
    pool = []
    with open(path) as f:
        for line in list(f)[1:]:  # skip header
            line = line.strip()
            if not line:
                continue
            string, name = line.split(",", 1)
            parts = name.split(" ", 1)
            quality = parts[1] if len(parts) > 1 else None
            pool.append(Item(int(string), parts[0], quality))
    return pool


def focused_pool(strings):
    """The slowest recent items from the time log, like play_on_midi --focused."""
    if not os.path.isfile(TIME_LOG):
        return []
    with open(TIME_LOG) as f:
        lines = [l.strip() for l in f if l.strip()]
    slowest = {}  # (string, name) -> worst elapsed seconds
    for line in lines[-FOCUSED_LOG_LINES:]:
        try:
            string, name, elapsed = line.split(",")
            key = (int(string), name)
            slowest[key] = max(slowest.get(key, 0), float(elapsed))
        except ValueError:
            continue
    items = [
        (secs, string, name)
        for (string, name), secs in slowest.items()
        if string in strings
    ]
    items.sort(reverse=True)
    pool = []
    for _, string, name in items[:FOCUSED_POOL_SIZE]:
        parts = name.split(" ", 1)
        quality = parts[1] if len(parts) > 1 else None
        pool.append(Item(string, parts[0], quality))
    return pool


# ---------------------------------------------------------------------------
# Advance modes: each returns a "wait for next round" function

def wait_key():
    print("Press any key for the next one (q to quit)...")
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    if ch in ("\x03", "q"):  # Ctrl+C or q
        raise KeyboardInterrupt
    return ch


def midi_waiter(controller_name):
    if shutil.which("aseqdump") is None:
        sys.exit("I require aseqdump for MIDI mode but it's not installed. Aborting.")
    listing = subprocess.run(["aseqdump", "-l"], capture_output=True, text=True)
    port = None
    for line in listing.stdout.splitlines():
        if controller_name in line:
            port = line.split()[0]
            break
    if port is None:
        sys.exit(
            f"MIDI controller '{controller_name}' not found. "
            "Run 'aseqdump -l' to see available controllers."
        )
    proc = subprocess.Popen(["aseqdump", "-p", port], stdout=subprocess.PIPE, text=True)

    def wait_midi():
        print("Press your MIDI controller for the next one (Ctrl+C to quit)...")
        for line in proc.stdout:
            if "Control change" in line:
                return
        raise KeyboardInterrupt  # aseqdump exited

    return wait_midi


# ---------------------------------------------------------------------------
# Main loop

def clear():
    print("\033[2J\033[H", end="")


def log_time(item, elapsed):
    with open(TIME_LOG, "a") as f:
        f.write(f"{item.string},{item.name},{int(elapsed)}\n")


def run_round(item, announce_delay):
    clear()
    print(f"\n  {item.display}\n")
    with open(NOTES_LOG, "a") as f:
        f.write(item.display + "\n")
    say(item.spoken)
    start = time.time()  # the clock starts once the prompt has been spoken
    time.sleep(announce_delay)
    play_root(item.root)
    return start


def practice(items, endless, waiter, auto_interval, announce_delay, log_times):
    pool = list(items)
    previous = None  # (item, start_time) for time logging
    while True:
        random.shuffle(pool)
        for item in pool:
            if waiter:
                waiter()
                if previous and log_times:
                    log_time(previous[0], time.time() - previous[1])
            start = run_round(item, announce_delay)
            previous = (item, start)
            if not waiter:
                time.sleep(auto_interval)
        if not endless:
            break
    print("No more notes to practice.")
    say("finished all notes")


def wizard(csv_pool):
    print("Guitar practice setup (Enter accepts the default)\n")

    if csv_pool is not None:
        pool = csv_pool
        strings = ALL_STRINGS
    else:
        strings = ask_numbers(
            "Which strings do you want to practice? ('all' or e.g. 2,3,4)",
            ALL_STRINGS,
        )
        chords = ask_choice("Practice notes or chords?", ["notes", "chords"]) == 1
        qualities = []
        if chords:
            print("Which chord qualities? ('all' or e.g. 1,3,5)")
            for i, q in enumerate(CHORD_QUALITIES, 1):
                print(f"  {i}. {q}")
            picks = ask_numbers("Choose", list(range(1, len(CHORD_QUALITIES) + 1)))
            qualities = [CHORD_QUALITIES[i - 1] for i in picks]
        sharps = ask_yes_no("Include sharps?", default_yes=False)
        roots = SHARPS if sharps else NATURALS
        pool = build_pool(strings, chords, qualities, roots)

    mode = ask_choice(
        "Practice mode?",
        [
            "endless random",
            "one full pass through everything",
            f"focused (your {FOCUSED_POOL_SIZE} slowest recent items)",
        ],
        default_index=2,
    )
    if mode == 2:
        focused = focused_pool(strings)
        if focused:
            pool = focused
        else:
            print("Not enough history in the time log yet - using the full pool.")
    endless = mode == 0

    advance = ask_choice(
        "How do you want to advance to the next one?",
        ["automatically", "key press", "MIDI controller"],
        default_index=2,
    )
    waiter = None
    auto_interval = 1.0
    if advance == 0:
        auto_interval = ask_float("Seconds before the next one", 1)
    elif advance == 2:
        controller = ask("MIDI controller name", "XTONE")
        waiter = midi_waiter(controller)
    else:
        waiter = wait_key

    announce_delay = ask_float("Delay between announcing and playing the note", 0.5)

    # Time-to-answer is only meaningful when you control the pace
    log_times = waiter is not None
    return pool, endless, waiter, auto_interval, announce_delay, log_times


def clear_time_log():
    if not os.path.isfile(TIME_LOG):
        print(f"{TIME_LOG} does not exist - nothing to clear.")
        return
    with open(TIME_LOG) as f:
        entries = sum(1 for line in f if line.strip())
    answer = input(f"Delete all {entries} entries from {TIME_LOG}? [y/N]: ")
    if answer.strip().lower().startswith("y"):
        os.remove(TIME_LOG)
        print(f"Cleared {TIME_LOG}.")
    else:
        print("Left the log alone.")


def main():
    parser = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""\
the time taken log ({TIME_LOG}):
  In key press and MIDI modes, the seconds between a prompt being announced
  and you advancing to the next one are appended as 'string,name,seconds'
  lines. Focused practice mode reads the last {FOCUSED_LOG_LINES} entries and
  drills your {FOCUSED_POOL_SIZE} slowest items. Clear the log with
  --clear-log when you want focused mode to start from a blank slate
  (e.g. after changing instrument or making real progress).
""",
    )
    parser.add_argument(
        "csv_file",
        nargs="?",
        help="optional CSV of specific items to practice (String,Note header)",
    )
    parser.add_argument(
        "--clear-log",
        action="store_true",
        help=f"clear the time taken log ({TIME_LOG}) and exit",
    )
    args = parser.parse_args()

    if args.clear_log:
        clear_time_log()
        return

    for cmd in ("say", "ffplay"):
        if shutil.which(cmd) is None:
            sys.exit(f"I require {cmd} but it's not installed. Aborting.")
    if not os.path.isdir(NOTES_DIR):
        sys.exit(
            f"Directory '{NOTES_DIR}' not found. "
            "Please create it and place the WAV files in it. Aborting."
        )

    csv_pool = pool_from_csv(args.csv_file) if args.csv_file else None
    settings = wizard(csv_pool)

    open(NOTES_LOG, "w").close()  # fresh log for tail -f

    try:
        practice(*settings)
    except KeyboardInterrupt:
        print("\nBye.")


if __name__ == "__main__":
    main()
