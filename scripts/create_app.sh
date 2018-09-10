#! /bin/bash

# Check for user privilege (root not recommend by following operations)
if [ $USER == 'root' ]; then
	echo "You should run this script with user privilege."
	exit
fi
# Check correct environment
if ! hash ng 2>/dev/null; then
	echo "Missing setup? Tools for projects not installed!"
	exit
fi

# Create project
read -p "Enter project name (or leave empty): " project_name
if [ $project_name ]; then
	# Initialize frontend project
	cd $HOME/Desktop
	ng new $project_name --routing --style=scss --skip-tests # With routing module, sass as styling language and no tests overflow
	sed -i 's/<base href="\/">/<base href=".">/g' $project_name/src/index.html  # Fix resources loading path from root to local
	sed -i "s/\"outputPath\": \"dist/\"outputPath\": \"\/opt\/apache-tomcat\/webapps/g" $project_name/angular.json   # Set deploy directory to tomcat server
	# Initialize backend project
	# TODO: generate restfull webservice maven project by custom archetype (connect to tomcat & postgresql jndi)
fi