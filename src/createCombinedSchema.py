#! /usr/bin/env python3

"""This tool assumes that tables are included before other files.

Oh god, this is all terrible, but this'll work with the NCBI database
and nothing else.

It combines the table definition file with the constraint definition
file so that primary keys can be defined, because SQLite doesn't
support redefining tables separately to add primary or foreign keys.
Yeesh.

"""


import gzip
import os
import sys

def readTable(inFile, tables):
    inTable = 0

    with gzip.open(inFile, "r") as input:
        for line in input:
            line = line.decode("utf-8").strip()

            if line.startswith("CREATE TABLE"):
                inTable = 1
                table = line.split()[-1][1:-1]
                # XXX XXX [*JustThisPart*]
                tables[table] = ""
                continue

            elif line == ")":
                inTable = 0

            if not inTable or line == "(":
                continue

            tables[table] += line + "\n"
    return tables

def readConstraint(inFile, constraints):
    with gzip.open(inFile) as input:
        for line in input:
            line = line.decode("utf-8").strip().split()
            if len(line) < 8:
                continue
            if line[7] != "KEY":
                continue

            table = line[2].strip("[]")
            key = " ".join([x for x in line[6:]
                            if "CLUSTERED" not in x])

            # this is ungodly, like everything in this project.
            # remove " ASC" and "[]" from key definitions.
            if key.split()[0] == "PRIMARY":
                key = key.rpartition("(")
                noAsc = ""
                for word in key[2].rpartition(")")[0].split(","):
                    noAsc += word.replace(
                        " ASC","").replace("[","").replace("]","") + ", "
                key = key[0] + "(" + noAsc[:-2] + ")"

            constraints[table] = key

    return constraints

def readIndex(inFile, someSql):
    # TODO handle index files.
    return


if __name__ == "__main__":

    tables = {}
    constraints = {}
    indices = {}
    baseName = sys.argv[1].rpartition("_")[0] + ".sql"

    print("Creating {} schema... ".format(baseName.rpartition(os.sep)[2]), end="")
    for afile in sys.argv[1:]:
        if afile.endswith("_table.sql.gz"):
            tables = readTable(afile, tables)
        elif afile.endswith("_constraint.sql.gz"):
            constraints = readConstraint(afile, constraints)
        elif afile.endswith("_index.sql.gz"):
            indices = readIndex(afile, indices)

    with open(baseName, "w") as output:
        for k in tables.keys():
            if k == "dn_table_rowcount":
                continue

            output.write("""\
CREATE TABLE [{}]
(
{}""".format(k, tables[k]))

            try:
                output.write(", " + constraints[k] + "\n")
            except KeyError as e:
                pass

            output.write("""\
)
go

""")

    print("Done.")
