#! /usr/bin/env sh

# lines of data to import.
# to import entire files, use -0
howMuch=-0

importTables() {
# do the normal table import after setting up the database
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/shared_data/Allele.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/ClinSigCode.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/Pedigree.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SNPClinSig.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SNPPubmed.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/Synonym.bcp.gz"
}


# # # # # # # # # # # # # # # # # #
# don't change things below here. #
# # # # # # # # # # # # # # # # # #
dbDir=bin
dbFile=$dbDir/project.sqlite

#
# functions
#
download() {
    fileName=${1##*\/}

    echo -n "Downloading ${fileName}... "
    here=`pwd`
    cd $dbDir
    wget -qNc $1
    cd $here
    echo "Done."
}
setup() {
# blow away the previous database.
    mkdir -p $dbDir
    rm $dbFile* 2>&1 > /dev/null

    # import the schemas
    download "ftp://ftp.ncbi.nih.gov/snp/database/shared_schema/dbSNP_main_table.sql.gz"
    echo -n "Importing shared schema... "
    cat "${dbDir}/${fileName}" | \
        gunzip | \
        sqlite3 $dbFile
    echo "Done."

    # exclude the syntax erroring empty table SubSNPOmim.
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_9606_table.sql.gz"
    echo -n "Importing human schema... "
    cat "${dbDir}/${fileName}" | \
        gunzip | \
        sed -e "/SubSNPOmim/,+4d" | \
        sqlite3 $dbFile
    echo "Done."

}
makeImport () {
# create import file to import into correct table name.
    fileName=${1##*\/}
    tablename=${fileName%%.*}
    importCommand=$(mktemp)

    cat <<EOF > $importCommand
.mode tabs $tablename
.import /dev/stdin $tablename
EOF
}
importSnp () {
# import a particular table.
    fileName=${1##*\/}
    tablename=${fileName%%.*}

    makeImport $1
    download $1

    echo -n "Importing $tablename... "
    cat "${dbDir}/${fileName}" | \
        gunzip | \
        head -n $howMuch | \
        sqlite3 --init $importCommand $dbFile
    echo "Done."
}

#
# main
#

# run setup
setup

# normal import
importTables
