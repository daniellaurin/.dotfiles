#!/bin/bash

# Navigate to the Samsung directory
cd ~/Documents/Samsung/

# Recursively find all files and rename them
find . -type f -name "* *" | while read file; do
	# Replace spaces with hyphens in the filename
	newname=$(echo "$file" | sed 's/ /-/g')
	# Rename the file to have a .md extension
	mv "$file" "${newname%.txt}.norg"
done

# Recursively find all directories and rename them
find . -type d -name "* *" | while read dir; do
	# Replace spaces with hyphens in the directory name
	newname=$(echo "$dir" | sed 's/ /-/g')
	mv "$dir" "$newname"
done
