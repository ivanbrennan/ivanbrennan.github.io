---
layout: post
title: "Debugging etags"
date: 2016-12-20 07:52
comments: true
categories: 
---

I've been using ctags to navigate the codebases I work with in Vim for a couple years, largely thanks to a [blog post](http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html) by Tim Pope where he describes how to use git hooks to keep your tags up-to-date. Omitting a few details, the script I use boils down to this:

	git ls-files | ctags -L - -o ".git/tags" --tag-relative=yes --languages=-javascript,sql

On a large Rails app I've been working with, it takes 1 second and generates a 7MB tags file.

More recently, I started playing around with Emacs, and I've been looking for a way to port my tagging strategy over to *e*tags. There are a few ways you can generate etags. Emacs comes with its own `etags` executable, but the more featureful implementations of ctags can also generate them.

I've been using [universal-ctags](https://github.com/universal-ctags/ctags), which picked up where [exuberant-ctags](http://ctags.sourceforge.net) left off a few years ago, so I added `-e` to my tagging command and gave it a whirl. 90 seconds later it handed me an ***8GB*** tags file.

At first, I thought this must be a problem with the etags format itself, but when I tried Emacs' own `etags` executable, it took 13 seconds and produced a 3MB file. Next, I tried exuberant-ctags, which took 2 seconds and produced a 1MB file.

Narrowing in on the problem further was an interesting process that called on several shell-scripting concepts and tools, including I/O redirection, sub-shells, and `awk`.

## Benchmarking

First, I needed to gather some data profiling each file's contribution to execution time and tags-size. I wanted something like,

	some_file.rb <- source-file
	0.004        <- processing time (seconds)
	8159         <- source file-size (bytes)
	13389        <- tags file-size (bytes)

	another_file.rb
	0.002
	345
	4859

	...

I wrote a shell script to iterate through the files, generating tags for each and recording the time taken and resulting tags size, appending these stats to a log file.
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
I'll break this down a bit. First, we run `git ls-files` in a sub-shell to generate a list of files to loop through.

	for f in $(git ls-files)

For each file, we run some commands (`echo`, `time`, `ctags`, `ls`) and redirect their output to a log file. This could be done like,

	run a command >> etagging.log
	run another command >> etagging.log
	run one more command >> etagging.log

but using a sub-shell lets us capture it all in one go:

	( run a command
	  run another command
	  run one more command ) >> etagging.log
  
### Time and redirection

Using the `time` [builtin](https://en.wikipedia.org/wiki/Shell_builtin) to benchmark tags creation introduces a little more complexity. We only want the real (perceived) time, so we need to set the `TIMEFORMAT` shell variable accordingly.

Since `time` broadcasts its results through stderr rather than stdout, we can't rely on just `>>`, which redirects stdout, or our time data would print to screen rather than being recorded. So once we've redirected stdout to the log-file, we need to redirect stderr there as well.

	( run a command
	  run another command
	  run one more command ) >> etagging.log 2>&1
  
You could read this as,
> run commands in a sub-shell, send the sub-shell's standard output to the log-file, and send its standard error data to the same location you're sending the standard output (i.e. the log-file)

The digits in `2>&1` are [file descriptors](https://en.wikipedia.org/wiki/File_descriptor), indicating stderr (`2`) and stdout (`1`). A running process has 3 standard I/O streams through which to communicate. As a source of input, it has stdin (`0`); when it's ready to broadcast some output, it _generally_ sends that to stdout (`1`), but _some_ output is semantically different (e.g. error messages), and it's useful to have a separate stream for such data. This is where stderr (`2`) comes in.

If you're familiar with pointers in C, you could think of `&1` as the location of stdout, so `2>&1` says to redirect stderr to the same place that stdout is headed. The order of redirection operations is significant. If we'd written,

	( run some commands ) 2>&1 >> etagging.log
	
we'd be directing stderr to the same location as stdout and then directing stdout elsewhere. It would be like saying,
> Hey stderr, ask stdout where it's currently headed. Go there.

> Hey stdout, change of plans: I want you to go to this log-file.

### Space and a little awk

We also want to record the size of the source-file and the size of the tags-file. We use `awk` to extract these sizes (in bytes) from the 5th field of long-format `ls` file-listings:

	( ls -l $f
	  ls -l tmp.TAGS ) | awk '{ print $5 }'
  
## Sorting the results

Once I had the profiling data, I wanted to sort it by time and tag-size to see which files were causing the big slowdown and eating up my diskspace. The `sort` command expects newline-separated records with whitespace-separated fields. I used `awk` to translate the results to the horizontal format `sort` expects.

	awk 'BEGIN { RS=""; FS="\n" } { print $1, $2, $3, $4 }' etagging.log

The `BEGIN` block to sets up awk's `RS` (record-separator) and `FS` (field-separator) variables, allowing it to correctly identify each record. The next block defines the actions to take on each record. In this case I just want to print each of its fields on a single line. Piping this into `sort` generates results sorted by time:

	awk 'BEGIN { RS=""; FS="\n" } { print $1, $2, $3, $4 }' etagging.log | sort -nrk2 > etagging-time

Here I'm telling `sort` to sort numerically, in reverse order, treating the 2nd field as the sort-key. I did the same for tag file size, the 4th field:

	awk 'BEGIN { RS=""; FS="\n" } { print $1, $2, $3, $4 }' etagging.log | sort -nrk4 > etagging-size

## Identifying the Culprit

Here's what floated to the top:

	$ head -n 3 etagging-time
	app/models/something_big.json 108.024 273517 8084569921
	vendor/assets/stylesheets/bootstrap/bootstrap.min.css 2.159 118153 288792277
	app/models/appointment.rb 0.252 10096 2481

	$ head -n 3 etagging-size
	app/models/something_big.json 108.024 273517 8084569921
	vendor/assets/stylesheets/bootstrap/bootstrap.min.css 2.159 118153 288792277
	vendor/assets/stylesheets/intlTelInput.css 0.051 18194 5464144

The two top offenders, by both time and by size, were a large JSON file and a minified bootstrap stylesheet, neither of which I had much interest in tagging. The JSON file outshadowed everything else by miles, and that shed some light on the performance disparity between universal-ctags and the other tagging libraries: only universal-ctags had JSON support, so it was the only one tagging JSON at all.

A quick fix was to add JSON to the languages I exclude from tagging, but it begged the question, why didn't *c*tags exhibit the same problem as *e*tags?

The hint was hiding in that _minified_ stylesheet. The JSON file and the stylesheet had extremely long lines. Both ctags and etags include source line references, and these references get truncated to a reasonable length when generating *c*tags, but not when generating *e*tags.

### Conclusion

The team at [universal-ctags](https://github.com/universal-ctags/ctags) was incredibly helpful in debugging this and helped turn a source of frustration into a learning experience. They were quick to respond and are looking into resolving the underlying issue. In the meantime, I've adjusted my command for generating *e*tags.

	git ls-files | ctags -L - -e -o ".git/etags" --tag-relative=yes --languages=-javascript,sql,json,css
