---
layout: post
title: "Shell: while loops and variables"
date: 2017-06-03 11:22
comments: true
categories: shell
---

A common idiom in shell scripting is to tweak the value of `IFS` (internal field separator) while reading lines of input:
```sh
while IFS= read -r line
do
    # ...
done
```
This leads to questions about `IFS` itself and the `-r` flag, and there are plenty of good answers out there. I'd like to focus, however, on the *syntax* of `IFS=` and it's location in the above line.

Shell variables can be assigned and referenced:
```sh
> var=A
> echo $var
A
```
Sometimes you want to set a variable for the duration of a single command:
```sh
> name=Bob bash -c 'echo $name'
Bob
> echo $name
 
```
At first glance, you might expect the first line of our `while` loop to look like:
```sh
IFS= while read -r line
```
but this causes a syntax error. In the `name=Bob` example, our entire line consisted of a single [simple command](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_01), defined as
> a sequence of optional variable assignments and redirections, in any sequence, optionally followed by words and redirections, terminated by a control operator.

The `while` loop, however, is a [compound command](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_04), with the format:
```
while compound-list-1
do
    compound-list-2
done
```
with `compound-list-1` being a sequence of [lists](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_03). A list is defined as
> a sequence of one or more AND-OR lists separated by the operators ';' and '&'.

with an `AND-OR` list being
> a sequence of one or more pipelines separated by the operators "&&" and "||" .

A [pipeline](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_02), in turn, has the format:
> [!] command1 [ | command2 ...]

It feels like we're going in circles, but the long and short of it is that we can view
```sh
while IFS= read -r line
```
as
```
while simple-command
```
Note that this means we're setting `IFS` to a temporary value only during the `read` command, not during the body of the loop.

To make this a little more concrete, here's a script I've called `while-vars.sh`:
```sh
var=A
i=1

tester() {
  echo "var in tester: $var"
  (( $i > 0 ))
}

echo -e "var before loop: $var\n"

while var=B tester; do
  let i-=1
  echo "var in loop: $var"
done

echo -e "\nvar after loop: $var"
```

The result:
```sh
> bash while-vars.sh
var before loop: A

var in tester: B
var in loop: A
var in tester: B

var after loop: A
```
