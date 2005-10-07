if !exists('g:vjde_loaded') || &cp
	finish
endif
if exists('g:vjde_iab_loaded') || &cp || !has('ruby') "{{{1
	finish
endif
let g:vjde_iab_loaded = 1
if !exists('g:vjde_iab_refs')
	let g:vjde_iab_refs={}
endif
if !has_key(g:vjde_iab_refs,'jsp')
	let g:vjde_iab_refs['jsp']=[ 'java', 'html' ]
endif
if !has_key(g:vjde_iab_refs,'cpp')
	let g:vjde_iab_refs['cpp']=[ 'c' ]
endif
let s:all_templates={}
let s:templates = []
let s:add_lines = []

let s:templates_ft={}


let g:iab_previewer = VjdePreviewWindow_New()
let g:iab_previewer.name='iab_previewer'
let g:iab_previewer.onSelect='VjdePreviewIabSelect'
let g:iab_previewer.previewLinesFun=''

func! s:VjdeIabbrAdd(name,desc) "{{{2
	call add(s:templates,{'name':a:name,'desc':a:desc})
endf
func! s:VjdeIabbrInit(name) "{{{2
	if !empty(s:templates)
		call remove(s:templates,0,-1)
	endif
	let mf = a:name
ruby<<EOF
$vjde_iab_manager = Vjde::VjdeTemplateManager.GetIAB(VIM::evaluate('mf'))
$vjde_iab_manager.indexs.each_with_index { |ti,i|
	VIM::command('call s:VjdeIabbrAdd("'+ti.name+'","'+ti.desc+'")')
}
EOF
	"let temp = []
	"let temp+= s:templates
	let s:all_templates[mf]=[]
	let s:all_templates[mf]+=s:templates
endf
func! s:VjdeInitPreview(base) "{{{2
	call g:iab_previewer.Clear()
	call g:iab_previewer.Add(&ft.':'.a:base)
	let names = [&ft]
	if has_key(g:vjde_iab_refs,&ft)
		let names += g:vjde_iab_refs[&ft]
	endif
	for name in names
		if !has_key(s:all_templates,name)
			call s:VjdeIabbrInit(name)
		endif
		let templates = get(s:all_templates,name)
		if strlen(a:base)<=0
			for item in templates
				call g:iab_previewer.Add('abbr '.item.name.';'.item.desc)
			endfor
		else
			for item in filter(copy(templates),'v:val.name =~ "^'.a:base.'"')
				call g:iab_previewer.Add('abbr '.item.name.';'.item.desc)
			endfor
		endif
	endfor
endf
let s:paras = {}
func! VjdePreviewIab(paras,...) "{{{2
	if strlen(&ft)==0
		echoerr 'You must setup the filetype of current buffer. :h ft'
		return
	endif
	let base = '' 
	if a:0>1
		let base = a:1
	else
		let base = expand('<cword>')
	endif
	call s:VjdeInitPreview(base)
	let s:paras = a:paras
	call g:iab_previewer.Preview(0)
endf
func! VjdePreviewIabSelect(word)
	let mf = &ft
	if strlen(a:word)>=0
		let s:added_lines = []
		if has_key(g:vjde_iab_refs,mf)
			let mf .= ';'.join(g:vjde_iab_refs[mf],';')
		endif
		
ruby<<EOF
    tn = VIM::evaluate("a:word")
    mf = VIM::evaluate('mf')
    mfs = mf.split(';')
    mfs.delete_if { |f| f.length==0 }
    mfs.each { |f| 
	    $vjde_iab_manager = Vjde::VjdeTemplateManager.GetIAB(f)
	    tplt = $vjde_iab_manager.getTemplate(tn)
	    if tplt != nil
		    tplt.each_para { |p|
		    if "1"==VIM::evaluate('has_key(s:paras,"'+p.name+'")')
			    tplt.set_para(p.name,VIM::evaluate('s:paras["'+p.name+'"]'))
		    else
			    str=VIM::evaluate('inputdialog(\''+p.desc.gsub(/'/,"\\'")+' : \',"")')
			    tplt.set_para(p.name,str)
		    end
		    }

		    tplt.each_line { |l|
		    l.gsub!(/'/,"\\'")
		    l.chomp!
		    VIM::command("call add(s:added_lines,'"+l+"')")
		    }
		    break
	    end
	}
EOF
	if len(s:added_lines) <= 0 
		return 
	endif
		call setline(line('.'),s:added_lines[0])
	if len(s:added_lines)>1	
		call append(line('.'),s:added_lines[1:-1])
	endif
		"exec 'normal '.len(s:added_lines).'k'
		exec 'normal '.len(s:added_lines).'=='
		let lnr = line('.')
		let idx = -1
		for item in s:added_lines
			let idx +=1
			let idx1 = stridx(item,'|')
			if ( idx1 > -1)
				call setline(lnr+idx,substitute(getline(lnr+idx),'|','',''))
				call cursor(lnr+idx,0)
				exec 'normal '.idx1.'l'
				break
			endif
		endfor
	endif
endf

"call s:VjdeIabbrInit()
au BufNewFile,BufRead,BufEnter *.java imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i
au BufNewFile,BufRead,BufEnter *.jsp imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i
au BufNewFile,BufRead,BufEnter *.htm imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i
au BufNewFile,BufRead,BufEnter *.html imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i

if exists('g:vjde_iab_exts')
	for item in split(g:vjde_iab_exts,';')
		exe 'au BufNewFile,BufRead,BufEnter *.'.item.' imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i'
	endfor
endif
"vim:fdm=marker:ff=unix
"
