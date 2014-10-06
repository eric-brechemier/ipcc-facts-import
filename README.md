ipcc-facts-import
=================

GOAL: to import data and metadata
from ipcc-fact-checking project
to a MySQL database

## Project Description

The project ipcc-fact-checking is a collection of facts (data.csv files)
and associated metadata (meta.txt files) related to IPCC authors.

This project, ipcc-facts-import, defines a process to import data
and metadata to a MySQL database, into a database `ipcc_facts_imports`
with a single table `facts` where records have the following structure:

  * short hash of the HEAD commit,
  retrieved with `git rev-parse --short HEAD` run in the submodule
  ipcc-fact-checking at the time of import

  * source domain name (grandgrandparent folder name)

  * document identifier (grandparent folder name)

  * dataset identifier (parent folder name)

  * line number
  (0 for metadata, 1 for column headers, and greater for data records)

  * name (tag name for metadata, column header for data records)

  * value (tag value for metadata, column value for data records)

One record is inserted for each line before the first empty line
in meta.txt files (description is located after an empty line,
and thus skipped) and for each value of each record in data.csv files
(lines with empty values only are counted in the offset but skipped).

In a refinement step, records with multiple values
(e.g. `'Tags'`, `'Name (Country)'`) get split into multiple records
with the same source, a new name  (`'Tag'`, `'Name'` and `'Country'`
in the example) and separate values.

## Attribution

[MEDEA Project][MEDEA]
[CC-BY][] [Arts Déco][Arts Deco] & [Sciences Po][Medialab]

[MEDEA]: http://www.projetmedea.fr/
[CC-BY]: https://creativecommons.org/licenses/by/4.0/
         "Creative Commons Attribution 4.0 International"
[Arts Deco]: http://www.ensad.fr/en
             "École Nationale Supérieure des Arts Décoratifs"
[Medialab]: http://www.medialab.sciences-po.fr/
               "Sciences Po Médialab"
