#! /bin/sh
# Import facts from ipcc-fact-checking into a MySQL database
#
# Usage:
# import.sh
#

echo "Update ipcc-fact-checking submodule (discarding local changes)"
git submodule update --init --force --quiet ipcc-fact-checking

cd ipcc-fact-checking

# Reference:
# "Get the short git version hash"
# http://stackoverflow.com/a/5694416
shortHash=$(git rev-parse --short HEAD)
echo "Read short hash of last commit: $shortHash"
