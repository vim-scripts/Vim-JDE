
let s:project_name=""

function! s:VjdeUpdateMenu(name) "{{{2
    "exec 'aun .10 Vim\ &JDE.Project<TAB>'.s:project_name.' :<CR>'
    "let s:project_name=a:name
    "exec 'amenu! .10 Vim\ &JDE.Project<TAB>'.s:project_name.' :<CR>'
endf
function! VjdeBrowseProject() " {{{2
    let prj=""
    if has("browse")
        let prj = browse(0,"Please Select a Vim JDE Project",".","")
    else
        let prj = input("Please Enter a Vim JDE Project:")
    endif
    if prj == ""
        return 
    endif
    call s:VjdeLoadProject(prj)
endf

function! s:VjdeLoadProject(prj) " {{{2
    call s:VjdeUpdateMenu(a:prj)
    exec 'source '.a:prj
    let s:project_name=a:prj
    let g:vjde_java_cfu = {}
endf
function! VjdeSaveMenu()
    call s:VjdeSaveProject()
endf
function! VjdeSaveAsMenu()
        if has("browse")
            let prj = browse(0,"Please Select a Vim JDE Project",".","")
        else
            let prj = input("Please Enter a Vim JDE Project:")
        endif
        call s:VjdeSaveProjectAs(prj)
endf
function! s:VjdeSaveProject() " {{{2
    let prj=""
    if s:project_name==""
        if has("browse")
            let prj = browse(1,"Please Select a Vim JDE Project",".","")
        else
            let prj = input("Please Enter a Vim JDE Project:")
        endif
        if prj!=""
            call s:VjdeSaveProjectAs(prj)
            let s:project_name=prj
        endif
    else
        call s:VjdeSaveProjectAs(s:project_name)
    endif
endf
func! s:VjdeWriteStr(name) 
	call add(s:lines,'let '.a:name."=\"".escape(eval(a:name),'"')."\"")
endf
func! s:VjdeWriteNumber(name) 
	call add(s:lines,'let '.a:name."=".eval(a:name))
endf
function! s:VjdeSaveProjectAs(prj) " {{{2
	let s:lines=[]
	call s:VjdeWriteStr("g:vjde_out_path")
	call s:VjdeWriteStr("g:vjde_src_path")
	call s:VjdeWriteStr("g:vjde_lib_path")
	call s:VjdeWriteStr("g:vjde_web_app")
	call s:VjdeWriteStr("g:vjde_test_path")
	call s:VjdeWriteStr("g:vjde_java_command")
	call s:VjdeWriteNumber("g:vjde_show_paras")
	call s:VjdeWriteNumber("g:vjde_xml_advance")
	if has('ruby')
ruby<<EOF
$vjde_tlds.each { |file,u|
#f.puts "VjdeaddTld "+file+" " + u 
VIM::command("call add(s:lines,'VjdeaddTld '.escape('#{file}',' ').' '.escape('#{u}',' '))")
}
$vjde_dtd_loader.dtds.each { |s|
#f.puts "VjdeaddDtd " + s.mname + " " + s.malias
VIM::command("call add(s:lines,'VjdeaddDtd '.escape('#{s.mname}',' ').' '.escape('#{s.malias}',' '))")
}
EOF
	endif
	call add(s:lines,'" vim :ft=vim:')
	call writefile(s:lines,a:prj)
	let s:lines=[]
	let s:project_name = a:prj
	return
endf
function! VjdeSetJava(str) 
	let g:vjde_java_command=a:str
endf
function! VjdeGetJava()
    return g:vjde_java_command
endf
function! s:VjdeAddTld(...) "{{{2
    let uri=""
    if (a:0==0) 
        echo "Vjdeaddtld <file> [uri]"
        return 
    endif
    if (a:0>=2)
        let uri=a:2
    endif
ruby<<EOF
    loader = Vjde::VjdeProjectTlds.instance
    loader.add(VIM::evaluate("a:1"),VIM::evaluate("uri"))
EOF
endf
function! s:VjdeAddDtd(...) "{{{2
    let al=''
    if (a:0==0) 
        echo 'VjdeAddDtd <file> [name]'
        return 0
    endif
    if (a:0>=2)
        let al=a:2
    endif
    ruby $vjde_dtd_loader.load(VIM::evaluate('a:1'),VIM::evaluate('al'))
endf
function! VjdeListDtds()
ruby<<EOF
str = "["
str << '"http://www.w3.org/1999/XSL/Transform"'
str << ","
str << '"http://www.w3.org/TR/html4"'
str << ","
str << '"http://www.w3.org/TR/html401"'
$vjde_dtd_loader.dtds.each { |d|
str << ',"'+d.malias+'"'
}
str << ']'
VIM::command("let res1="+str);
EOF
return res1
endf
func! s:VjdeRunCurrent(...)
        if a:0>1
                exec "!java  -cp \"".g:vjde_lib_path."\" ".a:1
        endif
        let cname = expand("%:t:r")
        let cpath= expand("%:h")
        if  strlen(g:vjde_src_path)!=0 && match(cpath,g:vjde_src_path)==0 
                let cpath = strpart(cpath,strlen(g:vjde_src_path)+1)
        elseif strlen(g:vjde_test_path)!=0 && match(cpath,g:vjde_test_path)==0  
                let cpath = strpart(cpath,strlen(g:vjde_test_path)+1)
        endif
        exec "!java  -cp \"".g:vjde_lib_path."\" ".substitute(cpath,'[/\\]','.','g').".".cname
endf
" create menu here {{{2
amenu Vim\ &JDE.Project.Project :
amenu Vim\ &JDE.Project.--Project-- :
amenu Vim\ &JDE.Project.Load\ Project\.\.\.    :call VjdeBrowseProject() <CR>
tmenu Vim\ &JDE.Project.Load\ Project\.\.\.    Browse a project file to use.
amenu Vim\ &JDE.Project.Save\ Project    :call VjdeSaveMenu()<CR>
amenu Vim\ &JDE.Project.Save\ Project\ As\.\.\.      :call VjdeSaveAsMenu()<CR>
amenu Vim\ &JDE.Project.--other--      :
amenu Vim\ &JDE.Project.Load\ STL\ TLDS  :VjdeJstl <CR>
tmenu Vim\ &JDE.Project.Load\ STL\ TLDS  loade the Standard taglibray for use
amenu Vim\ &JDE.Project.Avaiable\ Dtds\ \.\.\.      :echo VjdeListDtds()<CR>
tmenu Vim\ &JDE.Project.Avaiable\ Dtds      Query the available Docuement type definations (xml)
amenu <silent> Vim\ &JDE.Project.Add\ DTD(XML)\ \.\.\.      :let sefile =has('browse')? browse(0,"DTD File",".",""):inputdialog("Input a Document Type Define file",".","") <BAR> let ns=inputdialog("Enter the namspace or other name","") <BAR> call <SID>VjdeAddDtd(sefile,ns)<CR>
amenu <silent> Vim\ &JDE.Project.Add\ TLD(JSP)\ \.\.\.      :let sefile = has('browse')?browse(0,"TLD File",".",""):inputdialog("Input a Taglib Library Define file",".","") <BAR> let ns=inputdialog("Enter the uri for tld,(maybe empty)","") <BAR> call <SID>VjdeAddTld(sefile,ns)<CR>
tmenu <silent> Vim\ &JDE.Project.Add\ TLD(JSP)     add Taglib defination file to project 
amenu Vim\ &JDE.-Operation-    :
amenu Vim\ &JDE.Show\ &Information<TAB>:Vjdei  :Vjdei<CR>
tmenu Vim\ &JDE.Show\ &Information<TAB>:Vjdei  show the variable , function or class infomation
amenu Vim\ &JDE.Goto\ &Declarition<TAB>:Vjdegd        :Vjdegd<CR>
tmenu Vim\ &JDE.Goto\ &Declarition<TAB>:Vjdegd       Goto defination of current function, search the [path] 
amenu Vim\ &JDE.-template-    :
amenu Vim\ &JDE.&Wizard.Wizard  :
amenu Vim\ &JDE.&Wizard.--template1--  :
amenu Vim\ &JDE.-Refactor-    :
amenu Vim\ &JDE.&Source.&Override\ methods\ \.\.\.  :call Vjde_override(0)<CR>
amenu Vim\ &JDE.&Source.&Implements\ interfaces\ \.\.\.  :call Vjde_override(1)<CR>
amenu Vim\ &JDE.&Source.&Generate\ Constructor  :call VjdeGenerateConstructor()<CR>
amenu Vim\ &JDE.&Source.Generate\ Getter/&Setter :call Vjde_get_set()<CR>
amenu Vim\ &JDE.&Source.Add\ S&ingleton\ stub    :call VjdeAppendTemplate("Singleton") <CR>
amenu Vim\ &JDE.&Source.--source1-- :
amenu Vim\ &JDE.&Source.Extract\ to\ &local  :call Vjde_rft_var(2)<CR>
amenu Vim\ &JDE.&Source.Extract\ to\ &member  :call Vjde_rft_var(1)<CR>
amenu Vim\ &JDE.&Source.Extract\ to\ &argument  :call Vjde_rft_arg()<CR>
vmenu Vim\ &JDE.&Source.Extract\ to\ &const  :call Vjde_rft_const()<CR>
vmenu Vim\ &JDE.&Source.Surround\ with\ &try/catch  :call Vjde_surround_try()<CR>
vmenu Vim\ &JDE.&Source.&sort\ import  :call Vjde_sort_import()<CR>
amenu Vim\ &JDE.&Source.&extract\ import\ \.\.\.  :call Vjde_ext_import()<CR>
amenu Vim\ &JDE.&Source.--doc--  :
amenu Vim\ &JDE.&Source.Create\ Java&Doc	:call JCommentWriter()<cr>
vmenu Vim\ &JDE.&Source.Create\ JavaDocE&x	:call JCommentWriter()<cr>
amenu Vim\ &JDE.&Source.Invalidate\ JavaDoc	:call SearchInvalidComment(0)<cr>
amenu Vim\ &JDE.-fixtools-    :
amenu Vim\ &JDE.Fixerror\ with\ &try/catch    :call Vjde_fix_try()<CR>
amenu Vim\ &JDE.Fixerror\ with\ th&rows    :call Vjde_fix_throws()<CR>
amenu Vim\ &JDE.Fixerror\ with\ &import    :call Vjde_fix_import()<CR>
amenu Vim\ &JDE.&Add\ import  :call Vjde_fix_import1()<CR>
amenu Vim\ &JDE.-tools-    :
amenu Vim\ &JDE.&Compile\ file    :comp javac <BAR> Vjdec <CR>
amenu Vim\ &JDE.&Run\ file    :Vjder <CR>
amenu <silent> Vim\ &JDE.Run\ c&lass\.\.\.    :let cls = inputdialog("input the class name(with package) :","") <BAR> call <SID>VjdeRunCurrent(cls) <CR>
amenu Vim\ &JDE.-Params-    :
amenu Vim\ &JDE.Settings.Settings     :
amenu Vim\ &JDE.Settings.-Params1-    :
amenu <silent> Vim\ &JDE.Settings.Set\ Source\ Path\ \.\.\. :let g:vjde_src_path=has('browse')?browsedir("The source path:",g:vjde_src_path): inputdialog("Please Enter the source path:",g:vjde_src_path) <CR>
    amenu <silent> Vim\ &JDE.Settings.Set\ Test-Source\ Path\ \.\.\. :let g:vjde_test_path=has('browse')?browsedir("Test-source path:",g:vjde_test_path):inputdialog("Please Enter the test-source path:",g:vjde_test_path) <CR>
    amenu <silent> Vim\ &JDE.Settings.Set\ WebApp\ Path\ \.\.\. :let g:vjde_web_app=has('browse')?browsedir("WebApp path:",g:vjde_web_app):inputdialog("Please Enter the WebApp path:",g:vjde_web_app) <CR>
    amenu <silent> Vim\ &JDE.Settings.Add(jar/path)\ To\ class\ path\ \.\.\. :let g:vjde_lib_path.=g:vjde_path_spt.has('browse')?browse(0,"WebApp path:",".",''):inputdialog("Please Enter the classpath:",g:vjde_lib_path) <CR>
    amenu <silent> Vim\ &JDE.Settings.Set\ Class\ Path\ \.\.\. :let g:vjde_lib_path=inputdialog("Please Enter the classpath:",g:vjde_lib_path) <CR>
    amenu <silent> Vim\ &JDE.Settings.Set\ Out\ Path\ \.\.\. :let g:vjde_out_path=has('browse')?browsedir("Out dir:",g:vjde_out_path):inputdialog("Please Enter the Out dir:",g:vjde_out_path) <CR>
amenu  Vim\ &JDE.Settings.--cfu-- :
amenu <silent> Vim\ &JDE.Settings.Set\ Java\ command :let str=inputdialog("Please Enter the java command[".VjdeGetJava()."]:","java") <BAR> call VjdeSetJava(str) <CR>
amenu <silent> Vim\ &JDE.Settings.Reload\ lib\ path :let  g:vjde_java_cfu={} <CR>
amenu <silent> Vim\ &JDE.Settings.Show\ Params(on/off) :let g:vjde_show_paras=1-g:vjde_show_paras <CR>
amenu <silent> Vim\ &JDE.Settings.Completion\ Child(XML)(on/off) :let g:vjde_xml_advance=1-g:vjde_xml_advance <CR>
amenu <silent> Vim\ &JDE.Settings.Previews.-previ1-	:
amenu <silent> Vim\ &JDE.Settings.Previews.Show\ preview(console)\ (on/off) :let g:vjde_show_preview=1-g:vjde_show_preview <CR>
amenu <silent> Vim\ &JDE.Settings.Previews.-preview2-	:
amenu <silent> Vim\ &JDE.Settings.Previews.Show\ preview(gui)\ (on/off)	:let g:vjde_preview_gui=1-g:vjde_preview_gui <CR>
amenu <silent> Vim\ &JDE.Settings.Previews.Set\ preview(gui)\ width	:let g:vjde_preview_gui_width=inputdialog("The width of the preview window",g:vjde_preview_gui_width) <CR>
amenu <silent> Vim\ &JDE.Settings.Previews.Set\ preview(gui)\ height	:let g:vjde_preview_gui_height=inputdialog("The width of the preview window",g:vjde_preview_gui_height) <CR>
amenu  Vim\ &JDE.Settings.--find-- :
amenu  Vim\ &JDE.Settings.Add\ source\ to\ path   :exec 'set path+='.g:vjde_src_path <CR>
amenu  Vim\ &JDE.Settings.Add\ Test\ source\ to\ path   :exec 'set path+='.g:vjde_src_path <CR>
amenu Vim\ &JDE.-help-    :
amenu Vim\ &JDE.Create\ Index     :helptag $VIM/vimfiles/doc <CR>
amenu Vim\ &JDE.Vjde\ Help<TAB>:h\ vjde     :h vjde<CR>
"command for project {{{2
command!  -nargs=1 -complete=file Vjdeload call s:VjdeLoadProject(<f-args>)
command!  -nargs=* -complete=file Vjdeas call s:VjdeSaveProjectAs(<f-args>)
command!  -nargs=* -complete=file VjdeaddTld call s:VjdeAddTld(<f-args>)
command!  -nargs=* -complete=file VjdeaddDtd call s:VjdeAddDtd(<f-args>)
command!  -nargs=0 Vjdelistdtds echo VjdeListDtds()
command!  -nargs=0 -complete=file Vjdesave call s:VjdeSaveProject()
command! -nargs=0 Vjdec :exec "make -d \"".g:vjde_out_path."\" -classpath \"".g:vjde_lib_path."\" ".expand("%")
command! -nargs=0 Vjder :call s:VjdeRunCurrent()
if v:version>=700
    "command!  -nargs=0 Vjdesetup set cfu=VjdeCompletionFun 
endif

" vim:fdm=marker :ff=unix
