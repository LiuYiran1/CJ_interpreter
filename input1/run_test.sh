#!/bin/bash

cd ~/Main/Softer/DIPL/lab1/input || exit 1

cjc test.cj -o test
echo "compile_ret=$?"

./test
echo "run_ret=$?"
