# FAERS importer
This is a shell script to convert data in the [FDA adverse drug reactions database](https://www.fda.gov/drugs/questions-and-answers-fdas-adverse-event-reporting-system-faers/fda-adverse-event-reporting-system-faers-public-dashboard) ASCII exports into a mysql database.
## About
The FDA adverse drug reaction database is a world-wide repository of adverse drug reactions maintained by the American Food and Drug agency.

## This project
This is a shell (bash) script that will download the files, and create a database using mysql to store the imported data.

The FAERS database stores ages in Days, Weeks, Months, Years and Decades.  The importer has a *best guess* at converting these ages into years. Ages outside the range of 0 and 120 years are converted to null.

Event dates in FAERS can be recorded as Year, Year/Month or Year/Month/Day. This importer convert these dates to YYYYMMDD, assuming the soonest value possible.

The database uses the concept of a case id and revisions to get a primary key. There can be more than one primary key in the database, so this importer works out if a row is the `latest` version of a case.

None of the original data in this table is mutated.  Separate fields are created.

Make sure that any queries on the demographics table check the latest flag.

## Data accuracy
The FAERS database enjoys almost no data-validation on entry, expect ages > 450 years, event times in the year 1010. the importer tries to filter out impossible values, but only for fields I was interested in. Many (>40%) entries in the demographics table don't have **any** event date time, making this a not-very useful field to use.

It is possble to write queries that should replicate the values obtained by the [FEARS dashboard](https://fis.fda.gov/sense/app/95239e26-e0be-42d9-a960-9a5f7f1c25ee/sheet/7a47a261-d58b-4203-a8aa-6d3021737452/state/analysis).  The outputs of the queries run on this database enjoy no similarities with the dashboard values. For example the dashboard reports that there were 1,805,349 reports in 2017. My table showed 1,251,747 rows in 2017. Clearly something is wrong there.

## Speed
This database gets big, and the FAERS data is slow to download. expect this script to take a long time to run.

## Software requirements

In order to run this script you will be expected to have proficiency with bash scripting, have the following packages installed:
 - pv # pipe viewer
 - mysql
   - mysql is used with the syntax --login-path.  see [the documentation](https://dev.mysql.com/doc/refman/8.0/en/mysql-config-editor.html) for notes on how to set up. The mysql user chosen will require the super privilege to create databases/tables.
   - mysql also has to have load data infile working. you may need to update your mysql.cnf file to get this working. I had to add the line `secure_file_priv = ""` in the [mysqld] section of my mysql.cnf file.

## Help and support
This project is offered as-is and no support will be given. I had to do this for my work.  I first of all tried [this project](https://github.com/kylechua/faers-toolkit). But after a few days i found that it had issues and it was best to start again.  It took several days to create and I thought that this might be useful.

If you find an issue and have a fix, then report it.
