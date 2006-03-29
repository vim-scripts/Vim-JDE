if !exists('g:vjde_loaded') || &cp
	finish
endif
if !exists('g:vjde_cs_libs')
	let g:vjde_cs_libs=''
	echo 'Add g:vjde_cs_libs in your _vimrc!'
endif
if !exists('g:vjde_cs_cmd')
	let g:vjde_cs_cmd='mono.exe '.g:vjde_install_path.'/vjde/CSParser.exe'
endif
let g:vjde_cs_cfu={}

let s:types=[]
let s:type=''
let s:success=1
let s:last_start = 0

func! s:VjdeCSGetTypeName(var) 
	let tname = VjdeGetTypeName(a:var)
	if tname=='string'
		return "String"
	endif
	return tname
endf
func! VjdeCSGetUsing() 
	let retstr=''
	let l = line('.')
	let c = col('.')
	let l:line_us = search('^\s*using\s\+','Wb')
	let l:str=''
	let l:cend=0
	while l:line_us > 0 
		let l:str = getline(l:line_us)
		let l:cend = matchend(l:str,'^\s*using\s\+')
		if l:cend != -1
			let retstr = retstr.matchstr(l:str,".*$",l:cend)
		endif
		let l:line_us = search('^\s*using\s\+','Wb')
	endwhile
	call cursor(l,c)
	return retstr
endf
func! VjdeCSCompletion(findstart,base)
	if a:findstart
		let s:last_start=VjdeFindStart(getline('.'),a:base,col('.'),'[.@ \t]')
		return s:last_start
	endif
	let usingstr = VjdeCSGetUsing()
	let lline = getline('.')
	let lcol = col('.')
	let s:types = VjdeObejectSplit(VjdeFormatLine(strpart(lline,0,s:last_start)))
	if len(s:types) < 1 
		return ""
	endif
	let s:type=s:VjdeCSGetTypeName(s:types[0])
	if s:type=='' 
		let s:type=s:types[0]
	endif
        let s:beginning = a:base
	call VjdeCSCompletionVIM(usingstr)
	if g:vjde_cs_cfu.success
		return s:VjdeGeneratePerviewMenu(a:base)
	endif
	return ""
endf
func! s:VjdeGeneratePerviewMenu(base)
    let lval= []
    if strlen(a:base)==0
        for member in g:vjde_cs_cfu.class.members
            call add(lval,{'word': member.name , 'kind': 'm' ,  'info': member.type,'icase':0})
        endfor
        for method in g:vjde_cs_cfu.class.methods
            call add(lval,{'word': method.name."(" , 'kind' : 'f', 'info': method.ToString(),'icase':0})
        endfor
    else
        for member in g:vjde_cs_cfu.class.SearchMembers('stridx(member.name,"'.a:base.'")==0')
            call add(lval,{'word': member.name , 'kind': 'm' ,  'info': member.type ,'icase':0})
        endfor
        for method in g:vjde_cs_cfu.class.SearchMethods('stridx(method.name,"'.a:base.'")==0')
            call add(lval,{'word': method.name."(" , 'kind' : 'f', 'info': method.ToString(),'icase':0})
        endfor
    endif
    return lval
endf
func! VjdeCSCompletionVIM(usingstr)
	"if empty(g:vjde_cs_cfu) 
		let g:vjde_cs_cfu=VjdeCSCompletion_New(g:vjde_cs_cmd,g:vjde_cs_libs)
	"endif
	call g:vjde_cs_cfu.FindClass(s:type,a:usingstr)
	if !g:vjde_cs_cfu.success
		return 0
	endif
	let index = 1
	let length = len(s:types)
	let success = 1
	while index < length && success
		let rettype=''
		for member in g:vjde_cs_cfu.class.members
			if s:types[index]==member.name
				let rettype= member.type
			endif
		endfor
		if rettype==''
			for method in g:vjde_cs_cfu.class.methods
				if s:types[index]==method.name
					let rettype= method.ret_type
				endif
			endfor
		endif
		if rettype==''
			let success = 0
		else
			call g:vjde_cs_cfu.FindClass(rettype,'')
			let success = g:vjde_cs_cfu.success
		endif
		let index+=1
	endwhile
	let s:success = success
	return s:success
endf
func! VjdeCSCompletion_FindClass(name,imptstr,...) dict 
    let cmd = self.cmd. ' '.a:name.' "'.self.dllpath.'" "'.a:imptstr.'" '.s:beginning
    let str = system(cmd)
    if strlen(str) < 10 
        let self.success = 0
        return {}
    endif
    let self.success = 1
    let self.class = VjdeJavaClass_New(VjdeListStringToList(str))
    return self.class
endf
func! VjdeCSCompletion_New(cmd,path) 
    let inst = { 'cmd' : a:cmd , 'dllpath': a:path , 'class': { } , 'success' :0 ,
                \'FindClass':function('VjdeCSCompletion_FindClass') }
    return inst
endf
 if v:version>=700
    au BufNewFile,BufRead,BufEnter *.cs set cfu=VjdeCSCompletion
 endif
"let cscompletion = VjdeCSCompletion_New('mono.exe '.g:vjde_install_path.'/vjde/CSParser.exe','d:\Mono-1.1.13.4\lib\mono\2.0\mscorlib.dll')
"let cscompletion = VjdeCSCompletion_New('mono.exe e:/temp/CSParser.exe','d:\Mono-1.1.13.4\lib\mono\2.0\mscorlib.dll')
"let mclass = cscompletion.FindClass('Console','System')
"if cscompletion.success 
"	for item2 in	mclass.members
"		echo item2.ToString()
"	endfor
"endif
