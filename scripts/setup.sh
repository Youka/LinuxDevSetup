#! /bin/bash

# Check for root privilege (needed by following operations)
if [ $USER != 'root' ]; then
	echo "You must run this script with root privilege."
	exit
fi
# Macros
apt_install="apt-get install -y"
apt_update="apt-get update"
info_message () {
	echo
	echo -e "\033[0;36m $1 \033[0m"
	echo
}
SUDO_HOME=$(eval echo ~${SUDO_USER})
add_env_var () {
	echo "$1=$2" >> /etc/environment
	echo "export $1=$2" >> $SUDO_HOME/.bashrc
	source $SUDO_HOME/.bashrc
}
# Load environment from OS configuration instead of relying on parent shell
source $SUDO_HOME/.bashrc

# Install build-essential (most basic build tools for linux software)
$apt_install build-essential
# Install curl (downloader for web contents)
$apt_install curl
# Install git (source code manager)
$apt_install git
# Install java (development kit & runtime)
$apt_install default-jdk
# Install maven (popular java dependency manager & build system)
$apt_install maven
# Install postgresql (free database server competitive with best commercial ones)
$apt_install postgresql pgadmin3

# Install MS Visual Code (most powerful coding editor)
if ! hash code 2>/dev/null; then
	# See <https://code.visualstudio.com/docs/setup/linux>
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
	rm microsoft.gpg
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
	$apt_install apt-transport-https
	$apt_update
	$apt_install code
fi
# Install NodeJS/npm (javascript runtime environment + dependency manager)
if ! hash nodejs 2>/dev/null; then
	# See <https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions>
	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	$apt_install nodejs
fi
# Install Angular CLI (JS framework for SPAs)
if ! npm list -g @angular/cli 2>/dev/null; then
	npm install -g @angular/cli
fi
# Install Eclipse for Java EE (most advanced java IDE)
if [ ! -d /opt/eclipse ]; then
	# Load eclipse
	curl http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R/eclipse-jee-photon-R-linux-gtk-x86_64.tar.gz | tar -xzf - -C /opt
	# Create desktop file
	echo "[Desktop Entry]
Name=Eclipse
Comment=Eclipse IDE for Java development
Exec=/opt/eclipse/eclipse
Icon=/opt/eclipse/icon.xpm
Terminal=false
Type=Application
Categories=Development;Application" > /usr/share/applications/eclipse.desktop
	chmod a+x /usr/share/applications/eclipse.desktop
fi
# Install Tomcat (HTTP server with servlet support)
if ! ls /opt/apache-tomcat 2>/dev/null 1>&2; then
	# Load tomcat
	curl http://www-us.apache.org/dist/tomcat/tomcat-8/v8.5.33/bin/apache-tomcat-8.5.33.tar.gz | tar -xzf - -C /opt
	# Create shortcut (to used version)
	for tomcat in /opt/apache-tomcat-*; do
		ln -s $tomcat /opt/apache-tomcat
		break
	done
fi

# Configure git
if ! git config --global user.email 1>/dev/null; then
	read -e -p "Enter git user (global): " -i "$SUDO_USER" git_user
	git config --global user.name "$git_user"
	read -e -p "Enter git email (global): " -i "$SUDO_USER@foobar.com" git_email
	git config --global user.email "$git_email"
fi
# Configure java
if [ ! $JAVA_HOME ]; then
	add_env_var "JAVA_HOME" $(readlink -ze /usr/bin/javac | xargs -0 dirname | xargs -0 dirname)
fi
# Configure postgresql
service postgresql start
if sudo -u postgres psql -c "select 1 from pg_roles where rolname='test'" | grep "0 rows" 1>/dev/null; then
	# See <https://www.postgresql.org/docs/9.1/static/sql-revoke.html> <https://www.postgresql.org/docs/9.2/static/sql-createuser.html> <https://www.postgresql.org/docs/9.2/static/sql-createdatabase.html>
	sudo -u postgres psql -c "REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;"
	sudo -u postgres psql -c "REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;"
	sudo -u postgres psql -c "CREATE USER test WITH PASSWORD 'test';"
	sudo -u postgres psql -c "CREATE DATABASE test WITH OWNER test CONNECTION LIMIT 200;"
	sudo -u postgres psql -d test -c "CREATE TABLE persons(id serial primary key, name varchar(64) not null, birth_date date not null); ALTER TABLE persons OWNER TO test;"
	sudo -u postgres psql -d test -c "INSERT INTO persons(name, birth_date) VALUES('Max', '1970-01-01');"
	sudo -u postgres psql -d test -c "INSERT INTO persons(name, birth_date) VALUES('Julia', '2000-12-24');"
	info_message "You can register a database connection in 'pgadmin3' with (host=localhost, port=5432, dbname=test, user=test, password=test) now!"
fi
# Configure Tomcat
if [ ! $CATALINA_HOME ]; then
	# Add environment variable
	add_env_var "CATALINA_HOME" /opt/apache-tomcat
	# Add postgresql jdbc driver
	curl https://jdbc.postgresql.org/download/postgresql-42.2.5.jar > /opt/apache-tomcat/lib/postgresql-42.2.5.jar
	# Add tomcat jndi resource for postgresql ('test' database)
	sed -i 's/<\/Context>/    <ResourceLink name="jdbc\/test" global="jdbc\/testGlobal" auth="Container" type="javax.sql.DataSource" \/>\n<\/Context>/g' /opt/apache-tomcat/conf/context.xml
	sed -i 's/  <\/GlobalNamingResources>/    <Resource name="jdbc\/testGlobal" auth="Container" type="javax.sql.DataSource" driverClassName="org.postgresql.Driver" url="jdbc:postgresql:\/\/127.0.0.1:5432\/test" username="test" password="test" maxTotal="20" maxIdle="10" maxWaitMillis="-1" \/>\n  <\/GlobalNamingResources>/g' /opt/apache-tomcat/conf/server.xml
	info_message "Added tomcat 'jdbc/test' jndi resource!"
	# Add tomcat admin user
	sed -i 's/<\/tomcat-users>/  <role rolename="administrator"\/>\n  <role rolename="user"\/>\n  <user username="admin" password="admin" roles="administrator,manager-gui,manager-script"\/>\n  <user username="user" password="user" roles="user"\/>\n<\/tomcat-users>/g' /opt/apache-tomcat/conf/tomcat-users.xml
	info_message "Added tomcat 'admin' & 'user' user!"
	# Add tomcat system user & assign to tomcat folder
	groupadd tomcat
	useradd -s /sbin/nologin -g tomcat -d /opt/apache-tomcat tomcat
	# Set permissions (owner cannot be set over link, so detect original)
	for tomcat in /opt/apache-tomcat-*; do
		chown -R tomcat:tomcat $tomcat
		chmod -R a+rwx $tomcat
		chmod -R a-w,g+w $tomcat/bin $tomcat/lib
		break
	done
	# Add system service for tomcat
	echo "[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=forking
ExecStart=/opt/apache-tomcat/bin/startup.sh
ExecStop=/opt/apache-tomcat/bin/shutdown.sh
User=tomcat
Group=tomcat" > /etc/systemd/system/tomcat.service
fi