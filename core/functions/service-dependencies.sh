if [ "$(uname)" = "Linux" ]; then
	function service-dependencies() {
		if [[ -z $1 ]]; then
			echo "Usage: service-dependencies <service_name>"
			echo "Example: service-dependencies libvirtd"
			return
		fi

		grep "Wants=${1}" /etc/systemd/system/*/*
	}
fi
