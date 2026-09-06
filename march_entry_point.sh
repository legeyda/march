#!/usr/bin/env shelduck_run
set -eu



shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/shift.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/apply.sh


shelduck import ./march.sh

main() {
	# self test
	bobshell_result_set true
	bobshell_result_check
	bobshell_result_unset


	# delegate to march
	bobshell_app_name=march

	#
	march "$@"
	if ! bobshell_result_check; then
		bobshell_result_shift
		bobshell_result_apply bobshell_die
	fi
}


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/entry_point.sh
