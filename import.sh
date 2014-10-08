#! /bin/sh
# Create SQL script import.sql to import facts from ipcc-fact-checking
# into a MySQL database. The SQL script shall run separately to perform
# the actual import.
#
# Usage:
# import.sh
#

echo "Change to parent directory of the script"
cd $(dirname $0)
echo "Current directory: $(pwd)"

# Reference:
# Update a submodule to the latest commit
# http://stackoverflow.com/a/8191413
echo "Remove untracked files from ipcc-fact-checking submodule"
cd ipcc-fact-checking
git clean -df
git checkout master
echo "Update ipcc-fact-checking to latest commit"
git pull origin master
cd ..

# Reference:
# "Get the short git version hash"
# http://stackoverflow.com/a/5694416
cd ipcc-fact-checking
commit=$(git rev-parse --short HEAD)
echo "Read short hash of last commit: $commit"
cd ..

echo "Create SQL script import.sql"
cat << EOF > import.sql
-- create database ipcc_facts
CREATE DATABASE IF NOT EXISTS ipcc_facts
DEFAULT CHARACTER SET utf8
;
USE ipcc_facts

-- create table facts
CREATE TABLE IF NOT EXISTS facts (
  commit CHAR(7) NOT NULL
  COMMENT 'hash of latest commit in ipcc-fact-checking',
  source VARCHAR(30) NOT NULL
  COMMENT 'first-level folder name in ipcc-fact-checking',
  document VARCHAR(40) NOT NULL
  COMMENT 'second-level folder name in ipcc-fact-checking',
  dataset VARCHAR(30) NOT NULL
  COMMENT 'third-level folder name in ipcc-fact-checking',
  line SMALLINT UNSIGNED NOT NULL
  COMMENT 'line number in data.csv, or 0 for meta.txt',
  name VARCHAR(30) NOT NULL
  COMMENT 'column header in data.csv, property name in meta.txt',
  value VARCHAR(1000) NOT NULL
  COMMENT 'field value in data.csv, property value in meta.txt',
  PRIMARY KEY USING HASH (
    commit, source, document, dataset, line, name
  )
)
;

-- insert facts
INSERT INTO facts
VALUES
EOF

identify()
{
  echo "File: $1"
  source=$(dirname "$1")
  dataset=$(basename "$source")
  source=$(dirname "$source")
  document=$(basename "$source")
  source=$(dirname "$source")
  source=$(basename "$source")
#  cat << EOF
#commit: $commit
#source: $source
#document: $document
#dataset: $dataset
#EOF
}

factSeparator=' '

addFact()
{
  echo \
    "$factSeparator (" \
      "'$commit'," \
      "'$source'," \
      "'$document'," \
      "'$dataset'," \
      "$line," \
      "'$name'," \
      "\"$value\"" \
    ')' \
    >> import.sql
  factSeparator=','
}

addMetaFact()
{
  line=0
  name=${1%%": "*}
  value=${1#*": "}
  addFact
}

addMetaFacts()
{
  while read metaLine
  do
    case $metaLine in
      *": "*) addMetaFact "$metaLine";;
      # stop on first empty line
      "") break
    esac
  done < "$1"
}

echo "Gather facts from meta.txt files"
for meta in ipcc-fact-checking/*/*/*/meta.txt
do
  identify "$meta"
  addMetaFacts "$meta"
done

echo "Gather facts from data.csv files"
for data in ipcc-fact-checking/*/*/*/data.csv
do
  identify "$data"
done

echo ';' >> import.sql

echo "Complete. You can now run import.sql to perform the actual import."
