#!/bin/bash
set -eu

pwd; hostname; date

echo "installing minizinc ..."
# Install MiniZinc
wget https://github.com/MiniZinc/MiniZincIDE/releases/download/2.7.4/MiniZincIDE-2.7.4-bundle-linux-x86_64.tgz

# Ask user for MiniZinc installation path
read -p "Enter the installation path for MiniZinc: " minizinc_path

# Append MiniZinc directory to the entered path
minizinc_path_full="$minizinc_path/MiniZinc"

if [ -d $minizinc_path_full ]; then
    rm -r $minizinc_path_full
fi

mkdir $minizinc_path_full
tar zxvf MiniZincIDE-2.7.4-bundle-linux-x86_64.tgz -C $minizinc_path_full --strip-components=1
rm MiniZincIDE-2.7.4-bundle-linux-x86_64.tgz

# Remove old symbolic link if it exists
if [ -L "/usr/local/bin/minizinc" ]; then
    sudo rm /usr/local/bin/minizinc
fi

# Create symbolic link with full absolute path
sudo ln -s $minizinc_path_full/bin/minizinc /usr/local/bin/minizinc

echo "installing or-tools ..."
# Install Or-Tools
wget https://github.com/google/or-tools/releases/download/v9.2/or-tools_amd64_flatzinc_debian-11_v9.2.9972.tar.gz

if [ -d or-tools ]; then
    rm -r or-tools
fi

mkdir or-tools
tar xvzf or-tools_amd64_flatzinc_debian-11_v9.2.9972.tar.gz -C or-tools --strip-components=1
rm or-tools_amd64_flatzinc_debian-11_v9.2.9972.tar.gz

# Link Or-Tools to MiniZinc
read -p "Enter the installation path for Or-Tools: " ortools_path
ortools_full_path="$ortools_path/or-tools"
sed -i "s|{ORTOOLS_PATH}|$ortools_full_path|g" configfiles/ortools.msc
cp configfiles/ortools.msc $minizinc_path_full/share/minizinc/solvers

# Install Python requirements
python3 -m pip install -r pyrequirements.txt

date
echo "installation was completed!"
exit 0
