#!/usr/bin/env shelduck_run
set -eu



shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh
# shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/run.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/regex/match.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/subcommand.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/equals_any.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/array/call.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/array/insert.sh

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/unset.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/apply.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/remove.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/insert.sh

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/cli/setup.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/cli/parse.sh

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/event/fire.sh


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/foreach.sh


shelduck import ./util.sh
shelduck import ./download.sh
shelduck import ./runner.sh

main() {
	# self test
	bobshell_result_set true
	bobshell_result_check
	bobshell_result_unset


	# delegate to march
	bobshell_app_name=march

	march "$@"
	if ! bobshell_result_check; then
		bobshell_result_shift
		bobshell_result_apply bobshell_die
	fi
}



# march --size=298961400 \
#		--md5=3ac85eda13a87bc24698aa5041e63510 \
#       --sha256=8e26ee9ce094c24e9c79a6221388e190ebd5eb94831b98d575d45978f45ea87a \
#		https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/3.16



# bobshell_download [OPTIONS] URL
bobshell_cli_setup march_run --param --var=_march__cli_id     i app-id

# runners
bobshell_cli_setup march_run --flag  --var=_march__exe      exe
bobshell_cli_setup march_run --flag  --var=_march__appimage appimage
bobshell_cli_setup march_run --flag  --var=_march__appimage_no_sandbox appimage-no-sandbox

bobshell_cli_setup march_run --flag  --var=_march__archive      archive
bobshell_cli_setup march_run --param  --var=_march__archive_exe  archive-exe

# caching
bobshell_cli_setup march_run --param  --var=_march__expected_size size
bobshell_cli_setup march_run --param  --var=_march__expected_md5 md5
bobshell_cli_setup march_run --param  --var=_march__expected_sha256 sha256

march() {
    : "${MARCH_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/$bobshell_app_name}"


    if [ "${1:-}" = run ]; then
        _march__subcommand=run
        shift
    elif [ "${1:-}" = install ];  then
        _march__subcommand=install
    else
        _march__subcommand=run
    fi

	# parse cli
	bobshell_cli_parse march_run "$@"
	shift "$bobshell_cli_shift"

	if [ $# -eq 0 ]; then
		bobshell_result_set false 'url expected'
		return
	fi

	if bobshell_isset _march__cli_id; then
		_march__id="${_march__cli_id}"
	else
		_march__id=$(printf %s "$1" | sed 's/[\/<>:\\|?*]/-/g')
	fi

	if bobshell_isset _march__expected_md5 && [ 32 -ne "${#_march__expected_md5}" ] ; then
		bobshell_result_set false 'wrong md5sum'
		return
	fi


	if bobshell_isset _march__expected_sha256 && [ 64 -ne "${#_march__expected_sha256}" ] ; then
		bobshell_result_set false 'wrong sha256'
		return
	fi

    bobshell_event_fire march_cli_check "$@"

    march_"$_march__subcommand" "$@"


}

march_install() {
    bobshell_die install not implemented
}

read_file() {
    if [ -f "$1" ]; then
        bobshell_result_set true ''
        bobshell_result_2=$(cat "$1")
    else
        bobshell_result_set false 'file not found'
    fi
}

march_download_file_name() {
    bobshell_result_set false ''
    if [ -r "${MARCH_CACHE}/$_march__id/download-file-name" ]; then
        bobshell_result_2=$(cat ${MARCH_CACHE}/$_march__id/download-file-name)
    fi


    if [ "$#" -gt 1 ]; then
        bobshell_die 'not implemented'
    else
        "${MARCH_CACHE}/$_march__id/download-file-name"
    fi

}





# fun: march_run URL [ARGS ... ]
march_run() {
    march_runner "$@"
    if bobshell_result_check; then
        bobshell_result_1=exec
        bobshell_result_apply
    fi
}
