


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/shift.sh



# march_run URL ARGS ...
march_runner() {
	bobshell_result_set false 'runner not found'
	for _march_runner__candidate in appimage archive exe; do
		march_runner_$_march_runner__candidate "$@"
		if bobshell_result_check; then
			break
		else
			bobshell_result_shift
			if bobshell_result_check; then
				bobshell_result_set false 'runner not found'
			else
				break
			fi
		fi
	done
	unset _march_runner__candidate
}

march_shift_exec() {
	shift "$1"
	shift
	"$@"
}

# fun: march_runner_appimage URL [ ARGS ... ]
# result: true RUNARGS
#         false true try next runner
#         false false unrecoverable error
march_runner_appimage() {
	march_runner_download "$@"
	if ! bobshell_result_check _march_runner_appimage__file; then
		return
	fi

	if [ true = "$_march__appimage" ] || bobshell_ends_with "$_march_runner_appimage__file" .AppImage; then
		shift # remove url
		if [ true = "${MARCH_APPIMAGE_NO_SANDBOX:-false}" ] || [ true = "${_march__appimage_no_sandbox:-false}" ] ; then
			set -- --no-sandbox "$@"
		fi
	   chmod +x "$_march_runner_appimage__file"
	   bobshell_result_set true "$_march_runner_appimage__file" "$@"
	else
		bobshell_result_set false true 'not an appimage file'
	fi
	unset _march_runner_appimage__file
}

#
march_runner_exe() {
	march_runner_download "$@"
	if ! bobshell_result_check _march_runner_exe__file; then
		return
	fi

	if ! [ true = "$_march__exe" ]; then
		march_file_is_executable "$_march_runner_exe__file"
		if ! bobshell_result_check; then
			bobshell_result_set false true 'not an executable file'
			unset _march_runner_exe__file
			reset
			return
		fi
	fi

	chmod +x "$_march_runner_exe__file"
	shift # remove url
	bobshell_result_set true "$_march_runner_exe__file" "$@"
	unset _march_runner_exe__file
}

march_file_is_executable() {
	local temp=$(file "$1")
	if printf %s "$temp" | grep -q -E "executable|script"; then
		bobshell_result_set true "$1"
	else
		bobshell_result_set false
	fi
}

march_runner_download() {
	march_download "$@"
	if ! bobshell_result_check; then
		bobshell_result_insert 1 false
	fi
}

# fun: march_runner_archive URL [ ARGS ]
march_runner_archive() {
	march_runner_download "$@"
	if ! bobshell_result_check _march_runner_archive__file; then
		return
	fi

	if [ true = "$_march__archive" ] || bobshell_isset _march__archive_exe; then
		true
	elif bobshell_ends_with "$1" .tar.gz || bobshell_ends_with "$1" .tar.xz || bobshell_ends_with "$1" .zip; then
		true
	else
		bobshell_result_set false true 'unsupported archive'
		unset _march_runner_archive__file
		return
	fi

	_march_runner_archive__unpack="$MARCH_CACHE/$_march__id/unpack"

	if ! [ -e "$_march_runner_archive__unpack" ]; then
		march_util_unpack "$_march_runner_archive__file" "$_march_runner_archive__unpack"
		if ! bobshell_result_check; then
			bobshell_result_2="error unpacking archive: $bobshell_result_2"
			bobshell_result_insert 1 false
			unset _march_runner_archive__unpack
			unset _march_runner_archive__file
			return
		fi
	fi

	if bobshell_isset _march__archive_exe && [ -x "$_march_runner_archive__unpack/$_march__archive_exe" ]; then
		bobshell_result_set true "$_march_runner_archive__unpack/$_march__archive_exe" "$@"
		unset _march_runner_archive__unpack
		return
	fi

	# if archive contains single directory at root, go into it
	march_util_get_single_file_from_dir "$_march_runner_archive__unpack" -type d
	bobshell_result_check _march_runner_archive__unpack || true

	if bobshell_isset _march__archive_exe && [ -x "$_march_runner_archive__unpack/$_march__archive_exe" ]; then
		bobshell_result_set true "$_march_runner_archive__unpack/$_march__archive_exe" "$@"
		unset _march_runner_archive__unpack
		return
	fi


	# run single executable file or single exeuctable file in bin-subdirectory
	march_util_get_single_file_from_dir "$_march_runner_archive__unpack" -type f -executable
	if bobshell_result_check; then
		bobshell_result_set true "$bobshell_result_2" "$@"
	else
		march_util_get_single_file_from_dir "$_march_runner_archive__unpack/bin" -type f -executable
		if bobshell_result_check; then
			bobshell_result_set true "$bobshell_result_2" "$@"
		else
			bobshell_result_set false false 'executable in archvie not found'
		fi
	fi

	unset _march_runner_archive__unpack

}
