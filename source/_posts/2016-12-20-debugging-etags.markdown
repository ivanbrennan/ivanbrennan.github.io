---
layout: post
title: "debugging-etags"
date: 2016-12-20 07:52
comments: true
categories: 
---

I've been using ctags to navigate the codebases I work with in Vim for a couple years, largely thanks to a [blog post](http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html) by Tim Pope where he describes how to use git hooks to keep your tags up-to-date. Omitting a few details, the script I use boils down to this:

	git ls-files | ctags -L - -o ".git/tags" --tag-relative=yes --languages=-javascript,sql

On a large Rails app I've been working with, it takes 1 second and generates a 7MB tags file.

More recently, I started playing around with Emacs, and I've been looking for a way to port my tagging strategy over to *e*tags. There are a few ways you can generate etags. Emacs comes with its own `etags` executable, but the more featureful implementations of ctags can also generate etags.

I've been using [universal-ctags](https://github.com/universal-ctags/ctags), which picked up where [exuberant-ctags](http://ctags.sourceforge.net) left off a few years ago, adding more language support, so I added `-e` to my tagging command and gave that a try.

It took 90 seconds and produced an ***8GB*** tags file. At first, I thought this must be a problem with the etags format itself, but when I tried Emacs' own `etags` executable, it took 13 seconds and produced a 3MB file. Next, I tried exuberant-ctags, which took 2 seconds and produced a 1MB file.

Narrowing in on the problem was an interesting process that pulled together several shell scripting concepts and tools, including redirection, sub-shells, and `awk`.

The first step was to generate performance stats to profile each file's contribution to execution time and tags file-size. I wanted a list of records like:

	some_file.rb <- source-file
	0.004        <- processing time (seconds)
	8159         <- source file-size (bytes)
	13389        <- tags file-size (bytes)

	another_file.rb
	0.002
	345
	4859

	...

To generate these stats, I ran a shell script that iterated through the files, generating tags for each in turn, and appending stats to a running log file.
```sh
#!/bin/sh

for f in $(git ls-files)
do
  ( echo "$f"
    ( TIMEFORMAT='%R'
      time ctags -e -o tmp.TAGS --tag-relative=yes --languages=-javascript,sql $f )
    ( ls -l $f
      ls -l tmp.TAGS ) | awk '{ print $5 }'
    echo ) >> etagging.log 2>&1
  rm tmp.TAGS
done
```
I'll break this down a bit.

First we run `git ls-files` in a sub-shell to generate the list of files we'll be iterating over:

	for f in $(git ls-files)

On each iteration, we run a few commands to generate performance stats and append their output to a log file named `etagging.log`. This could be done like,

	run a command >> etagging.log
	run another command >> etagging.log
	run one more command >> etagging.log

but by using a sub-shell, we can do the same with a single `>>` indirection operator.

	( run a command
	  run another command
	  run one more command ) >> etagging.log
  
I'm using the `time` command to record the time spent processing each file, and this introduces some extra complexity. For one, I only want the real (perceived) time, and because I'm using the shell's `time` built-in, I need to set the `TIMEFORMAT` shell variable to acheive this.

Furthermore, `time` prints its results to stderr rather than stdout. If I simply used `>>` as above, the time stats would print to my terminal rather than to the logfile. To redirect stderr to the log file as well, the form changes to:

	( run a command
	  run another command
	  run one more command ) >> etagging.log 2>&1
  
You could read this as, "Run these commands in a sub-shell, send the sub-shell's standard output data to a log file, and send the standard error data to the same location you're sending the standard output."

The `2` and `1` above are "file-descriptors" that indicate stderr and stdout, respectively. Think of a file-descriptor as a numeric identifier associated with a particular stream of data. If you're familiar with pointers in C, you could think of `&1` as the location of stdout. Thus, `2>&1` says to redirect stderr to the same place that stdout is headed.

The order of the redirection commands is important. If we'd written,

	( run some commands ) 2>&1 >> etagging.log
	
then stderr would redirected to the same location as stdout (`2>&1`) *before* we'd changed stdout to point to the log file. It would be like saying, "Hey stderr, see the river stdout is headed towards? Go there. Hey stdout, change direction, go the that hilltop."

After the time stats have been generated, we want to include the size of the source file as well as of the generated tags file:

	( ls -l $f
	  ls -l tmp.TAGS ) | awk '{ print $5 }'
  
This produces long-format file-listings, and we pipe the results to `awk` to extract the 5th field from each line, which happens to the number of bytes in the file.

Once the script has run to completion, I'd like to sort the results by time and tag-size. The `sort` command expects newline-separated records with whitespace-separated fields. We can use `awk` to translate our results to the horizontal format `sort` expects.

	awk 'BEGIN { RS=""; FS="\n" } { print $1, $2, $3, $4 }' etagging.log

We're using a `BEGIN` block to set up awk's `RS` (record-separator) and `FS` (field-separator) variables, allowing it to correctly identify each record. The next block defines the actions we want to take on each record, namely to print each of its fields on a single line. We can pipe this into `sort` and generate stats sorted by time:

	awk 'BEGIN { RS=""; FS="\n" } { print $1, $2, $3, $4 }' etagging.log | sort -nrk2 > etagging-time

Here we're telling `sort` to sort numerically, in reverse order, treating the 2nd field (time) as the sort-key. We can do the same for tag file size, the 4th field:

	awk 'BEGIN { RS=""; FS="\n" } { print $1, $2, $3, $4 }' etagging.log | sort -nrk4 > etagging-size

Finally, we can take a look at what floated to the top.

	$ head -n 3 etagging-time
	app/models/taxi_edit.json 108.024 273517 8084569921
	vendor/assets/stylesheets/bootstrap/bootstrap.min.css 2.159 118153 288792277
	app/models/appointment.rb 0.252 10096 2481

	$ head -n 3 etagging-size
	app/models/taxi_edit.json 108.024 273517 8084569921
	vendor/assets/stylesheets/bootstrap/bootstrap.min.css 2.159 118153 288792277
	vendor/assets/stylesheets/intlTelInput.css 0.051 18194 5464144

As you can see, the top two offenders, both by time and by size, are a large json file and a minified bootstrap stylesheet, neither of which I have much interest in tagging. This shed some light on the performance disparity between universal-ctags and other tagging libraries, as universal-ctags recently added json support, so it was the only implementation tagging json at all.

A quick fix is to add json to the languages I exclude from tagging, but it begged the question, why didn't it have the same problem when run without the `-e` flag? Turns out the issue was extremely long lines in the source files. The tags file includes a source line reference, and it truncates these references when outputting *c*tags, but not when outputting *e*tags.

I reported the issue to the universal-ctags project (they were, in fact, very helpful during the debugging process as well).
