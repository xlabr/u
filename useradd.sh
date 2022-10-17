set -euo pipefail
read -p "ENTER USER PWD:" USER PWD
pass=$(perl -e 'print crypt($ARGV[0], "PWD")' $PWD)
useradd "$USER" -m -p "$pass" -G sudo
