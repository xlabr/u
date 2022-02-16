:<<!
  if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
! 
    password=789123
    username=usr
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
    sudo useradd -m -p "$pass" "$username"
:<<!		
[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system."
	exit 2
fi
!
