# Set home to sudo user
if [ "$USER" == "root" ] && [ -n "$SUDO_USER" ]; then
	SUDO_HOME=$(eval echo ~${SUDO_USER})
fi

# Modify environment
add_env_var_global () {
	echo "$1=$2" >> /etc/environment
}
add_env_var_user () {
	if [ -n "$SUDO_HOME" ]; then
		echo "export $1=$2" >> $SUDO_HOME/.bashrc
	else
		echo "export $1=$2" >> ~/.bashrc
	fi
}
load_env_global () {
	. /etc/environment
}
add_env_var () {
	add_env_var_global $1 $2
	add_env_var_user $1 $2
	load_env_global
}

# Request privileges
with_root () {
	if [ "$USER" != "root" ]; then
		echo_error "Root user required!"
		exit
	fi
}
with_user () {
	if [ "$USER" == "root" ]; then
		echo_error "Non-root user required!"
		exit
	fi
}
