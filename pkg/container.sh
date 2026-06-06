_container_engine() {
	if [ -n "${docker_bin:-}" ] && [ -x "$docker_bin" ]; then
		printf '%s\n' "$docker_bin"
		return 0
	fi

	if [ -n "${podman_bin:-}" ] && [ -x "$podman_bin" ]; then
		printf '%s\n' "$podman_bin"
		return 0
	fi

	printf 'No docker or podman binary found.\n' >&2
	return 1
}

container-image-list() {
	_engine="$(_container_engine)" || return 1
	"$_engine" image ls "$@"
}

container-image-update() {
	_engine="$(_container_engine)" || return 1

	if [ "$#" -gt 0 ]; then
		for _image in "$@"; do
			"$_engine" pull "$_image" || return $?
		done
		return 0
	fi

	_images="$("$_engine" image ls --format '{{.Repository}}:{{.Tag}}' | grep -v '^<none>:' | grep -v ':<none>$' | sort -u)"
	if [ -z "$_images" ]; then
		printf 'No tagged images found.\n' >&2
		return 0
	fi

	printf '%s\n' "$_images" | while IFS= read -r _image; do
		[ -n "$_image" ] || continue
		"$_engine" pull "$_image"
	done
}

container-image-remove() {
	if [ "$#" -eq 0 ]; then
		printf 'Usage: container-image-remove <image> [image...]\n' >&2
		return 2
	fi

	_engine="$(_container_engine)" || return 1
	"$_engine" image rm "$@"
}

container-image-prune() {
	_engine="$(_container_engine)" || return 1
	"$_engine" image prune "$@"
}

container-image-prune-all() {
	_engine="$(_container_engine)" || return 1
	"$_engine" image prune -a "$@"
}

alias img-list='container-image-list'
alias img-update='container-image-update'
alias img-remove='container-image-remove'
alias img-rm='container-image-remove'
alias img-prune='container-image-prune'
alias img-prune-all='container-image-prune-all'
