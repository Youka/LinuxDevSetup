# Shortcuts
app_install="apt-get install -y"
app_update="apt-get update"
app_exist="hash"
psql="sudo -u postgres psql"

# Convenient functions
targz_download () {
	curl "$1" | tar -xzf - -C "$2"
}