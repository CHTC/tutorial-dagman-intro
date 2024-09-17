#!/bin/bash

A_has_error=false

# Check if A.out has the right line
if $(grep -q "(This line appears when the typo is fixed.)" A.out) ; then
        echo "A.out shows the correct line." > A-check.out
else
        echo "A.out does not show the correct line." > A-check.out
        A_has_error=true
fi

# Check if A.err exists and is empty
if [ -e "A.err" ] && [ ! -s "A.err" ]; then
        echo "A.err exists and is empty." >> A-check.out
else
        echo "A.err does not exist or is not empty." >> A-check.out
        A_has_error=true
fi

# Final report

if ${A_has_error}; then
        echo "Job A did not pass the check!" >> A-check.out
        exit 1
else
        echo "Job A passed the check!" >> A-check.out
        exit 0
fi