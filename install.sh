#!/bin/bash
set -eu

pwd; hostname; date

echo "installing minizinc ..."
# Install MiniZinc
wget https://github.com/MiniZinc/MiniZincIDE/releases/download/2.7.4/MiniZincIDE-2.7.4-bundle-linux-x86_64.tgz
if [ -d MiniZinc ]; then
    rm -r MiniZinc
fi
mkdir MiniZinc
tar zxvf MiniZincIDE-2.7.4-bundle-linux-x86_64.tgz -C MiniZinc --strip-components=1
rm MiniZincIDE-2.7.4-bundle-linux-x86_64.tgz
if [ -L "/usr/local/bin/minizinc" ]; then
    rm /usr/local/bin/minizinc
fi
ln -s MiniZinc/bin/minizinc /usr/local/bin/minizinc

echo "installing or-tools ..."
# Install Or-Tools
wget https://github.com/google/or-tools/releases/download/v9.2/or-tools_amd64_flatzinc_debian-11_v9.2.9972.tar.gz
if [ -d or-tools ]; then
rm -r or-tools
fi
mkdir or-tools
tar xvzf or-tools_amd64_flatzinc_debian-11_v9.2.9972.tar.gz -C or-tools --strip-components=1
rm or-tools_amd64_flatzinc_debian-11_v9.2.9972.tar.gz

# Introduce Or-Tools to MiniZinc
cp configfiles/ortools.msc MiniZinc/share/minizinc/solvers

# Install Python requirements
python3 -m pip install -r pyrequirements.txt

date
echo "installtion was completed!"
exit 0