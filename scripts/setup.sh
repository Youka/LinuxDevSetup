#! /bin/bash

# Extensions
. ./helpers/app.sh
. ./helpers/env.sh
. ./helpers/io.sh


# Check for root privilege (needed by following operations)
with_root
# Load environment from OS configuration instead of relying on parent shell
load_env_user

# Install build-essential (most basic build tools for linux software)
$app_install build-essential
# Install curl (downloader for web contents)
$app_install curl
# Install git (source code manager)
$app_install git
# Install java (development kit & runtime)
$app_install default-jdk
# Install maven (popular java dependency manager & build system)
$app_install maven
# Install postgresql (free database server competitive with best commercial ones)
$app_install postgresql pgadmin3

# Install MS Visual Code (most powerful coding editor)
if ! $app_exist code 2>/dev/null; then
	# See <https://code.visualstudio.com/docs/setup/linux>
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
	rm microsoft.gpg
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
	$app_install apt-transport-https
	$app_update
	$app_install code
fi
# Install NodeJS/npm (javascript runtime environment + dependency manager)
if ! $app_exist nodejs 2>/dev/null; then
	# See <https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions>
	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	$app_install nodejs
fi
# Install Angular CLI (JS framework for SPAs)
if ! npm list -g @angular/cli 2>/dev/null; then
	npm install -g @angular/cli
fi
# Install Eclipse for Java EE (most advanced java IDE)
if [ ! -d /opt/eclipse ]; then
	# Load eclipse
	targz_download http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R/eclipse-jee-photon-R-linux-gtk-x86_64.tar.gz /opt
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
if [ ! -L /opt/apache-tomcat ]; then
	# Load tomcat
	targz_download http://archive.apache.org/dist/tomcat/tomcat-8/v8.5.34/bin/apache-tomcat-8.5.34.tar.gz /opt
	# Create shortcut (to used version)
	for tomcat in /opt/apache-tomcat-*; do
		ln -s $tomcat /opt/apache-tomcat
		break
	done
fi

# Configure git
if ! sudo -u $SUDO_USER git config --global user.email 1>/dev/null; then
	# Request input
	read_string_with_default "Enter git user (global): " "$SUDO_USER" git_user
	read_string_with_default "Enter git email (global): " "$SUDO_USER@foobar.com" git_email
	# Configure for user
	sudo -u $SUDO_USER git config --global user.name "$git_user"
	sudo -u $SUDO_USER git config --global user.email "$git_email"
	# Configure for root
	git config --global user.name "$git_user"
	git config --global user.email "$git_email"
fi
# Configure java
if [ ! $JAVA_HOME ]; then
	add_env_var "JAVA_HOME" $(readlink -ze /usr/bin/javac | xargs -0 dirname | xargs -0 dirname)
fi
# Configure postgresql
service postgresql start
if $psql -c "select 1 from pg_roles where rolname='test'" | grep "0 rows" 1>/dev/null; then
	# See <https://www.postgresql.org/docs/9.1/static/sql-revoke.html>
	$psql -c "REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;"
	$psql -c "REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;"
	# See <https://www.postgresql.org/docs/9.2/static/sql-createuser.html>
	$psql -c "CREATE USER test WITH PASSWORD 'test';"
	# See <https://www.postgresql.org/docs/9.2/static/sql-createdatabase.html>
	$psql -c "CREATE DATABASE test WITH OWNER test CONNECTION LIMIT 200;"
	# Insert test data
	$psql -d test -c "CREATE TABLE persons(id serial primary key, name varchar(64) not null, birth_date date not null); ALTER TABLE persons OWNER TO test;"
	$psql -d test -c "INSERT INTO persons(name, birth_date) VALUES('Max', '1970-01-01'),('Julia', '2000-12-24');"
	echo_note "You can register a database connection in 'pgadmin3' with (host=localhost, port=5432, dbname=test, user=test, password=test) now!"
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
	echo_note "Added tomcat 'jdbc/test' jndi resource!"
	# Add tomcat server users
	sed -i 's/<\/tomcat-users>/  <role rolename="administrator"\/>\n  <role rolename="user"\/>\n  <user username="admin" password="admin" roles="administrator,manager-gui,manager-script"\/>\n  <user username="user" password="user" roles="user"\/>\n<\/tomcat-users>/g' /opt/apache-tomcat/conf/tomcat-users.xml
	echo_note "Added tomcat 'admin' & 'user' user!"
	# Add tomcat system user & assign to tomcat folder
	groupadd tomcat
	useradd -s /sbin/nologin -g tomcat -d /opt/apache-tomcat tomcat
	# Set permissions (owner cannot be set over symbolic link, so detect original)
	for tomcat in /opt/apache-tomcat-*; do
		chown -R tomcat:tomcat $tomcat
		chmod -R a+rwx $tomcat
		chmod -R a-w,g+w $tomcat/bin $tomcat/lib
		break
	done
	# Add system service for tomcat (and start)
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
	service tomcat start
fi
