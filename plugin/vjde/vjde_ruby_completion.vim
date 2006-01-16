if !exists('g:vjde_loaded') || &cp
	finish
endif
if !exists('g:vjde_ruby_include')
	let g:vjde_ruby_include=''
endif
let g:vjde_ruby_previewer= VjdePreviewWindow_New()
let g:vjde_ruby_previewer.name = 'g:vjde_ruby_previewer'
let g:vjde_ruby_previewer.onSelect='VjdeInsertWord'
let g:vjde_ruby_previewer.previewLinesFun='GetRubyCompletionLines'
let g:vjde_ruby_previewer.docLineFun=''

let s:matched_member=[]
let s:header=''
func! GetRubyCompletionLines(previewer) "{{{2
	call add(a:previewer.preview_buffer,s:header)
	for item in s:matched_member
		call add(a:previewer.preview_buffer,item.kind.' '.item.name.';')
	endfor
endf
func! RubyMember_New(kind,name)
	return {'kind' : a:kind,
				\ 'name':a:name }
endf
func! VjdeGetRubyType(v)
	return inputdialog('Input the type of the variable','Object')
endf
func! VjdeRubyCFU0(findstart,base)
	return VjdeRubyCFU(getline('.'),a:base,col('.'),a:findstart)
endf
func! s:AddToPreviews(kind,name)
	call add(s:matched_member,RubyMember_New(a:kind,a:name))
endf
func! VjdeRubyCFU(line,base,col,findstart) "{{{2
    if a:findstart
        let s:last_start  = VjdeFindStart(a:line,a:base,a:col,'[.> \t:?)(+\-*/&|^,]')
	return s:last_start
    endif
    let tp = VjdeGetRubyType(a:base)
    if strlen(tp) < 1
	    return ''
    endif
    let base=a:base
    let s:lines=''
    let s:header=tp.':'
    if !empty(s:matched_member)
	    call remove(s:matched_member,0,-1)
    endif
ruby <<EOF
	eval(' a = '+VIM::evaluate('tp')+'.new')
	base = VIM::evaluate('base')
	if base==nil || base==''
		a.methods.each { |m|
		VIM::command('call s:AddToPreviews("function","'+m+'")')
		}
	else
		a.methods.each { |m|
		VIM::command('call s:AddToPreviews("function","'+m+'")') if m[0,base.length]==base
		}
	end
EOF
	return join(s:matched_member,"\n")
endf
let item='rb'
exec 'au BufNewFile,BufRead,BufEnter *.'.item.' set cfu=VjdeRubyCFU0'
exec 'au BufNewFile,BufRead,BufEnter *.'.item.' imap <buffer> '.g:vjde_completion_key.' <Esc>:call g:vjde_ruby_previewer.CFU("<C-space>",0)<CR>a'
