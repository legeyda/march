
shelduck import ./util.sh


bobshell_event_listen march_cli_check true

# fun: march_download URL
# result: FILE
march_download() {
	_march_download__dir="${MARCH_CACHE}/$_march__id/download"

    march_util_get_single_file_from_dir "$_march_download__dir"
    if bobshell_result_check; then
        march_download_check_file "$bobshell_result_2"
        if bobshell_result_check; then
            unset _march_download__dir
            return
        fi
    fi

    march_util_rm_backup "$_march_download__dir"
    march_util_download_to_dir "$1" "$_march_download__dir"
	if bobshell_result_check _march__download_file; then
	    echo "actual file size: $(wc -c < "$_march__download_file")"

        march_util_sha256sum $_march__download_file
        echo "actual file sha256 sum: $bobshell_result_2"

		march_download_check_file "$_march__download_file"
		if bobshell_result_check; then
            _march__download_file_name=$(basename "$_march__download_file")
            printf %s "$_march__download_file" > "${MARCH_CACHE}/$_march__id/download-file-name"
            unset _march__download_file_name
		fi

	fi

    unset _march_download__dir
}




# march_download_check_file FILE
march_download_check_file() {
	if ! [ -r "$1" ]; then
		bobshell_result_set false 'file not exist'
		return
	fi

	if bobshell_isset _march__expected_size; then
		_march_download_check_file__actual_size=$(wc -c < "$1")
		if [ "$_march__expected_size" -ne "$_march_download_check_file__actual_size" ]; then
			bobshell_result_set false 'size differs'
			unset _march_check__expected_size
			return
		fi
		unset _march_check__expected_size
	fi

	if bobshell_isset _march__expected_md5; then
		if bobshell_isset _march__expected_md5 && [ 32 -ne "${#_march__expected_md5}" ] ; then
			bobshell_result_set false 'wrong md5'
			return
		fi
		if ! bobshell_regex_match "$_march__expected_md5" '^[0-9a-f]\{32\}*$'; then
			bobshell_result_set false 'wrong md5'
			return
		fi

		march_md5sum "$1"
		if ! bobshell_result_check; then
			bobshell_result_set false 'error calculating md5'
		fi

		if [ "$_march__expected_md5" != "$bobshell_result_2" ]; then
			bobshell_result_set false 'md5 differs'
			return
		fi
	fi

	if bobshell_isset _march__expected_sha256; then
		if bobshell_isset _march__expected_sha256 && [ 64 -ne "${#_march__expected_sha256}" ] ; then
			bobshell_result_set false 'wrong sha256'
			return
		fi
		if ! bobshell_regex_match "$_march__expected_sha256" '^[0-9a-f]\{64\}*$'; then
			bobshell_result_set false 'wrong sha256'
			return
		fi

		march_util_sha256sum "$1"
		if ! bobshell_result_check; then
			bobshell_result_set false 'error calculating sha256'
		fi

		if [ "$_march__expected_sha256" != "$bobshell_result_2" ]; then
			bobshell_result_set false 'sha256 differs'
			return
		fi
	fi


	bobshell_result_set true "$1"
}
