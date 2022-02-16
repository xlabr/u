set -euo pipefail
password=789123
username=usrttt
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -m -p "$pass" "$username"
