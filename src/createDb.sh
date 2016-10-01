#! /usr/bin/env sh

# lines of data to import.
# to import entire files, use -0
howMuch=-0

importTables() {
# do the normal table import after setting up the database
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/Allele.bcp.gz"
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
setup() {
# blow away the previous database.
    mkdir -p $dbDir
    rm $dbFile 2>&1 > /dev/null

    # import the schemas! exclude the syntax erroring empty table SubSNPOmim.
    wget -qO - ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_9606_table.sql.gz | \
        gunzip | \
        sed -e "/SubSNPOmim/,+4d" | \
        sqlite3 $dbFile

    wget -qO - ftp://ftp.ncbi.nih.gov/snp/database/shared_schema/dbSNP_main_table.sql.gz | \
        gunzip | \
        sqlite3 $dbFile
}
makeImport () {
# create import file to import into correct table name.
    importCommand=$(mktemp)
    cat <<EOF > $importCommand
.mode tabs $tablename
.import /dev/stdin $tablename
EOF
}
importSnp () {
# import a particular table.
    tablename=${1##*\/}
    tablename=${tablename%%.*}
    makeImport

    wget -qO - $1 | \
        gunzip | \
        head -n $howMuch | \
        sqlite3 --init $importCommand $dbFile
}

#
# main
#

# run setup
setup

# normal import
importTables
