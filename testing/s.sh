#!/bin/bash

rm nprocs
gcc nprocs.c -o nprocs
../tools/schedtool/schedtool -R -p 99 -e ./nprocs