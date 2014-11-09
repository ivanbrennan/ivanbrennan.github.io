---
layout: post
title: "unix know-how"
date: 2014-11-04 22:48
comments: true
categories: unix, sql
---
I was recently working with MySQL's timezone conversion capabilities and noticed that the following query didn't work when run against my local database (though it worked elsewhere):
```sql
SELECT CONVERT_TZ('2014-01-01 12:00:00', 'America/New_York', 'UTC');
=> null
```
The named timezones (`America/New_York`, `UTC`) weren't recognized, but if I specified timezones numerically, it worked as expected:
```sql
SELECT CONVERT_TZ('2014-01-01 12:00:00', '-5:00', '+00:00');
=> 2014-01-01 17:00:00
```
I hadn't loaded my system's zoneinfo files into the `mysql` database. I followed the [docs](http://dev.mysql.com/doc/refman/5.5/en/time-zone-support.html) and ran the `mysql_tzinfo_to_sql` utility to do so:
```bash
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
```
Midway through loading the tables, `mysql_tzinfo_to_sql` failed with: "ERROR 1406 (22001) at line 38408: Data too long for column 'Abbreviation' at row 1". A coworker suggested I write the command's output to a file so I could see the problem:
```bash
mysql_tzinfo_to_sql /usr/share/zoneinfo > debuggingfile
```
This produced a file of SQL insert statements, with the problematic code on line 38408:
```sql
INSERT INTO time_zone_transition_type (Time_zone_id, Transition_type_id, Offset, Is_DST, Abbreviation) VALUES (@time_zone_id, 0, 0, 0, 'Local time zone must be set--see zic manual page');
```
Clearly, the `'Local time zone must be set--see zic manual page'` value was too long for the Abbreviation column. I shortened it to `'unset'`, fed the file into mysql, and all was well.
```bash
mysql -u root mysql < debuggingfile
```

I was struck by the simplicity of this solution, and how a little unix know-how can demystify a problem.
