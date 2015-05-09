# Gregorio Tests
# Copyright (C) 2015 Gregorio Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

export PASS="${C_GOOD}PASS${C_RESET}"
export FAIL="${C_BAD}FAIL${C_RESET}"

groups=''

function register {
    method_missing=false

    for method in test accept view_log view_diff view_expected view_output
    do
        if [ "$(type -t ${1}_$method)" != "function" ]
        then
            method_missing=true
            echo "${1}_method is not defined in harness.sh"
        fi
    done

    if $method_missing
    then
        exit 100
    fi

	groups="${groups} $1"
	export -f ${1}_test
}

function testing {
	TESTING="$1"
}

if $show_success
then
    function pass {
        RESULT=0
        echo "$TESTING : $PASS"
    }
else
    function pass {
        RESULT=0
    }
fi

function fail {
	RESULT=1
	echo "$TESTING : $FAIL - $1"
}

function not_verified {
    RESULT=0
    echo "$TESTING : not verified"
}

function maybe_run {
	if $verify
	then
		if answer=$("$@")
		then
			pass
		else
			fail "$answer"
		fi
	else
		not_verified
	fi
}

function accept_result {
	echo "Accepting $2 as expectation for $1"
	cp "$2" "$testroot/tests/$(dirname "$1")/$3"
}

function view_text {
    if [ "$VIEW_TEXT" = "" ]
    then
        echo "Unable to view $1"
        echo 'VIEW_TEXT is not set.'
    elif [ ! -r "$1" ]
    then
        echo "Unable to view $1"
        echo 'File does not exist.'
    else
        cmd="${VIEW_TEXT//\{file\}/$1}"
        echo "$cmd"
        eval $cmd
    fi
}

function view_pdf {
    if [ "$VIEW_PDF" = "" ]
    then
        echo "Unable to view $1"
        echo 'VIEW_PDF is not set.'
    elif [ ! -r "$1" ]
    then
        echo "Unable to view $1"
        echo 'File does not exist.'
    else
        cmd="${VIEW_PDF//\{file\}/$1}"
        echo "$cmd"
        eval $cmd
    fi
}

function view_images {
    if [ "$VIEW_IMAGES" = "" ]
    then
        echo "Unable to view $@"
        echo 'VIEW_IMAGES is not set.'
    elif [ "$#" = "0" -o ! -r "$1" ]
    then
        echo 'No files to view exist.'
    else
        cmd="${VIEW_IMAGES//\{files\}/$@}"
        pwd
        echo "$cmd"
        eval $cmd
    fi
}

function diff_text {
    if [ "$DIFF_TEXT" = "" ]
    then
        echo "Unable to view $1"
        echo 'DIFF_TEXT is not set.'
    elif [ ! -r "$2" ]
    then
        echo "Unable to diff against $2"
        echo 'File does not exist.'
    else
        cmd="${DIFF_TEXT//\{expect\}/$1}"
        cmd="${cmd//\{output\}/$2}"
        echo "$cmd"
        eval $cmd
    fi
}

function diff_pdf {
    if [ "$DIFF_PDF" = "" ]
    then
        echo "Unable to view $1"
        echo 'DIFF_PDF is not set.'
    elif [ ! -r "$2" ]
    then
        echo "Unable to diff against $2"
        echo 'File does not exist.'
    else
        cmd="${DIFF_PDF//\{expect\}/$1}"
        cmd="${cmd//\{output\}/$2}"
        echo "$cmd"
        eval $cmd
    fi
}

export -f testing pass fail not_verified maybe_run

function gabc_gtex_find {
	find gabc-gtex -name '*.gabc' -print
}
function gabc_gtex_test {
	filename="$1"
	outfile="${filename}.out"
	logfile="${filename}.log"
	expfile="${filename%.gabc}.tex"

	testing "$filename"

	if gregorio -f gabc -F gtex -o "$outfile" -l "$logfile" "$filename"
	then
        sed -e 's/^\(% File generated by gregorio \).*/\1@/' \
            -e 's/\(\gregoriotexapiversion{\)[^}]\+/\1@/' \
            "$outfile" > "$outfile-"
        sed -e 's/^\(% File generated by gregorio \).*/\1@/' \
            -e 's/\(\gregoriotexapiversion{\)[^}]\+/\1@/' \
            "$expfile" > "$expfile-"
		maybe_run diff -q "$outfile-" "$expfile-"
	else
		fail "Failed to compile $filename"
	fi

	return $RESULT
}
function gabc_gtex_accept {
    accept_result "$1" "$1.out" "$(basename "${1%.gabc}").tex"
}
function gabc_gtex_view_log {
	view_text "$1.log"
}
function gabc_gtex_view_diff {
	filename="$1"
    diff_text "${filename%.gabc}.tex-" "${filename}.out-"
}
function gabc_gtex_view_expected {
	view_text "${1%.gabc}.tex-"
}
function gabc_gtex_view_output {
	view_text "${filename}.out-"
}
register gabc_gtex

function gabc_dump_find {
	find gabc-dump -name '*.gabc' -print
}
function gabc_dump_test {
	filename="$1"
	outfile="${filename}.out"
	logfile="${filename}.log"
	expfile="${filename%.gabc}.dump"

	testing "$filename"

	if gregorio -f gabc -F dump -o "$outfile" -l "$logfile" "$filename"
	then
        sed -e 's/[0-9]\+\( (\(GRE\|S\|G\|L\)_\)/@\1/' "$outfile" > "$outfile-"
        sed -e 's/[0-9]\+\( (\(GRE\|S\|G\|L\)_\)/@\1/' "$expfile" > "$expfile-"
        maybe_run diff -q "$outfile-" "$expfile-"
	else
		fail "Failed to compile $filename"
	fi

	return $RESULT
}
function gabc_dump_accept {
	accept_result "$1" "$1.out" "$(basename "${1%.gabc}").dump"
}
function gabc_dump_view_log {
	view_text "$1.log"
}
function gabc_dump_view_diff {
	filename="$1"
    diff_text "${filename%.gabc}.dump-" "${filename}.out-"
}
function gabc_dump_view_expected {
	view_text "${1%.gabc}.dump-"
}
function gabc_dump_view_output {
	view_text "${filename}.out-"
}
register gabc_dump

function typeset_and_compare {
	indir="$1"; shift
	outdir="$1"; shift
	texfile="$1"; shift
	pdffile="${texfile%.tex}.pdf"

	if "$@" --output-directory="$outdir" "$texfile" >&/dev/null
	then
		if $verify
		then
			if cd "$outdir" && mkdir expected && convert "../$pdffile" expected/page.png && convert "$pdffile" page.png
			then
                declare -a failed
				for name in page*.png
				do
					if ! compare -metric AE "$name" "expected/$name" "diff-$name" 2>/dev/null
					then
                        failed[${#failed[@]}]="$indir/$outdir/$name"
					fi
				done
                if [ ${#failed[@]} != 0 ]
                then
                    fail "[${failed[*]}] differ from expected"
                    return
                fi
				pass
			else
				fail "Failed to create images for $indir/$outdir/$pdffile"
			fi
		else
			not_verified
		fi
	else
		fail "Failed to typeset $indir/$outdir/$texfile"
	fi
}
function accept_typeset_result {
	filebase="$(basename "$1")"
	filebase="${filebase%.$2}"
    accept_result "$1" "$1.out/$filebase.pdf" "$filebase.pdf"
}
function view_typeset_diff {
    if [ "$DIFF_PDF" = "" ]
    then
        (cd "$1/$2" && view_images diff-page*.png)
    else
        diff_pdf "$1/$3" "$1/$2/$3"
    fi
}
export -f typeset_and_compare accept_typeset_result view_typeset_diff

function gabc_output_find {
	find gabc-output -name '*.gabc' -print
}
function gabc_output_test {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"
	filebase="${filename%.gabc}"
	texfile="$filebase.tex"

	testing "$1"

	if cd "${indir}" && mkdir "${outdir}"
	then
		if sed -e "s/###FILENAME###/$filebase/" "$testroot/gabc-output.tex" >${texfile}
		then
			typeset_and_compare "$indir" "$outdir" "$texfile" latexmk -pdf -pdflatex='lualatex --shell-escape'
		else
			fail "Could not create $indir/$outdir/$texfile"
		fi
	else
		fail "Could not create $indir/$outdir"
	fi

	return $RESULT
}
function gabc_output_accept {
	accept_typeset_result "$1" gabc
}
function gabc_output_view_log {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

	view_text "$indir/$outdir/${filename%.gabc}.log"
}
function gabc_output_view_diff {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

    view_typeset_diff "$indir" "$outdir" "${filename%.gabc}.pdf"
}
function gabc_output_view_expected {
	view_pdf "${1%.gabc}.pdf"
}
function gabc_output_view_output {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

    view_pdf "$indir/$outdir/${filename%.gabc}.pdf"
}
register gabc_output

function tex_output_find {
	find tex-output -name '*.tex' -print
}
function tex_output_test {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="${filename}.out"

	testing "$1"

	if cd "$indir" && mkdir "$outdir"
	then
		typeset_and_compare "$indir" "$outdir" "$filename" latexmk -pdf -pdflatex='lualatex --shell-escape'
	else
		fail "Could not create $indir/$outdir"
	fi

	return $RESULT
}
function tex_output_accept {
	accept_typeset_result "$1" tex
}
function tex_output_view_log {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

	view_text "$indir/$outdir/${filename%.tex}.log"
}
function tex_output_view_diff {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

    view_typeset_diff "$indir" "$outdir" "${filename%.tex}.pdf"
}
function tex_output_view_expected {
	view_pdf "${1%.tex}.pdf"
}
function tex_output_view_output {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

    view_pdf "$indir/$outdir/${filename%.tex}.pdf"
}
register tex_output

function plain_tex_find {
	find plain-tex -name '*.tex' -print
}
function plain_tex_test {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="${filename}.out"

	testing "$1"

	if cd "$indir" && mkdir "$outdir"
	then
		typeset_and_compare "$indir" "$outdir" "$filename" luatex --shell-escape
	else
		fail "Could not create $indir/$outdir"
	fi

	return $RESULT
}
function plain_tex_accept {
	accept_typeset_result "$1" tex
}
function plain_tex_view_log {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

	view_text "$indir/$outdir/${filename%.tex}.log"
}
function plain_tex_view_diff {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

    view_typeset_diff "$indir" "$outdir" "${filename%.tex}.pdf"
}
function plain_tex_view_expected {
	view_pdf "${1%.tex}.pdf"
}
function plain_tex_view_output {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="$filename.out"

    view_pdf "$indir/$outdir/${filename%.tex}.pdf"
}
register plain_tex
