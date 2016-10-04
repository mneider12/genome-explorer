#! /usr/bin/env sh

echo "This script assumes you've already run createDb.sh to download the schemas."
echo "If you haven't already, Ctrl+C and do so before continuing."
echo
read X

here=`pwd`
cd bin

echo "@startuml" > main_table.uml
cat dbSNP_main_table.sql.gz | gunzip | sed -e 's#\(\[\|\]\)##g' -e 's/CREATE TABLE /object-/' -e 's/ / : /' -e 's/object-/object /' -e 's/^go$//' -e 's/^object \(.*\)$/object \1 {/' -e 's/^($//' -e 's/^)/}/' | cut -d' ' -f'1-3' >> main_table.uml
echo "@enduml" >> main_table.uml
plantuml main_table.uml

echo "@startuml" > human_table.uml
cat human_9606_table.sql.gz | gunzip | sed -e 's#\(\[\|\]\)##g' -e 's/CREATE TABLE /object-/' -e 's/ / : /' -e 's/object-/object /' -e 's/^go$//' -e 's/^object \(.*\)$/object \1 {/' -e 's/^($//' -e 's/^)/}/' | cut -d' ' -f'1-3' >> human_table.uml
echo "@enduml" >> human_table.uml
plantuml human_table.uml

cd $here
