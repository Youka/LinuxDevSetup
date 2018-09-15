# What these scripts do?
*scripts/setup.sh* installs & configures developer software for a debian-based operating system.

*scripts/create_app.sh* builds & configures new projects for a web application.

# Usage
To run bash scripts:
* open **terminal** in scripts directory
* run `chmod u+x ./setup.sh && sudo ./setup.sh`
* enter root password
* wait... (pay attention to prompts with default values near the end)
* run `chmod u+x ./create_app.sh && ./create_app.sh`
* enter project name
* wait...
* PROFIT

# TODO
* Fix: Tomcat download path changes with new version