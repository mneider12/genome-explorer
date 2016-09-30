#! /usr/bin/env sh

howMuch=40
dbDir=db
dbFile=$dbDir/project.sqlite

function makeImport {
# create import file to import into correct table name.
    importCommand=$(mktemp)
    cat <<EOF > $importCommand
.mode tabs $tablename
.import /dev/stdin $tablename
EOF
}

function importSnp {
# import a particular table.
    tablename=${1##*\/}
    tablename=${tablename%%.*}
    echo $tablename
    makeImport
    wget -qO - $1 | head -$howMuch | gunzip | sqlite3 --init $importCommand $dbFile
}

# blow away the previous database.
mkdir $dbDir
rm $dbFile

# import the schema!
wget -qO - ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_9606_table.sql.gz | gunzip | sed -e '/SubSNPOmim/,+4d' | sqlite3 $dbFile

# normal import
importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SubPopGty.bcp.gz"
