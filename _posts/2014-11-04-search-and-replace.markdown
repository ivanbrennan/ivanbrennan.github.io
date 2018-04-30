---
layout: post
title: "search & replace"
date: 2014-11-04 08:05
comments: true
categories: unix
---

Performing a project-wide search-and-replace is a common task, and yet I still forget how to do it in Vim. While there's not that much to it (build an argument list of relevant files and run a global substitution across them), I've had to look it up enough times to start wondering if there's a better way. I ended up writing a shell function, as well as a Ruby-specific wrapper for it.

Now if I want to rename a function across my project's javascript files, I can drop onto the command-line and run:

    $ greplace **.js uglyFunctionName nicerFunctionName

Or, if I'm renaming a Ruby method:

    $ rupl bad_method_name good_method_name


## The Sauce
Using `find`, `grep`, and `sed` in concert, we declare which files to search, what to search for, and what to do with those files that contain a match.
```bash
greplace() {
  if [ "$#" != 3 ]; then
    echo "Usage: greplace file_pattern search_pattern replacement"
    return 1
  else
    file_pattern=$1
    search_pattern=$2
    replacement=$3

    # This is built for BSD grep and the sed bundled with OS X.
    # GNU grep takes -Z instead of --null, and other versions of sed may not support the -i '' syntax.

    find . -name "$file_pattern" -exec grep -lw --null "$search_pattern" {} + |
    xargs -0 sed -i '' "s/[[:<:]]$search_pattern[[:>:]]/$replacement/g"
  fi
}

rupl() {
  if [ "$#" != 2 ]; then
    echo "Usage: rupl search_pattern replacement"
    return 1
  else
    search_pattern=$1
    replacement=$2

    greplace '**.rb' "$search_pattern" "$replacement"
  fi
}
```

## Ingredients
The first thing `greplace` does is test whether it received the wrong number of arguments: `[ "$#" != 3 ]`. If so, we print a usage message and return an error code. Otherwise, we set some local variables with more memorable names than `1`, `2`, and `3`.

Next, we `find` pathnames in the current directory (and subdirectories) that match `file_pattern`. Using `find ... --exec <command> {};` lets us run a command on each found path, expanding `{}` to the pathname. Replacing `;` with `+` will instead expand `{}` to as many of the found pathnames as possible, which allows us to feed all the found files as arguments to a single `grep`.

We `grep` the relevant files for `search_pattern`, restricting results to the names of files (`-l`) that contain a whole-word (`-w`) match. We also print a [null-character](http://en.wikipedia.org/wiki/Null_character) after each filename in the results (`--null`), which will be useful as a delimiter in the next step.

The results of `grep` are piped into `xargs -0`, which constructs an argument list (recognizing the null-character delimiter) and feeds this list to `sed` for further processing.

We then use `sed -i` to edit each file "in place" (rather than writing results to stdout) without creating any backup files (`''`), which could be risky, but since I'm working with Git this seems reasonable.

The actual search-and-replace is simply a pattern substitution. The `[[:<:]]` and `[[:>:]]` delimiters restrict it to whole-word matches.

## Caveats
A few things limit this function's portability. For one, not all versions of `grep` recognize the `--null` flag. GNU grep uses `-Z` instead. Also, the `-i ''` syntax may not be recognized by all versions of `sed` (actually, from what I was able to gather, that syntax might be unique to the version bundled with OSX).

That being said, it would only take a few minor tweaks to get this working on a different system.

