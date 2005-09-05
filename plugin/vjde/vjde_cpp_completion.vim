"{{{1
if !has('ruby')
	echo 'C++ completion is ruby required!!'
	finish
endif

let g:vjde_cpp_previewer= VjdePreviewWindow_New()

if !exists('g:vjde_cpp_exts')
	let g:vjde_cpp_exts='cpp;c;cxx;h;hpp;hh'
endif
let s:types=[]
let g:vjde_cpp_previewer.name = 'g:vjde_cpp_previewer'
let g:vjde_cpp_previewer.onSelect='VjdeInsertWord'
let g:vjde_cpp_previewer.previewLinesFun='GetCTAGSCompletionLines'
let g:vjde_cpp_previewer.docLineFun=''
func! VjdeGetCppType(v)
	let lnr = line('.')
	let cnr = col('.')
	let pattern='\<\i\+\>\(\s*<.*>\)*\(\s*\[.*\]\)*[* \t]\+\<'.a:v.'\>'
	let pos = VjdeGotoDefPos(pattern,'b')
	if pos[0]==0
		call cursor(lnr,cnr)
		return a:v
	endif
	let lstr = getline(pos[0])
	let vt = matchstr(lstr,'[^ \t\[\<]\+',pos[1]-1)
	call cursor(lnr,cnr)
	return vt
endf
func! VjdeCppCFU(line,base,col,findstart) "{{{2
    if a:findstart
        let s:last_start  = VjdeFindStart(a:line,a:base,a:col,'[.> \t:?)(+\-*/&|^,]')
	return s:last_start
    endif
    let lstr = strpart(a:line,0,a:col)
    let lstr = substitute(lstr,'::','.','g')
    let lstr = substitute(lstr,'->','.','g')
    " call the parameter info
    if a:line[s:last_start-1]=='(' && (s:last_start == a:col)
	    let s:types=VjdeObejectSplit(VjdeFormatLine(lstr[0:-2].'.'))
	    if len(s:types)==1
		    return CtagsCompletion3(s:types[0])
	    else
		    let vt = VjdeGetCppType(s:types[0])
		    return CtagsCompletion4(vt,s:types[-1])
	    end
	    return ""
    endif
    let s:types=VjdeObejectSplit(VjdeFormatLine(lstr))
    if len(s:types)==0  " completion for global functions
	    return CtagsCompletion(a:base)
    endif
    let v = s:types[0]
    " std:: string::
    if a:line[s:last_start-1]==':' 
	    return CtagsCompletion2(v,a:base)
    endif
    let vt = VjdeGetCppType(v)
    if ( strlen(vt)>0)
	    return CtagsCompletion2(vt,a:base)
    endif
    return ''
endf
func! VjdeCppCompletion(char,short)
    let lstr = getline(line('.'))
    let cnr = col('.')
    let Cfu=function(&cfu)
    let s:last_start  = Cfu(lstr,'',cnr,1)
    if s:last_start < 0
	    return
    endif

    if lstr[s:last_start-1]=='('
	    let mstr = Cfu(lstr,strpart(lstr,s:last_start,cnr-s:last_start),cnr,0)
	    if mstr == ''
		    return ''
	    endif
	    let str = ''
	    let items = VjdeGetCppCFUTags()
	    for item in items
		    let str.=item.cmd."\n"
	    endfor
	    call g:vjde_cpp_previewer.PreviewInfo(str)
	    return mstr
    endif
    call g:vjde_cpp_previewer.CFU(a:char,a:short)
endf

func! VjdeCppGenerateIdx(...)
	let mtags = &tags
	let len = 2
	if ( a:0 > 0)
		let len = a:1
	endif
	for item in split(mtags,",")
ruby<<EOF
	Vjde.generateIndex(VIM::evaluate("item"),VIM::evaluate("len").to_i)
EOF
	endfor
endf
"{{{ auto command 
for item in split(g:vjde_cpp_exts,';')
	if strlen(item)>0
		exec 'au BufNewFile,BufRead,BufEnter *.'.item.' set cfu=VjdeCppCFU'
		exec 'au BufNewFile,BufRead,BufEnter *.'.item.' imap <buffer> <C-space> <Esc>:call VjdeCppCompletion("<C-space>",0)<CR>a'
	endif
endfor


"vim:fdm=marker:ff=unix
