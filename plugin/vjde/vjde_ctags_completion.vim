let s:matched_tags=[]
let s:retstr=''
let s:header=''
func! GetCTAGSCompletionLines(previewer) "{{{2
	call add(a:previewer.preview_buffer,s:header)
	for item in s:matched_tags
		call add(a:previewer.preview_buffer,item.kind.' '.item.name.';'.item.cmd)
	endfor
endf
func! s:VjdeAddToTags(name,kind,cmd) "{{{2
	call add(s:matched_tags,{ 'name' : a:name , 'kind' : a:kind , 'cmd' : a:cmd })
endf
func! s:VjdeCleanTags() "{{{2
	if !empty(s:matched_tags)
		call remove(s:matched_tags,0,-1)
	endif
endf
func! VjdeGetCppCFUTags()
	return s:matched_tags
endf

func! CtagsCompletion(word) "{{{2
	if strlen(a:word)==0
		return
	endif
	call s:VjdeCleanTags()
	let word = a:word
	let s:header = word.':'
ruby<<EOF
	taglist = Vjde::CtagsTagList.new(VIM::evaluate('&tags'))
	str=''
	taglist.max=150
	taglist.count=0
	taglist.each_tag(VIM::evaluate('word')) { |t,f|
		VIM::command('call s:VjdeAddToTags("'+t.name+'","'+t.kind+'","'+t.cmd+'")')
		str=str+t.name+"\n"
		taglist.count+=1
	}
	VIM::command('let s:retstr="'+str+'"')
EOF
	return s:retstr
endf

func! CtagsCompletion2(cls,word) "{{{2
	call s:VjdeCleanTags()
	let s:header = a:cls.':'.a:word
	let cls = a:cls
	let word = a:word
ruby<<EOF
	taglist = Vjde::CtagsTagList.new(VIM::evaluate('&tags'))
	str=''
	taglist.max=100
	taglist.count=0
	taglist.each_member(VIM::evaluate('cls'),VIM::evaluate('word')) { |t,f|
		VIM::command('call s:VjdeAddToTags("'+t.name+'","'+t.kind+'","'+t.cmd+'")')
		str=str+t.name+"\n"
		taglist.count+=1
	}
	VIM::command('let s:retstr="'+str+'"')
EOF
	return s:retstr
endf
func! CtagsCompletion3(word) "{{{2
	if strlen(a:word)==0
		return
	endif
	call s:VjdeCleanTags()
	let word = a:word
	let s:header = word.':'
	let s:retstr=''
ruby<<EOF
	taglist = Vjde::CtagsTagList.new(VIM::evaluate('&tags'))
	str=''
	taglist.max=10
	taglist.count=0
	word = VIM::evaluate('word')
	taglist.each_tag(word) { |t,f|
		next if t.name != word
		VIM::command('call s:VjdeAddToTags("'+t.name+'","'+t.kind+'","'+t.cmd+'")')
		str=str+t.name+"\n"
		taglist.count+=1
	}
	VIM::command('let s:retstr="'+str+'"')
EOF
	return s:retstr
endf
func! CtagsCompletion4(cls,word) "{{{2
	call s:VjdeCleanTags()
	let s:header = a:cls.':'.a:word
	let cls = a:cls
	let word = a:word
	let s:retstr=''
ruby<<EOF
	taglist = Vjde::CtagsTagList.new(VIM::evaluate('&tags'))
	str=''
	taglist.max=30
	taglist.count=0
	word = VIM::evaluate('word')
	taglist.each_member(VIM::evaluate('cls'),word) { |t,f|
		next if t.name!= word
		VIM::command('call s:VjdeAddToTags("'+t.name+'","'+t.kind+'","'+t.cmd+'")')
		str=str+t.name+"\n"
		taglist.count+=1
	}
	VIM::command('let s:retstr="'+str+'"')
EOF
	return s:retstr
endf
