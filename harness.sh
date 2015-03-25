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

groups=''

function testing {
	TESTING="$1"
}

function pass {
	RESULT=0
	echo "$TESTING : PASS"
}

function fail {
	RESULT=1
	echo "$TESTING : FAIL - $1"
}

function run {
	if answer=("$@")
	then
		pass
	else
		fail "$answer"
	fi
}

export -f testing pass fail run

groups="${groups} gabc_gtex"
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
		run diff -q --label "$outfile" <(tail -n +3 "$outfile") --label "$expfile" <(tail -n +3 "$expfile")
	else
		fail "Failed to compile $filename"
	fi

	return $RESULT
}
export -f gabc_gtex_test

groups="${groups} gabc_dump"
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
		run diff -q "$outfile" "$expfile"
	else
		fail "Failed to compile $filename"
	fi

	return $RESULT
}
export -f gabc_dump_test

groups="${groups} gabc_output"
function typeset_and_compare {
	indir="$1"
	outdir="$2"
	texfile="$3"
	pdffile="${texfile%.tex}.pdf"

	if latexmk -pdf -pdflatex='lualatex --shell-escape' --output-directory="$outdir" "$texfile" >&/dev/null
	then
		if cd "$outdir" && mkdir expected && convert "../$pdffile" expected/page.png && convert "$pdffile" page.png
		then
			for name in page*.png
			do
				if ! compare -metric AE "$name" "expected/$name" "diff-$name" 2>/dev/null
				then
					fail "$indir/$outdir/$name differs from expected"
					return
				fi
			done
			pass
		else
			fail "Failed to create images for $indir/$outdir/$pdffile"
		fi
	else
		fail "Failed to typeset $indir/$outdir/$texfile"
	fi
}
export -f typeset_and_compare

function gabc_output_find {
	find gabc-output -name '*.gabc' -print
}
function gabc_output_test {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	filebase="${filename%.gabc}"
	outdir="$filebase.out"
	texfile="$filebase.tex"

	testing "$1"

	if cd "${indir}" && mkdir "${outdir}"
	then
		if sed -e "s/###FILENAME###/$filebase/" "$testroot/gabc-output.tex" >${texfile}
		then
			typeset_and_compare "$indir" "$outdir" "$texfile"
		else
			fail "Could not create $indir/$outdir/$texfile"
		fi
	else
		fail "Could not create $indir/$outdir"
	fi

	return $RESULT
}
export -f gabc_output_test

groups="${groups} tex_output"
function tex_output_find {
	find tex-output -name '*.tex' -print
}
function tex_output_test {
	indir="$(dirname "$1")"
	filename="$(basename "$1")"
	outdir="${filename%.gabc}.out"

	testing "$1"

	if cd "$indir" && mkdir "$outdir"
	then
		typeset_and_compare "$indir" "$outdir" "$filename"
	else
		fail "Could not create $indir/$outdir"
	fi

	return $RESULT
}
export -f tex_output_test
