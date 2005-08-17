
func! VjdeReadIniFile(filename)
	if !filereadable(a:filename)
		return {}
	endif
	let lines = readfile(a:filename)
	call filter(lines,'v:val !~ "^\s*$"')
	let mps = {}
	for item in lines
		if item[0]=~'^\s*#'
			continue 
		endif
		let pairs = matchlist(item,'^\s*\([^ \t]*\)\s*=\s*\(.*\)$')
		if len(pairs)>=3
			let mps[pairs[1]] = pairs[2]
		endif
	endfor
	return mps
endf

func! SkipToIgnoreString(line,index,target) "{{{2
    let start = a:index
    let len = strlen(a:line)
    while start < len
        if ( a:line[start]=~a:target) 
            return start
        endif
        if ( a:line[start]=='\')
            let start=start+1
        elseif (a:line[start]=='"')
            let start=SkipToIgnoreString(a:line,start+1,'"')
            if start == -1
                return -1
            end
        endif
        let start=start + 1
    endwhile
    return -1
endf

func! VjdeFindUnendPair(line,firstc,secondc,start,endcol) "{{{2
    let res = SkipToIgnoreString(a:line,a:start,a:firstc)
    while res != -1
        let res2 = SkipToIgnoreString(a:line,res,a:secondc)
        if ( res2 == -1 || res2>=a:endcol )
            return res
        endif
        let res = SkipToIgnoreString(a:line,res2,a:firstc)
    endw
    return -1
endf "}}}2
"vim:fdm=marker:ff=unix
