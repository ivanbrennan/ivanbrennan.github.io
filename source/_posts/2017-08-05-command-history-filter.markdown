---
layout: post
title: "History: filtered vs unfiltered"
date: 2017-08-05 08:49
comments: true
categories: shell, awk
---

I get a lot of use out of shell history. At its simplest, tapping `↑` cycles through previous commands. Incremental search (`C-r`) will retrieve matching history entries, updating as you type. There are more ways you can access history, but these two in particular have become ingrained in my workflow.

I'm running Bash (for now), and have it configured to save a good deal of history:
```sh
export HISTSIZE=10000
shopt -s histappend
```
When you start a shell, Bash reads `~/.bash_history` (or `$HISTFILE` if that's been set), initializing the in-memory history your session will interact with. When exiting the shell, new history is written to disk, making it available to future sessions. With `histappend` set, the history file is appended to rather than being overwritten.

I've also configured it to save multiline commands with embedded newline characters, separated by timestamps. This makes it easy to recall and modify more complex commands, such as loops and pipelines.
```sh
export HISTTIMEFORMAT='%F %T '
shopt -s cmdhist lithist
```

Bash also has a `HISTIGNORE` variable that can hold a colon-separated list of patterns to exclude from history. If, for example, you wanted to ignore the `jobs` builtin and any `ls` commands, you could set:
```sh
HISTIGNORE='jobs:ls[ ]*'
```
The patterns are treated as shell globs that must match the entire line. Multiline entries are decided based on the first line. I tried this out and quickly realized I prefer an unfiltered recent history, for the most part. If I run,

    ls /path/to/some/directory

I want to be able to `ls` a subdirectory by tapping `↑` and appending to the path. I also find the unfiltered approach more intuitive when interacting with recent history. 

More distant history, on the other hand, could benefit from some filtering. I don't see much value in persisting `ls` or `man` commands from one session to the next, as I'm not likely to search for them, and when I'm reaching back into a previous session's history it's nearly always by searching -- either _reverse-search-history_ (`C-r`) or the less well-known _history-search-backward_, which retrieves the previous command matching what you've already typed (I've bound this to `M-p`).

The only things I'm using `HISTIGNORE` for are commands like `jobs` and `fg`, which I never reach for through the hands of history.

### Filtering persisted history

To keep commands like `ls` from polluting the history of future shell sessions, I'm running a custom filter to groom `~/.bash_history` upon exit. I initially tried filtering just the new entries that were to be appended to the existing file, but the order Bash runs things in upon exit made this infeasible. It also turned out to be unnecessary, as the filter can process 50,000 lines in about 70 milliseconds.

I'm trapping `EXIT` to trigger the filter in my `~/.bashrc`:
```sh
if [[ $- == *i* ]]; then
  trap '$HOME/.bash_history_filter >/dev/null 2>&1 &' EXIT
fi
```
The cryptic `$-` variable holds flags indicating which shell options are in effect, and I'm using it to restrict the trap to interactive shells, indicated by an `i` flag. The script it runs, `~/.bash_history_filter`, is as follows:
```sh
#!/bin/sh

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

awk_script="$HOME/.bash_history_filter.awk"
persisted_history="${HISTFILE:-$HOME/.bash_history}"

if [[ -r "$awk_script" && -r "$persisted_history" ]]; then
  awk -f "$awk_script" "$persisted_history" > "$tmpfile"

  mv "$tmpfile" "$persisted_history"
fi
```
The actual filtering logic lives in an Awk script. We run the persisted history through that script, output to a temporary file, then replace the history file with the results. As a cautionary measure, we lay an exit trap to remove the temporary file in case something goes wrong.

Writing the actual filtering logic was interesting. It's the first time I made good use of Awk beyond its most basic capabilities.

Awk processes input, in this case `~/.bash_history`, one line at a time, splitting it into individual fields (space-delimited by default). The individual fields are referenceable as `$1`, `$2`, etc. and the entire line can be referenced by `$0`. The Awk script itself defines a set of commands that run on each line, and a common idiom, in pseudocode is:

    /pattern/ {
      # commands to run on any line matching pattern 
    }

    $1 ~ /word/ {
      # commands to run on any line whose first field matches word 
    }

You can call `next` to skip any subsequent commands and jump to the next line of input. You can also set and manipulate whatever variables you need to track state, accumulate text, etc. The `print` function gives you control over what makes it into the output stream. 

This is what I ended up with:
```awk
/^#[[:digit:]]{10}$/ {
  timestamp = $0
  histentry = ""
  next
}

($1 ~ /^(ls?|man|cat)$/) || /^[[:alpha:]]$/ {
  if (! timestamp) {
    print
  } else {
    histentry = $0
  }
  next
}

timestamp {
  print timestamp
  timestamp = ""
}

histentry {
  print histentry
  histentry = ""
}

{ print }
```

It's essentially a state-machine.

{% img state-machine /images/history-filter/state-machine.png 'state-machine' 'state-machine' %}

Getting the Awk script just right took some work, and I found it helpful to have some [automated tests](https://github.com/ivanbrennan/dotfiles/blob/master/shell/filter_test) at my back as I fiddled with it.

When processing multiline entries, I decided that if a command is complex enough to warrant mutliple lines, it's worth remembering, even if its first line matches an uninteresting pattern. The "uninteresting" predicate ended up as:

    ($1 ~ /^(ls?|man|cat)$/) || /^[[:alpha:]]$/

This matches some commands that are uninteresting with or without arguments, any line that consists of a single letter. I have some functions/aliases I use -- `v` for (neo)vim, `e` for emacs, `t` for tmux -- which aren't very interesting by themselves, but could have interesting arguments. I frequently use `C-r`, for example, to recall/reuse a previous `tmux new-session` command:

    t new-session -s ruby-project -c /path/to/ruby-project

I tried out Sed as an alternative to Awk for this use, but decided against it. Sed has an extremely terse syntax and fought me most of the way. I finally found a couple ways to make it work, but they're pretty gnarly. If you install GNU Sed, you can tell Sed to treat lines as separated by NULL bytes. The entire file will be slurped into a single "line" on which you can apply substitution:

    gsed --null-data \
         --regexp-extended \
         's/(#[0-9]{10}\n((cat|ls?|man)([^[:alnum:]][^\n]*)?|[[:alpha:]])\n)+(#[0-9]{10}\n|$)/\5/g' \
         "$infile" >"$outfile"

Sed implementations that don't have the NULL byte trick up their sleeve (e.g. BSD Sed), will instead have to juggle data back and forth between the "hold-space" and "pattern-space". I scripted this out of morbid curiosity, but I wouldn't wish it on anyone:

    sed -E -f horrendous.sed "$infile" >"$outfile"

with the following `horrendous.sed` script:

    $ {
      1 h
      1!H
      x
      /^#[[:digit:]]{10}\n((ls?|cat|man)([^[:alnum:]][[:print:]]*)?|[[:alpha:]])$/ d
      p
    }

    /^#[[:digit:]]{10}$/ !{
      1 h
      1!H
      d
    }

    x
    /^$/ d
    /^#[[:digit:]]{10}$/ d
    /^#[[:digit:]]{10}\n((ls?|cat|man)([^[:alnum:]][[:print:]]*)?|[[:alpha:]])$/ d

Benchmarking the Awk, GNU Sed, and Sed solutions on a 50,000 line file:

    awk  0.070s
    gsed 0.060s
    sed  0.080s
    
Awk is the best choice, I think. GNU Sed can shave 10 milliseconds off the run time, but the extra dependency and the 80+ character regex aren't worth it.
