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

echo "Remove untracked files from ipcc-fact-checking submodule"
cd ipcc-fact-checking
git clean -df
cd ..

echo "Update ipcc-fact-checking submodule (discarding local changes)"
git submodule update --init --force --quiet ipcc-fact-checking

# Reference:
# "Get the short git version hash"
# http://stackoverflow.com/a/5694416
cd ipcc-fact-checking
shortHash=$(git rev-parse --short HEAD)
echo "Read short hash of last commit: $shortHash"
cd ..

echo "Create SQL script import.sql"
cat << EOF > ../import.sql
-- create database ipcc_facts
CREATE DATABASE IF NOT EXISTS ipcc_facts
DEFAULT CHARACTER SET utf8
;
EOF

echo "Complete. You can now run import.sql to perform the actual import."
