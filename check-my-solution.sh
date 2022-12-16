#!/bin/bash

executable="$1"
tests="$executable.test"
time_limit=10

if ! [[ -f "$executable" ]]; then
	echo "Error: $executable doesn't exist"
	exit 1
fi
if ! [[ -f "$tests" ]]; then
	echo "Error: $tests doesn't exist"
	exit 1
fi

number_of_lines=$(wc -l "$tests" | awk '{print $1}')
((number_of_lines++))
mode="test"
is_first=1

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
			#input="$(echo "$input" | tr '\n' ' ' | tr -s '[:blank:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
			output="$(echo "$output" | tr '\n' ' ' | tr -s '[:blank:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
			finished_gracefuly=0
			if actual_output="$(timeout $time_limit echo "$input" | "$executable" | tr '\n' ' ' | tr -s '[:blank:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"; then
				finished_gracefuly=1
			fi
			echo "[TEST $test_n]"
			if ((finished_gracefuly == 0)); then
				echo "ERROR: Execution time exceeded the time limit ($time_limit)"
			elif [[ "$actual_output" != "$output" ]]; then
				execution_time="$(
					TIMEFORMAT='%lR'
					time (sh -c "echo \"$input\" | \"$executable\"") 2>&1 1>/dev/null
				)"
				echo "ERROR: Wrong output"
				echo "Input:"
				echo "$input"
				echo "Expected output:"
				echo "$output"
				echo "Output:"
				echo "$actual_output"
				echo "Time:"
				echo "$execution_time"
			else
				execution_time="$(
					TIMEFORMAT='%lR'
					time (sh -c "echo \"$input\" | \"$executable\"") 2>&1 1>/dev/null
				)"
				echo "OK"
				echo "Time:"
				echo "$execution_time"
			fi

			echo ""

			output=""
			input=""
		fi

		if [[ "$current_line" =~ [[]TEST' '[0-9]+[]] ]]; then
			test_n="$(echo "$current_line" | grep -oE "[0-9]+")"
			((is_first *= 0))
		fi

	elif [[ "$mode" == "in" ]]; then
		input+="$current_line"
		input+=$'\n'
	elif [[ "$mode" == "out" ]]; then
		output+=" $current_line "
	elif [[ "$mode" == "test" ]]; then
		true
		#echo "test"
	fi

done
