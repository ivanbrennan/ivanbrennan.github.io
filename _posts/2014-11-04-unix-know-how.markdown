---
layout: post
title: "unix know-how"
date: 2014-11-04 22:48
comments: true
categories: unix, sql
---
I was working with MySQL queries that involved timezone conversion when I noticed that my local instance of MySQL didn't recognize named timezones. Queries with named timezones were returning `null`, while those with numeric offsets from UTC were returning correct conversions:

    > SELECT CONVERT_TZ('2014-01-01 12:00:00', 'America/New_York', 'UTC');
    => null

    > SELECT CONVERT_TZ('2014-01-01 12:00:00', '-5:00', '+00:00');
    => 2014-01-01 17:00:00

I hadn't loaded my system's zoneinfo files into the `mysql` database. As per the [docs](http://dev.mysql.com/doc/refman/5.5/en/time-zone-support.html), I used the `mysql_tzinfo_to_sql` utility to load them from `/usr/share/zoneinfo`:

    $ mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

The process failed before loading all the tables:

    ERROR 1406 (22001) at line 38408: Data too long for column 'Abbreviation' at row 1

Now I could reference `America/New_York`, but not `UTC`, since the process had failed before loading that table. A coworker suggested I write the command's output to a file so I could debug:

    $ mysql_tzinfo_to_sql /usr/share/zoneinfo > debuggingfile

The `debuggingfile` contained many insert statements, and line 38408 revealed the problem:

    INSERT INTO time_zone_transition_type (Time_zone_id, Transition_type_id, Offset, Is_DST, Abbreviation) VALUES (@time_zone_id, 0, 0, 0, 'Local time zone must be set--see zic manual page');

The `'Local time zone must be set--see zic manual page'` value was too long for the Abbreviation column. I shortened it to `'unset'`, fed the file into mysql, and all was well.

    $ mysql -u root mysql < debuggingfile


I was struck by the simplicity of this solution, and how a little unix know-how can demystify a problem.
