#! /usr/bin/env sh

# make an ER diagram.

neato -Tpng -Goverlap=prism src/er-diagram.dot > bin/er-diagram.png
