#!/bin/bash

# setup and required installs
#  pv -- pipe viewer
#  mysql
# the mysql option --login-path  see this for how to set up https://dev.mysql.com/doc/refman/8.0/en/mysql-config-editor.html
# is required to connect to the mysql database the login-path profile requires the create database and super privileges
# update the mysql.cnf to have secure_file_priv = "" in the [mysqld] section to allow load data infile to work.

function get_faers_data() {
  mkdir data 2>/dev/null # make a directory
  echo "$(date) starting download of faers files, expect this to take at least two hours"
  curl https://fis.fda.gov/content/Exports/faers_ascii_2017q1.zip --output data/faers_ascii_2017Q1.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2017q2.zip --output data/faers_ascii_2017Q2.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2017q3.zip --output data/faers_ascii_2017Q3.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2017q4.zip --output data/faers_ascii_2017Q4.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2018q1.zip --output data/faers_ascii_2018Q1.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2018q2.zip --output data/faers_ascii_2018Q2.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2018q3.zip --output data/faers_ascii_2018Q3.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2018q4.zip --output data/faers_ascii_2018Q4.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2019Q1.zip --output data/faers_ascii_2019Q1.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2019Q2.zip --output data/faers_ascii_2019Q2.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2019Q3.zip --output data/faers_ascii_2019Q3.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2019Q4.zip --output data/faers_ascii_2019Q4.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2020Q1.zip --output data/faers_ascii_2020Q1.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2020Q2.zip --output data/faers_ascii_2020Q2.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2020Q3.zip --output data/faers_ascii_2020Q3.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2020Q4.zip --output data/faers_ascii_2020Q4.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2021Q1.zip --output data/faers_ascii_2021Q1.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2021Q2.zip --output data/faers_ascii_2021Q2.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2021Q3.zip --output data/faers_ascii_2021Q3.zip
  curl https://fis.fda.gov/content/Exports/faers_ascii_2021Q4.zip --output data/faers_ascii_2021Q4.zip
}

function unzip_faers_data(){
  echo "$(date) uncompressing faers data, expect this to take 10 minutes"
  for file in demographic.txt drug.txt indication.txt outcome.txt reaction.txt source.txt therapy.txt
  do
    rm $file 2> /dev/null
    touch $file
  done
  for folder in 2017q1 2017q2 2017q3 2017q4 2018q1 2018q2 2018q3 2018q4 2019Q1 2019Q2 2019Q3 2019Q4 2020Q1 2020Q2 2020Q3 2020Q4 2021Q1 2021Q2 2021Q3 2021Q4
  do
    rm -rf "data/${folder}" 2> /dev/null
    unzip "data/faers_ascii_${folder}.zip" -d "data/${folder}/"
    # fix an annoying file naming issue in 2018Q1
    mv data/2018q1/ASCII/DEMO18Q1_new.txt data/2018q1/ASCII/DEMO18q1.txt 2> /dev/null
    # remove the first 2 chars from $folder
    f="${folder:2}"
    # tail -n +2 ignores the first line of a file.
    # iconv -c option skips invalid sequences - there are bad utf-8 chars in the file.
    tail -n +2  "data/${folder}/ASCII/DEMO${f}.txt" | iconv --from utf-8 --to utf-8 -c >> demographic.txt
    tail -n +2  "data/${folder}/ASCII/DRUG${f}.txt" | iconv --from utf-8 --to utf-8 -c >> drug.txt
    tail -n +2  "data/${folder}/ASCII/INDI${f}.txt" | iconv --from utf-8 --to utf-8 -c >> indication.txt
    tail -n +2  "data/${folder}/ASCII/OUTC${f}.txt" | iconv --from utf-8 --to utf-8 -c >> outcome.txt
    tail -n +2  "data/${folder}/ASCII/REAC${f}.txt" | iconv --from utf-8 --to utf-8 -c >> reaction.txt
    tail -n +2  "data/${folder}/ASCII/RPSR${f}.txt" | iconv --from utf-8 --to utf-8 -c >> source.txt
    tail -n +2  "data/${folder}/ASCII/THER${f}.txt" | iconv --from utf-8 --to utf-8 -c >> therapy.txt
  done
}

function create_schema() {
  echo "$(date) creating the mysql database and schema"
  echo "drop database if exists faers;" > schema.sql
  echo 'CREATE DATABASE faers;' >> schema.sql
  echo 'use faers;' >>schema.sql
  echo "CREATE TABLE DEMOGRAPHIC
        (
          id               INT UNSIGNED     NOT NULL AUTO_INCREMENT,
          PRIMARYID        BIGINT UNSIGNED           DEFAULT NULL,
          CASEID           bigint UNSIGNED           DEFAULT NULL,
          CASEVERSION      int                       DEFAULT NULL,
          latest           TINYINT UNSIGNED NOT NULL DEFAULT 0,
          age_years        TINYINT UNSIGNED null     default null,
          wt_kg            float UNSIGNED   null     default null,
          year_quarter     char(6)          null     default null,
          I_F_COD          char(1)          null     DEFAULT NULL,
          EVENT_DT         char(8)          null     DEFAULT NULL,
          EVENT_DT8         char(8)          null     DEFAULT NULL,
          MFR_DT           char(8)          null     DEFAULT NULL,
          INIT_FDA_DT      char(8)          null     DEFAULT NULL,
          FDA_DT           char(8)          null     DEFAULT NULL,
          REPT_COD         char(3)          null     DEFAULT NULL,
          AUTH_NUM         varchar(100)     null,
          MFR_NUM          varchar(100)     null     DEFAULT NULL,
          MFR_SNDR         varchar(100)     null     DEFAULT NULL,
          LIT_REF          varchar(500)     null     DEFAULT NULL,
          AGE              char(10)         null     DEFAULT NULL,
          AGE_COD          char(3)          null     DEFAULT NULL,
          AGE_GRP          char(1)          null     DEFAULT NULL,
          SEX              char(3)          null     DEFAULT NULL,
          GNDR_COD         char(1)          null     DEFAULT NULL,
          E_SUB            char(1)          null     DEFAULT NULL,
          WT               char(100)        NULL     DEFAULT NULL,
          WT_COD           char(3)          NULL     DEFAULT NULL,
          REPT_DT          char(8)          null     DEFAULT NULL,
          REPT_DT8         char(8)          null     DEFAULT NULL,
          OCCP_COD         char(2)          null     DEFAULT NULL,
          TO_MFR           char(1)          NULL     DEFAULT NULL,
          REPORTER_COUNTRY varchar(50)      NULL     DEFAULT NULL,
          OCCR_COUNTRY     char(2)          null     DEFAULT NULL,
          PRIMARY KEY id (id),
          KEY AGE_COD (AGE_COD),
          KEY CASEID (CASEID),
          KEY EVENT_DT (EVENT_DT),
          KEY EVENT_DT8 (EVENT_DT8),
          KEY MFR_DT (MFR_DT),
          KEY REPT_DT (REPT_DT),
          KEY REPT_DT8 (REPT_DT8),
          KEY SEX (SEX),
          KEY age_years (age_years),
          KEY latest (latest),
          KEY year_quarter (year_quarter)
        ) ENGINE = InnoDB;" >>schema.sql
  echo "CREATE TABLE INDICATION (
          id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
          PRIMARYID     BIGINT UNSIGNED NULL DEFAULT NULL,
          CASEID        bigint UNSIGNED NULL DEFAULT NULL,
          DRUG_SEQ      int     null  DEFAULT NULL,
          INDI_DRUG_SEQ int     null  DEFAULT NULL COMMENT 'Drug sequence number for identifying a drug for a Case',
          INDI_PT       varchar(100)         DEFAULT NULL,
          PRIMARY KEY id (id),
          KEY CASEID (CASEID),
          KEY DRUG_SEQ (DRUG_SEQ),
          KEY INDI_DRUG_SEQ (INDI_DRUG_SEQ)
        ) ENGINE = InnoDB;" >>schema.sql
  echo "CREATE TABLE OUTCOME
        (
          id        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
          PRIMARYID BIGINT UNSIGNED NULL DEFAULT NULL,
          CASEID    bigint UNSIGNED NULL DEFAULT NULL,
          OUTC_COD  char(2)              DEFAULT NULL COMMENT 'DE=Death,LT=Life-Threatening,HO=Hospitalization - Initial or Prolonged,DS=Disability,CA=Congenital Anomaly,RI=Required Intervention to Prevent Permanent,OT=Other Serious (Important Medical Event)',
          has_death tinyint unsigned NOT NULL DEFAULT 0,
          PRIMARY KEY id (id),
          KEY CASEID (CASEID),
          KEY OUTC_COD (OUTC_COD),
          KEY has_death (has_death)
        ) ENGINE = InnoDB;" >>schema.sql
  echo "CREATE TABLE REACTION
        (
          id           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
          PRIMARYID    BIGINT UNSIGNED NULL DEFAULT NULL,
          CASEID       bigint UNSIGNED NULL DEFAULT NULL,
          PT           text COMMENT 'Preferred Term',
          DRUG_REC_ACT varchar(100)         DEFAULT NULL COMMENT 'Drug Recur Action data - populated with reaction/event information (PT) if/when the event reappears upon re administration of the drug.',
          PRIMARY KEY id (id),
          KEY CASEID (CASEID),
          KEY DRUG_REC_ACT (DRUG_REC_ACT)
        ) ENGINE = InnoDB;" >>schema.sql
  echo "CREATE TABLE SOURCE
      (
        id        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
        PRIMARYID BIGINT UNSIGNED NULL DEFAULT NULL,
        CASEID    bigint UNSIGNED NULL DEFAULT NULL,
        RPSR_COD  char(3)              DEFAULT NULL COMMENT 'FGN=Foreign,SDY=Study,LIT=Literature,CSM=Consumer,HP=HealthProfessional,UF=UserFacility,CR=CompanyRepresentative,DT=Distributor,OTH=Other',
        PRIMARY KEY id (id),
        KEY CASEID (CASEID),
        KEY RPSR_COD (RPSR_COD)
      ) ENGINE = InnoDB;" >>schema.sql
  echo "CREATE TABLE THERAPY
      (
        id        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
        PRIMARYID BIGINT UNSIGNED NULL DEFAULT NULL,
        CASEID    bigint UNSIGNED NULL DEFAULT NULL,
        DRUG_SEQ  int                  DEFAULT NULL,
        START_DT  char(8)              DEFAULT NULL,
        END_DT    char(8)              DEFAULT NULL,
        DUR       char(5)              DEFAULT NULL,
        DUR_COD   char(3)              DEFAULT NULL COMMENT 'YR=Years,MON=Months,WK=Weeks,DAY=Days,HR=Hours,MIN=Minutes,SEC=Seconds',
        PRIMARY KEY id (id),
        KEY CASEID (CASEID),
        KEY DRUG_SEQ (DRUG_SEQ),
        KEY START_DT (START_DT),
        KEY END_DT (END_DT),
        KEY DUR (DUR),
        KEY DUR_COD (DUR_COD)
      ) ENGINE = InnoDB;" >>schema.sql
    echo "CREATE TABLE DRUG (
        id int unsigned NOT NULL AUTO_INCREMENT,
        PRIMARYID bigint unsigned DEFAULT NULL,
        CASEID bigint unsigned DEFAULT NULL,
        DRUG_SEQ int DEFAULT NULL,
        ROLE_COD char(2) DEFAULT NULL,
        DRUGNAME varchar(255) DEFAULT NULL,
        PROD_AI varchar(300) DEFAULT NULL,
        VAL_VBM int DEFAULT NULL,
        ROUTE varchar(50) DEFAULT NULL,
        DOSE_VBM varchar(250) DEFAULT NULL,
        CUM_DOSE_CHR char(10) DEFAULT NULL,
        CUM_DOSE_UNIT char(5) DEFAULT NULL,
        DECHAL char(1) DEFAULT NULL,
        RECHAL char(1) DEFAULT NULL,
        LOT_NUM varchar(200) DEFAULT NULL COMMENT 'Lot number of the drug',
        EXP_DT varchar(200) DEFAULT NULL COMMENT 'Expiration date of the drug. (YYYYMMDD format) - If a complete date   is not available, a partial date is provided',
        NDA_NUM varchar(50) DEFAULT NULL COMMENT 'NDA number',
        DOSE_AMT char(10) DEFAULT NULL COMMENT 'Amount of drug reported',
        DOSE_UNIT varchar(10) DEFAULT NULL COMMENT 'Unit of drug dose',
        DOSE_FORM varchar(50) DEFAULT NULL COMMENT 'Form of dose reported',
        DOSE_FREQ varchar(10) DEFAULT NULL COMMENT 'Code for Frequency',
        PRIMARY KEY (id),
        KEY CASEID (CASEID),
        KEY DRUG_SEQ (DRUG_SEQ)
      ) ENGINE=InnoDB" >>schema.sql
  mysql --login-path=root <schema.sql
}


function import_mysql_data() {
 echo "$(date) importing the data, expect this to take a long time."
 import_mysql_data_demographic
 import_mysql_data_drug
 import_mysql_data_indication
 import_mysql_data_outcome
 import_mysql_data_reaction
 import_mysql_data_source
 import_mysql_data_therapy
}

function import_mysql_data_demographic() {
  table=demographic
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' IGNORE INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID, CASEID, CASEVERSION, I_F_COD, EVENT_DT, MFR_DT, INIT_FDA_DT, FDA_DT, REPT_COD, AUTH_NUM, MFR_NUM, MFR_SNDR, LIT_REF, AGE, AGE_COD, AGE_GRP, SEX, E_SUB, WT, WT_COD, REPT_DT, TO_MFR, OCCP_COD, REPORTER_COUNTRY, OCCR_COUNTRY);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}

function import_mysql_data_drug() {
  table=drug
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' IGNORE INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID,CASEID,DRUG_SEQ,ROLE_COD,DRUGNAME,PROD_AI,VAL_VBM,ROUTE,DOSE_VBM,CUM_DOSE_CHR,CUM_DOSE_UNIT,DECHAL,RECHAL,LOT_NUM,EXP_DT,NDA_NUM,DOSE_AMT,DOSE_UNIT,DOSE_FORM,DOSE_FREQ);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}

function import_mysql_data_indication() {
  table=indication
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID, CASEID, INDI_DRUG_SEQ, INDI_PT);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}

function import_mysql_data_outcome() {
  table=outcome
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID, CASEID, OUTC_COD);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}

function import_mysql_data_reaction() {
  table=reaction
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID, CASEID,PT,DRUG_REC_ACT);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}

function import_mysql_data_source() {
  table=source
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID, CASEID,RPSR_COD);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}

function import_mysql_data_therapy() {
  table=therapy
  echo "$(date) Importing file ${table}.txt which has $(wc -l < ${table}.txt) lines"
  file="$(pwd)/${table}.txt"
  mysql --login-path=root -e "SET foreign_key_checks=0;LOAD DATA INFILE '${file}' INTO TABLE ${table} FIELDS TERMINATED BY '$' (PRIMARYID, CASEID,DRUG_SEQ,START_DT, END_DT, DUR, DUR_COD);SET foreign_key_checks=1;" faers
  echo "After importing, found `mysql --login-path=root -s -e "select count(*) from ${table};" faers` rows in table ${table}"
}


function fixes() {
  echo "SET foreign_key_checks=0;" > fixes.sql
  # now set the latest=1 for the most recent row in the demographics table.
  # primaryid is a composite key from the caseid and the caseversion fields.
  # first find the maximum version of each caseid, then handle duplicates of the primaryid
  # find last primary id (the one that has the largest id)
  # shellcheck disable=SC2129
  echo "update DEMOGRAPHIC
  inner join (
    select primaryid, max(id) max_id
    from DEMOGRAPHIC
    inner join (
      select caseid, max(CASEVERSION) max_version
      from DEMOGRAPHIC
      group by caseid) ij on concat(ij.caseid,ij.max_version) = DEMOGRAPHIC.primaryid
    group by primaryid
    ) oj on oj.max_id = demographic.id
  set latest = 1;" >>fixes.sql
  echo "UPDATE DEMOGRAPHIC set
      event_dt8 = CASE WHEN event_dt='' THEN NULL WHEN length(event_dt) = 4 THEN concat(event_dt,'0101') WHEN length(event_dt)=6 THEN concat(event_dt,'01') ELSE event_dt END,
      year_quarter = concat(substr(INIT_FDA_DT,1,4),'Q',quarter(init_fda_dt)),
      wt_kg = if(wt>0 && wt_cod='lbs', round(wt/2.2,2),if (wt>0,round(wt,2),null));
      " >> fixes.sql
  echo "UPDATE DEMOGRAPHIC
        set age_years =
        case
         when age = null then null
         when age < 0 then null
         when age = '' then null
         when age_cod = 'YR'  then if(age>120,null,age)
         when age_cod = 'DEC' then if(age*10>120,null,age*10)
         when age_cod = 'MON' then if(age/12>120,null,round(age / 12,0))
         when age_cod = 'WK'  then if(age/52>120,null,round(age / 52,0))
         when age_cod = 'DY'  then if(age/365.25>120,null,round(age / 365.25,0))
         else age
         end;" >> fixes.sql

  # work out outcomes that include death.
  echo "update outcome
              inner join (
              select distinct primaryid
              from outcome
              where outc_cod='DE'
              ) t on t.primaryid = outcome.primaryid
              set outcome.has_death = 1;" >> fixes.sql
  echo "SET foreign_key_checks=1;" >> fixes.sql
  echo "$(date) Apply fixes"
  pv fixes.sql | mysql --login-path=root faers
}

#tidy up temporary files.
function tidy_up() {
  rm DEMOGRAPHIC.txt 2>/dev/null
  rm DRUG.txt 2>/dev/null
  rm INDICATION.txt 2>/dev/null
  rm OUTCOME.txt 2>/dev/null
  rm REACTION.txt 2>/dev/null
  rm SOURCE.txt 2>/dev/null
  rm THERAPY.txt 2>/dev/null
  rm dump.txt 2>/dev/null
  rm schema.txt 2>/dev/null
  rm fixes.txt 2>/dev/null
  echo " ## now run the query and expect it take 11 minutes.
  select year_quarter,
  	sum(if(sex='M' and all_outcomes.primaryid is null, 1,0)) male_non_serious,
  	sum(if(sex='M' and serious_outcomes.primaryid >0,1,0)) male_serious,
  	sum(if(sex='M' and death_outcomes.primaryid>0,1,0)) male_death,
    sum(if(sex='F' and all_outcomes.primaryid is null, 1,0)) female_non_serious,
  	sum(if(sex='F' and serious_outcomes.primaryid >0,1,0)) female_serious,
  	sum(if(sex='F' and death_outcomes.primaryid>0 ,1,0)) female_death
  FROM demographic
  LEFT JOIN (select distinct primaryid from outcome) all_outcomes on all_outcomes.primaryid = demographic.primaryid
  LEFT JOIN (select distinct primaryid from outcome where outc_cod='DE') death_outcomes ON death_outcomes.primaryid = demographic.primaryid
  LEFT JOIN (select distinct primaryid from outcome where has_death=0) serious_outcomes ON serious_outcomes.primaryid = demographic.primaryid
  WHERE demographic.latest = 1 and age_years between 18 and 35
  GROUP BY year_quarter
  order by year_quarter;"
}

echo "$(date) Faers Script starts"
get_faers_data
unzip_faers_data
create_schema
import_mysql_data
fixes
tidy_up
echo "$(date) Script ends"
