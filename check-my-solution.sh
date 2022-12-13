#!/bin/bash

executable="$1"
tests="$executable.test"
time_limit=2

if ! [[ -f "$executable" ]]; then
	echo "Error: $executable doesn't exist"
	exit 1
fi
if ! [[ -f "$tests" ]]; then
	echo "Error: $tests doesn't exist"
	exit 1
fi

number_of_lines=$(wc -l "$tests" | awk '{print $1}')
mode="test"
is_first=1
test_regex=" "
for ((i = 1; i <= number_of_lines + 1; i++)); do
	if ((i != number_of_lines + 1)); then
		current_line="$(awk "NR==$i" "$tests")"
	else
		current_line=" "
	fi

	if [[ "$current_line" == "[IN]" ]]; then
		mode="in"
	elif [[ "$current_line" == "[OUT]" ]]; then
		mode="out"
	elif [[ "$current_line" =~ [[]TEST' '[0-9]+[]] ]] || ((i == number_of_lines + 1)); then
		mode="test"
		if ((is_first == 0 || i == number_of_lines + 1)); then
			input="$(echo "$input" | tr '\n' ' ' | tr -s '[:blank:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
			output="$(echo "$output" | tr '\n' ' ' | tr -s '[:blank:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
			finished_gracefuly=0
			actual_output="$(timeout $time_limit echo "$input" | "$executable" | tr '\n' ' ' | tr -s '[:blank:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' && finished_gracefuly=1)"
			execution_time="$( TIMEFORMAT='%lR';time ( sh -c "echo \"$input\" | \"$executable\"" ) 2>&1 1>/dev/null)"
			
			echo "[TEST $test_n]"
			echo "Input:"
			echo "$input"
			echo "Output:"
			echo "$actual_output"
			echo "Expected output:"
			echo "$output"
			echo "Time:"
			echo "$execution_time"
			echo ""
			
			output=""
			input=""
		fi

		if [[ "$current_line" =~ [[]TEST' '[0-9]+[]] ]]; then
			test_n="$(echo "$current_line" | grep -oE "[0-9]+")"
			((is_first *= 0))
		fi

	elif [[ "$mode" == "in" ]]; then
		input+=" $current_line "
	elif [[ "$mode" == "out" ]]; then
		output+=" $current_line "
	elif [[ "$mode" == "test" ]]; then
		echo "test"
	fi

done
