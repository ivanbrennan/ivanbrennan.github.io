---
layout: post
title: "search &amp; replace"
date: 2014-11-04 08:05
comments: true
categories: unix
---

Performing a project-wide search-and-replace is a common task, and yet I still forget how to do it in Vim. While there's not that much to it (build an argument list of relevant files and run a global substitution across them), I've had to look it up enough times to start wondering if there's a better way. I ended up writing a shell function, as well as a Ruby-specific wrapper for it.

Now if I want to rename a function across my project's javascript files, I can drop onto the command-line and run:
```
greplace **.js uglyFunctionName nicerFunctionName
```
Or, if I'm renaming a Ruby method:
```
rupl bad_method_name good_method_name
```

## Sauce
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
The function first tests whether it's been passed the wrong number of arguments, `[ "$#" != 3 ]`, in which case it displays a usage message and returns an error code. Otherwise it sets some local variables based on the arguments received.

It performs a `find` in the current directory, looking for files whose name matches the filename-pattern, and greps through the found files looking for the search-pattern.

Next, the results of `grep` are piped to `xargs`, which constructs an argument list for the following `sed` command. Finally, `sed` performs the search and replace on each file in that list.

## Details

