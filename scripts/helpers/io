# See <https://misc.flogisoft.com/bash/tip_colors_and_formatting>
FORMAT_RED="\e[31m"
FORMAT_GREEN="\e[32m"
FORMAT_YELLOW="\e[33m"
FORMAT_BLUE="\e[34m"
FORMAT_MAGENTA="\e[35m"
FORMAT_CYAN="\e[36m"
FORMAT_UNDERLINE="\e[4m"
FORMAT_RESET="\e[0m"

# Colored messages
echo_info () {
	echo -e "$FORMAT_CYAN$1$FORMAT_RESET"
}
echo_error () {
	echo -e "$FORMAT_RED$1$FORMAT_RESET"
}
echo_warning () {
	echo -e "$FORMAT_YELLOW$1$FORMAT_RESET"
}
echo_success () {
	echo -e "$FORMAT_GREEN$1$FORMAT_RESET"
}
echo_note () {
	echo
	echo -e "$FORMAT_UNDERLINE$1$FORMAT_RESET"
	echo
}

# Simplified input
read_char () {
	read -e -p "$1" -n 1 $2
}
read_string () {
	read -p $1 $2
}
read_string_with_default () {
	read -e -p $1 -i $2 $3
}
