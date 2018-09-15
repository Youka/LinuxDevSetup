#! /bin/bash

# Extensions
. ./helpers/app
. ./helpers/env
. ./helpers/io


# Check for user privilege (root not recommend by following operations)
with_user
# Check correct environment
if ! $app_exist ng 2>/dev/null; then
	echo "Missing setup? Tools for projects not installed!"
	exit
fi

# Create project
read_string "Enter project name (or leave empty): " project_name
if [ -n "$project_name" ]; then
	# Subproject names
	frontend_project_name=$project_name"-app"
	backend_project_name=$project_name"-service"
	# Project location on desktop
	cd $HOME/Desktop
	# Initialize frontend project
	ng new $frontend_project_name --routing --style=scss --skip-tests # With routing module, sass as styling language and no tests overflow
	sed -i 's/<base href="\/">/<base href=".">/g' $frontend_project_name/src/index.html  # Fix resources loading path from root to local
	sed -i "s/\"outputPath\": \"dist/\"outputPath\": \"\/opt\/apache-tomcat\/webapps/g" $frontend_project_name/angular.json   # Set deploy directory to tomcat server
	# Initialize backend project
	# TODO: generate restfull webservice maven project by custom archetype (connect to tomcat & postgresql jndi)
fi
