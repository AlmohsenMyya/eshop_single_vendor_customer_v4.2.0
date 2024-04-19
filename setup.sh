#!/bin/bash
echo "Welcome to WRTeam's product eBroker!"

#Please add these dependencies into pubspec.yaml if not there rename,flutter_launcher_icons
#this file will help change app name , package name, and change launcher icon.

{
    flutter pub get
    flutter pub global activate rename
} >/dev/null 2>&1

# Prompt the user for app name
read -p "Enter the new app name: " app_name

# Prompt the user for package name
read -p "Enter the new package name: " package_name

handle_error() {
    echo "Error: $1"
    exit 1
}

echo "Changing app name to ${app_name}"
rename setAppName --targets ios,android --value "${app_name}" >/dev/null 2>&1 || handle_error "Failed to set app name"
echo "--App name changed!--"

echo "Changing package name to ${package_name}"
flutter pub run change_app_package_name:main ${package_name} >/dev/null 2>&1 || handle_error "Failed to set app name"
echo "--App package changed!--"
#
#echo "Changing App Icons"
#flutter pub run flutter_launcher_icons >/dev/null 2>&1
#echo "--App Icon changed!--"

echo "Basic setup done!"
echo "Please follow documentation for more! https://wrteamdev.github.io/ebroker-App-Doc/"
