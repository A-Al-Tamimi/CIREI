#!/bin/bash

#####################################
#=-Persistent data volume handling-=#
#####################################
#Creates parts of the WISE-WARE folder structure and sets user and group ids as
#configured.  The container volumes that are not created here will be created
#during normal operation, so adding things here is only necessariy if particular
#uid:gid settings are needed or if a later part of this script is extended to
#require a particular folder

declare -A new_dirs

#Set directory paths and permissions, if applicable
new_dirs["./containervolumes/zookeeper/data"]="1000:1000"
new_dirs["./containervolumes/zookeeper/log"]="1000:1000"
new_dirs["./containervolumes/kafka/broker/data"]="1000:1000"
new_dirs["./containervolumes/kafka/secrets"]="1000:1000"
new_dirs["./containervolumes/nodered/data"]="1000:1000"

#Loop through the associative array
for dir in "${!new_dirs[@]}"; do
  if ! test -d "$dir"; then
    mkdir -p "$dir"
    echo "Created directory: $dir"
  else
    echo "Directory already exists: $dir"
  fi

  #Only sets user and group id if a value has been included; does nothing if
  #there is no defined value
  if [[ ! -z "${new_dirs[$dir]}" ]]; then
    echo "Setting uid:gid permissions for $dir to ${new_dirs[$dir]}"
    chown -R "${new_dirs[$dir]}" "$dir"
  fi
done

###########################################
#=-Resolving the docker compose template-=#
###########################################
#Populates placeholder keys present in the provided list of filenames; searches
#for .template versions of each one and will replace an existing file. Placeholder
#keys should be in constant case (all caps, underscores), prefixed by "<<" and
#postfixed by ">>". eg. <<HOST_IP>>

declare -A substitutions
#Define substitutions (key-value pairs)

#Assuming the first address is the device itself on it's primary network usually
#works fine, but with more complex network topologies may turn out to be wrong;
#adjust if needed
substitutions["<<HOST_IP>>"]=$(hostname -I | cut -d' ' -f1)

#List of real filenames to process; do not include the .template extension here,
#but make sure the template file does exist in the same directory as this script
filenames=(
  "docker-compose.yml"
  "configuration.yaml"
)

#Populates all templates, provided they exist
for filename in "${filenames[@]}"; do
  template_file="$filename.template"

  if [ -f "$template_file" ]; then
    echo "Found template for $filename: $template_file"

    #Clears out old version of the output file
    if [ -f "$filename" ]; then
      echo "$filename exists, deleting..."
      rm "$filename"
    fi

    #Clone template
    echo "Cloning $template_file and renaming to $filename..."
    cp "$template_file" "$filename"

    #Populate placeholders
    echo "Substituting templates in $filename..."
    for key in "${!substitutions[@]}"; do
      value="${substitutions[$key]}"
      echo "Substituting $key..."
      sed -i "s/$key/$value/g" "$filename"
    done
  else #Outputs a warning if a template is not found for the file in question
    echo "WARNING: Template not found for $filename: $template_file"
  fi
done


###############################################
#=-End-of-script reporting and tutorialising-=#
###############################################
report_msg="WISE-WARE has finished regenerating!
\nUse 'docker compose down' in the same folder as the compose file.
\tThis will clear out any leftover containers from previous runs of WISE-WARE.
Then use 'docker compose up -d' to run WISE-WARE as normal.
After first run, don't forget to move Home Assistant's configuration.yaml using:
\tmv ./configuration.yaml ./containervolumes/homeassistant/config/configuration.yaml
\tThen, restart Home Assistant either through it's UI or through it's container.
\tYou need to do it in this order so files that configuration.yaml references exist when it is interpreted.
This machine's IP address is ${substitutions[$'<<HOST_IP>>']}.
\n"

printf "$report_msg"
