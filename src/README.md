See other WISE-WARE documentation to learn about the structure and functions of this application.<br>

Once this has been downloaded on a new machine, the installation and first-run process is:<br>
* Run docker-install-debian.sh
* Run wiseware-regenerate.sh
* Run docker compose up -d
* Go to localhost:9000 and set up your Portainer admin account
  * If this is not done within 5 minutes of starting that container it will time out and you will need to restart the container and try again.
* Run mv ./configuration.yaml ./containervolumes/homeassistant/config/configuration.yaml
* Either in Home Assistant's user interface (accessed through localhost:8123) or through container controls, restart it so it reloads it's new config file and starts communicating with Kafka
