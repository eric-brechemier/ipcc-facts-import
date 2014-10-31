#! /bin/sh
# Create SQL script import.sql to import facts from ipcc-fact-checking
# into a MySQL database. The SQL script shall run separately to perform
# the actual import.
#
# Usage:
# import.sh
#

# Config: size of database fields in characters
commitMaxSize=7
sourceMaxSize=30
documentMaxSize=35
datasetMaxSize=35
nameMaxSize=30
valueMaxSize=1100

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

#-- drop table (uncomment to apply new definition)
#DROP TABLE facts;

-- create table facts
CREATE TABLE IF NOT EXISTS facts (
  commit CHAR($commitMaxSize) NOT NULL
  COMMENT 'hash of latest commit in ipcc-fact-checking',
  source VARCHAR($sourceMaxSize) NOT NULL
  COMMENT 'first-level folder name in ipcc-fact-checking',
  document VARCHAR($documentMaxSize) NOT NULL
  COMMENT 'second-level folder name in ipcc-fact-checking',
  dataset VARCHAR($datasetMaxSize) NOT NULL
  COMMENT 'third-level folder name in ipcc-fact-checking',
  line SMALLINT UNSIGNED NOT NULL
  COMMENT 'line number in data.csv, or 0 for meta.txt',
  name VARCHAR($nameMaxSize) NOT NULL
  COMMENT 'column header in data.csv, property name in meta.txt',
  value VARCHAR($valueMaxSize) NOT NULL
  COMMENT 'field value in data.csv, property value in meta.txt',
  PRIMARY KEY USING HASH (
    commit, source, document, dataset, line, name
  )
)
;

-- insert facts
EOF

logError()
{
  echo "ERROR: $1"
}

checkSize()
{
  if test "${#2}" -gt "$3"
  then
    logError "$1 '$2' has ${#2} characters > maximum expected: $3"
  fi
}

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
  checkSize 'Commit' "$commit" $commitMaxSize
  checkSize 'Source' "$source" $sourceMaxSize
  checkSize 'Document' "$document" $documentMaxSize
  checkSize 'Dataset' "$dataset" $datasetMaxSize
}

insertFact='INSERT INTO facts VALUES'

addFact()
{
  checkSize 'Fact Name' "$name" $nameMaxSize
  checkSize 'Fact Value' "$value" $valueMaxSize
  echo \
    "$insertFact (" \
      "'$commit'," \
      "'$source'," \
      "'$document'," \
      "'$dataset'," \
      "$line," \
      "'$name'," \
      "\"$value\"" \
    ');' \
    >> import.sql
}

parseMetaLine()
{
  line=0
  name=${1%%": "*}
  value=${1#*": "}
  addFact
}

parseMetaFile()
{
  # Reference:
  # Shell script read missing last line
  # http://stackoverflow.com/a/12919766

  # Read file line by line, including last line without EOF
  while read -r metaLine || test -n "$metaLine"
  do
    case $metaLine in
      *": "*) parseMetaLine "$metaLine";;
      # stop on first empty line
      "") break
    esac
  done < "$1"
}

# Reference:
# Split() is Not Always The Best Way to Split a String
# http://www.regexguru.com/2009/04/split-is-not-always-the-best-way-to-split-a-string/

discardEndOfDataLine()
{
  # skip the rest of the line
  headerFields=''
}

parseDataField()
{
  case "$headerFields" in
    # quoted field
    \"*)
      # discard initial quote character
      headerFields=${headerFields#\"}
      # field ends with ",
      endOfField='\",'
    ;;
    # unquoted field
    *)
      # field ends with ,
      endOfField=','
  esac
  case "$headerFields" in
    *$endOfField*)
      name=${headerFields%%$endOfField*}
      headerFields=${headerFields#$name$endOfField}
    ;;
    *)
      logError "End of field '$endOfField' not found in '$headerFields'"
      discardEndOfDataLine
      return
  esac

  case "$dataFields" in
    # quoted field
    \"*)
      dataFields=${dataFields#\"}
      endOfField='\",'
    ;;
    # unquoted field
    *)
      endOfField=','
  esac
  case "$dataFields" in
    *$endOfField*)
      value=${dataFields%%$endOfField*}
      dataFields=${dataFields#$value$endOfField}
    ;;
    *)
      logError "End of field '$endOfField' not found in '$dataFields'"
      discardEndOfDataLine
      return
  esac

  # skip empty values
  if test -n "$value"
  then
    addFact
  fi
}

parseDataLine()
{
  dataFields="$1"
  headerFields="$2"

  until test -z "$headerFields"
  do
    parseDataField
  done
}

parseDataFile()
{
  line=0

  # Read file line by line, including last line without EOF
  while read -r dataLine || test -n "$dataLine"
  do
    line=$(($line + 1))
    if test "$line" -eq 1
    then
      headers="$dataLine"
    fi
    case $dataLine in
      # line with at list one value
      # parse the data row and headers,
      # with a final ',' added to simplify parsing
      *[!,]*) parseDataLine "$dataLine," "$headers,";;
      # only commas: no value
      *) continue
    esac
  done < "$1"
}

echo "Gather facts from meta.txt files"
for meta in ipcc-fact-checking/*/*/*/meta.txt
do
  identify "$meta"
  parseMetaFile "$meta"
done

echo "Gather facts from data.csv files"
for data in ipcc-fact-checking/*/*/*/data.csv
do
  identify "$data"
  parseDataFile "$data"
done

echo ';' >> import.sql

echo "Facts from commit '$commit' are ready for import."
echo "You can now run import.sql to perform the actual import."
