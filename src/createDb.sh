#! /usr/bin/env sh

# lines of data to import.
# to import entire files, use -0
howMuch=10000

importTables() {
# do the normal table import after setting up the database
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/shared_data/Allele.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/ClinSigCode.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SNP.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SNPAlleleFreq.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SNPClinSig.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/SNPPubmed.bcp.gz"
    importSnp "ftp://ftp.ncbi.nih.gov/snp/database/organism_data/human_9606/Synonym.bcp.gz"
}
importSchemas() {
# import the schemas

    # download them first.
    download "ftp://ftp.ncbi.nih.gov/snp/database/shared_schema/dbSNP_main_table.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/shared_schema/dbSNP_main_constraint.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/shared_schema/dbSNP_main_index.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_9606_table.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_9606_constraint.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_9606_index.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/dbSNP_sup_constraint.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/dbSNP_sup_index.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/dbSNP_sup_table.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_gty1_constraint.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_gty1_index.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_gty1_table.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_gty2_constraint.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_gty2_index.sql.gz"
    download "ftp://ftp.ncbi.nih.gov/snp/database/organism_schema/human_9606/human_gty2_table.sql.gz"

    # create unified schemas.
    src/createCombinedSchema.py "bin/dbSNP_main_table.sql.gz" "bin/dbSNP_main_constraint.sql.gz" "bin/dbSNP_main_index.sql.gz"
    src/createCombinedSchema.py "bin/human_9606_table.sql.gz" "bin/human_9606_constraint.sql.gz" "bin/human_9606_index.sql.gz"
    src/createCombinedSchema.py "bin/dbSNP_sup_constraint.sql.gz" "bin/dbSNP_sup_index.sql.gz" "bin/dbSNP_sup_table.sql.gz"
    src/createCombinedSchema.py "bin/human_gty1_constraint.sql.gz" "bin/human_gty1_index.sql.gz" "bin/human_gty1_table.sql.gz"
    src/createCombinedSchema.py "bin/human_gty2_constraint.sql.gz" "bin/human_gty2_index.sql.gz" "bin/human_gty2_table.sql.gz"

    # import schemas.
    importSchemaFile dbSNP_main.sql
    importSchemaFile dbSNP_sup.sql
    importSchemaFile human_9606.sql
    importSchemaFile human_gty1.sql
    importSchemaFile human_gty2.sql
}


# # # # # # # # # # # # # # # # # #
# don't change things below here. #
# # # # # # # # # # # # # # # # # #
dbDir=bin
dbFile=$dbDir/project.sqlite
downloadLogfile=$(mktemp)
touch $downloadLogfile
echo "Logging download data to ${downloadLogfile}."

setup() {
# blow away the previous database.
    mkdir -p $dbDir
    rm $dbFile* > /dev/null 2>&1

    importSchemas
}
importSchema() {
# import named schema file from bin directory.
    download $1
    importSchemaFile $1
}
importSchemaFile() {
# import the file
    fileName=${1##*\/}

    echo -n "Importing schema ${fileName}... "
    cat "${dbDir}/${fileName}" | \
        sqlite3 $dbFile
    echo "Done."
}
download() {
# download named file to bin directory.
    fileName=${1##*\/}

    echo -n "Downloading ${fileName}... "
    here=`pwd`
    cd $dbDir
    wget --referer="https://github.com/NickDaly/genome-explorer" -Nc $1 >> $downloadLogfile 2>&1
    cd $here
    echo "Done."
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
        sed -e 's/"/""/g' -e 's/	/"	"/g' -e 's/^\(.*\)$/"\1"/' | \
        sqlite3 --init $importCommand $dbFile
    # 1. unzip the file.
    # 2. process $thisMany lines.
    # 3. escape ":
    #    A. double " to escape them
    #    B. delimit fields by "
    #    C. wrap entire line in "
    # 4. echo into sqlite.
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
checkDependencies () {
    depend gzip
    depend python3
    depend sqlite3
    depend wget
}
depend () {
    which $1 > /dev/null 2>&1 || die "$1 is a missing required dependency.  Install it first."
}
die () {
    echo $1
    read X
    exit 0
}

#
# main
#

checkDependencies

# run setup
setup

# normal import
importTables
