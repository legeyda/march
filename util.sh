

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh



# march_util_download_to_dir URL DIR
march_util_download_to_dir() {
	# todo delete files on failure
	# todo delete files when signal received

	if bobshell_command_available curl; then

		march_util_exec_capture curl --head --location --fail --output /dev/null --write-out "%{url_effective}" "$1"
		if ! bobshell_result_check; then
			return
		fi

		mkdir -p "$2"

		march_util_exec_capture curl --fail --output-dir "$2" --remote-name --remote-header-name "$bobshell_result_2"
		if ! bobshell_result_check; then
			march_util_rm_backup "$2"
			return
		fi

		march_util_get_single_file_from_dir "$2"
		if ! bobshell_result_check; then
			march_util_rm_backup  "$2"
			return
		fi

	elif bobshell_command_available wget; then
		mkdir -p "$2"
		if ! wget --directory-prefix="$2" "$1"; then
			march_util_rm_backup  "$2"
			bobshell_result_set false
			return
		fi
	elif bobshell_command_available python; then
		bobshell_result_set false 'python not implemented'
		return 1
		mkdir -p "$2"
		python -c '
import sys
import urllib.request
urllib.request.urlretrieve(sys.argv[1])' "$1" "$2"
	else
		bobshell_result_set false 'unable to download'
	fi

	march_util_get_single_file_from_dir "$2"
}


# march_util_exec
# result: code stdout stderr
march_util_exec() {
	# https://stackoverflow.com/questions/11027679/capture-stdout-and-stderr-into-different-variables
	bobshell_result_set '' '' '' ''
	#bobshell_result_size=4
	bobshell_result_3=$(mktemp)
	bobshell_result_2=$("$@" 2> "$bobshell_result_3") \
		&& bobshell_result_1=$? \
		|| bobshell_result_1=$?
	bobshell_result_3=$(cat "$bobshell_result_3")
}

# fun: march_util_exec_capture CMD [ARGS ...]
# result: true  stdout
#         false stderr
march_util_exec_capture() {
	march_util_exec "$@"
	if [ 0 = "$bobshell_result_1" ]; then
		bobshell_result_set true "$bobshell_result_2"
	else
		bobshell_result_set false "$bobshell_result_3"
	fi
}



# march_util_unpack FILE DIR
march_util_unpack() (
	trap - EXIT
	if bobshell_regex_match "$1" '^.*\.tar.[0-9a-z]\+$'; then
		if bobshell_regex_match "$1" '^.*\.tar.gz$'; then
			_march_util_unpack__tar_cmd=z
		elif bobshell_regex_match "$1" '^.*\.tar.xz$'; then
			_march_util_unpack__tar_cmd=J
		else
			bobshell_die unsupported format
		fi
		_march_util_unpack__archive=$(realpath "$1")
		mkdir -p "$2"
		cd "$2"
		march_util_exec_capture tar x${_march_util_unpack__tar_cmd}f "$_march_util_unpack__archive"
		if bobshell_result_check; then
		    bobshell_result_set "$2"
		else
		    march_util_rm_backup "$2"
		fi
		unset _march_util_unpack__archive
	elif bobshell_ends_with "$1" .zip; then
		mkdir -p "$2"
		march_util_exec_capture unzip "$1" -d "$2"
		if bobshell_result_check; then
		    bobshell_result_set "$2"
		else
		    march_util_rm_backup "$2"
		fi
	else
	    bobshell_result_set false 'unsupported archive'
	fi
)




# march_util_sha256sum FILE
march_util_sha256sum() {
	if bobshell_command_available sha256sum; then
		bobshell_result_size=2
		bobshell_result_1=true
		bobshell_result_2=$(sha256sum "$1")
		bobshell_result_2=$(printf %s "$bobshell_result_2" | cut -d ' ' -f 1)
	elif bobshell_command_available shasum; then
		bobshell_result_size=2
		bobshell_result_1=true
		bobshell_result_2=$(shasum -a 256  "$1")
		bobshell_result_2=$(printf %s "$bobshell_result_2" | cut -d ' ' -f 1)
	elif bobshell_command_available openssl; then
		bobshell_result_size=2
		bobshell_result_1=true
		bobshell_result_2=$(openssl dgst -sha256 "$1")
		bobshell_result_2=$(printf %s "$bobshell_result_2" | cut -d ' ' -f 2)
	else
		bobshell_result_set false "Error: No suitable SHA-256 utility found."
	fi
}

# march_util_get_single_file_from_dir DIR [ FIND ARGS ]
march_util_get_single_file_from_dir() {
	_march_util_get_single_file_from_dir="$1"
	shift
	if [ -e "$_march_util_get_single_file_from_dir" ]; then
		_march_util_get_single_file_from_dir__1=$(find "$_march_util_get_single_file_from_dir" -mindepth 1 -maxdepth 1 "$@" -print -quit)
		if [ "$_march_util_get_single_file_from_dir__1" ]; then
			_march_util_get_single_file_from_dir__2=$(find "$_march_util_get_single_file_from_dir" -mindepth 1 -maxdepth 1 -path "$_march_util_get_single_file_from_dir__1" -prune -or "$@" -print -quit)
			if [ "$_march_util_get_single_file_from_dir__2" ]; then
				bobshell_result_set false 'multiple files found'
			else
				bobshell_result_set true "$_march_util_get_single_file_from_dir__1"
			fi
			unset _march_util_get_single_file_from_dir__2
		else
			bobshell_result_set false "dir $_march_util_get_single_file_from_dir__1 is empty"
		fi
	else
		bobshell_result_set false 'directory not exists'
	fi
	unset _march_util_get_single_file_from_dir _march_util_get_single_file_from_dir__1
}

#
march_util_rm_backup() {
    if [ -e "$1" ]; then
        _march_util_rm_backup="${MARCH_CACHE}/backup/$_march__id"
		_march_util_rm_backup="$_march_util_rm_backup/$(date +%Y-%m-%d_%H-%M-%S_%N)"
		mkdir -p "$_march_util_rm_backup"
		mv -t "$_march_util_rm_backup" "$1"
		unset _march_util_rm_backup
    fi
}
