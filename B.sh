#!/bin/bash

set -e

echo "This script is..."
echo "    running on machine $(hostname)"
echo "    being executed by user $(whoami)"
echo "    in the directory $(pwd)"
echo ""
echo "(This line appears when the typo is fixed.)"
echo ""

# Extracting the contents of A.out
A_hostname="$(sed -n 's/.*running on machine \(.*\)/\1/p' A.out)"
A_whoami="$(sed -n 's/.*being executed by user \(.*\)/\1/p' A.out)"
A_pwd="$(sed -n 's/.*in the directory \(.*\)/\1/p' A.out)"

# Comparing and reporting A and B
echo "Jobs A and B ..."

if [[ "$(hostname)" == "${A_hostname}" ]]; then
        echo "    both ran on the same machine: ${A_hostname}"
else
        echo "    ran on different machines"
fi

if [[ "$(whoami)" == "${A_whoami}" ]]; then
        echo "    both were executed by the same user: ${A_whoami}"
else
        echo "    were executed by different users"
fi

if [[ "$(pwd)" == "${A_pwd}" ]]; then
        echo "    both were executed in the ssame directory: ${A_pwd}"
else
        echo "    were executed in different directories"
fi