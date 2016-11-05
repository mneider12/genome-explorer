#! /usr/bin/env sh

# make an ER diagram.

neato -Tpng -Goverlap=prism "src/Genetic Database ER diagram.dot" > "bin/Genetic Database ER diagram.png"
