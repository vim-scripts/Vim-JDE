module Vjde
    def Vjde.getTagFiles(tagsVar)
        # get the 'tags' VIM variable
        #tagsVar = VIM::evaluate("&tags") #"./tags,/"

        # if the user does not have his/her
        # 'tags' variable set :
        if ( (tagsVar == "") || (tagsVar == nil) )
            # we provide a reasonnable default :
            tagsVar = "./tags,/"
        end

        curDir = curVimDir()
        # As the current directory may contain spaces, we need to reintroduce
        # backspaces in the current directory.
        curDir.gsub!(/ /, '\\ ')

        # replace eg ./tags by `pwd`.tags
        # this is useful for the uniq! done
        # at the end of this function.
        # i don't want to parse once `pwd`/tags
        # and once ./tags...
        tagsVar.gsub!(/^\./, curDir)

        # we split by " " but NOT by "\ ",
        # which is a valid space in a filename
        result = tagsVar.scan(/(?:\\ |[^,; ])+/)

        # now we remove the "\ ", ruby
        # otherwise later when we replace
        # all the "\" by "/" for the windows
        # paths, all is messed up.
        result.each { |tr|
            tr.gsub!(/\\ / ," ")

            # in here i want only paths with "/"
            # separators. that's the ruby way
            # (hey, i didn't say i think it's a good
            # idea :O/)
            tr.gsub!(/\\/, "/")
        }

        # we support the "/" trick: if 'tags'
        # include "/", then we check all the files
        # in directories under us.
        if result.include?("/")
            result.delete("/")
            # now we must add "pwd/tags" and all subdirs
            # 		# we start at the dir under us.
            # 		curDir = dirUp(Dir.pwd)
            # current directory
            curDir = curVimDir() 
            while (!File.rootDir?(curDir))
                result.push(curDir + "/tags")
                curDir = File.dirUp(curDir)
            end
            # we didn't add rootdir/tags yet
            result.push("#{curDir}/tags")
        end
        # remove duplicate dirs
        result.uniq!

        return result
    end


    def Vjde.generateIndex(fileName,len=1)
        index = 0
        latter=" "*len
        f_tag = File.open(fileName)
        f_idx = File.open(fileName+".idx","w")
        f_tag.each_line { |line|
            if ( line[0,len]!=latter)
                latter=line[0,len]
                f_idx.puts latter+"\t"+index.to_s
            end
            index = f_tag.pos
        }
        f_tag.close()
        f_idx.close()
    end

    # return the current directory.
    # depending on cpoptions, this might
    # be the path of the current file, or
    # the current directory itself (and those
    # might of course be different)
    def Vjde.curVimDir()
        # is pwd(), if 'cpoptions' contains 'd'
        #if (VIM::evaluate('&cpoptions').include?(?d))
        curDir = Dir.pwd
        #else
        #curDir = VIM::evaluate("expand('%:p:h')")
        #end
        return curDir
    end

    # some more methods for the class
    # file...
    class MyFile
        # will return path itself if path
        # is the root of the drive.
        # requires "/" as the dir separator,
        # even on windows (do a gsub to fix it
        # if needed)
        def File.dirUp(path)
            # remove final "/" if there is one
            cleanPath = path.chomp(File::SEPARATOR)
            return path if (File.rootDir?(path))
            File.split(cleanPath)[0]
        end

        # is this dir the root dir?
        # requires "/" as the dir separator,
        # even on windows (do a gsub to fix it
        # if needed)
        def File.rootDir?(path)
            # remove final "/" if there is one
            cleanPath = path.chomp(File::SEPARATOR)
            # UNIX root dir:
            return true if path == "/"
            # windows network drives \\machine\drive\dir
            # we're at the root if it's something like
            # \\machine\drive
            return true if cleanPath =~ %r{^//\w+/\w+$}
            # now standard windows root directories
            # (a: c: d: ...)
            return true if cleanPath =~ /^[a-zA-Z]:$/
            return false
        end
    end

    # manages one tag.
    class CtagsTag
        attr_reader :scope
        attr_reader :name
        attr_reader :className
        attr_reader :type
        attr_reader :inherits
        attr_reader :access

        def initialize(name, file, type, line, scope, inherits, className, access)
            @name = name
            @file = file
            @type = type
            @line = line
            @scope = scope
            @inherits = inherits
            @className = className
            @access = access
        end

        # for debug.
        def to_s()
            return "tag, name : " + @name + ", file : " + @file + ", type : " + @type + ", line : " + ((@line==nil)?(""):(@line)) + ", scope : " + ((@scope == nil)?(""):(@scope)) + ", inherits : " + ((@inherits == nil)?(""):(@inherits)) + ", className : " + ((@className == nil)?(""):(@className)) + ", access : \"" + ((@access == nil)?(""):(@access)) + "\""
        end

        # for now "==" is not defined for speed (i often do comparisons
        # will nil)

        # I need a hash method because Array.uniq uses it
        # to remove duplicate elements and I want that duplicate
        # elements are properly accounted for...
        def hash
            return @name.hash() + @type.hash()
        end

        # http://165.193.123.250/book/ref_c_object.html#Object.hash
        # "must have the property that a.eql?(b) implies a.hash == b.hash."
        # without this, Array.uniq doesn't work properly.
        def eql?(other)
            return hash == other.hash
        end

        # here is a ctags line:
        # ENTRY_AUTH_KEYCHANGE	snmp/usm/SnmpUser.java	/^	public static final String ENTRY_AUTH_KEYCHANGE = ".6";$/;"	f	class:SnmpUser	access:default
        def CtagsTag.getTagFromCtag(ctag_line, knownTags)

            # ;\ separates the "extended" information
            # from the standard one.
            ctag_infos = ctag_line.split('$/;"')

            ctag_infos_base = ctag_infos[0].split("\t")


            if ( ctag_infos[1] == nil) 
                return
            end
            ctag_infos_ext = ctag_infos[1].split("\t")


            index = 2 # at 0 it's "", at 1 it's the tag type (c, m, f, ...)
            while (ctag_infos_ext[index] != nil)
                info = [] #ctag_infos_ext[index].split(":")
                infoindex = ctag_infos_ext[index].index(":")
                return if infoindex == -1

                info << ctag_infos_ext[index][0,infoindex]
                info << ctag_infos_ext[index][infoindex+1,ctag_infos_ext[index].length]

                infoindex = info[1].index("::")
                if (infoindex != nil)
                    info[1][0,infoindex+2]=""
                end
                # possible optimisation: call chomp only
                # if it's REALLY the last identifier of the line,
                # not "just in case" like that.
                if (info[0] == "line")
                    line = info[1].chomp
                end
                if (info[0] == "inherits")
                    inherits = info[1].chomp.split(",")
                end
                if ( (info[0] == "class") || (info[0] == "interface") )
                    className = info[1].chomp
                end
                if (info[0] == "access")
                    access = info[1].chomp
                end
                index = index + 1
            end
            # since there is no ctag_infos_ext[index], there will
            # be a carriage return here.
            # 		ctag_infos_ext[index-1].chomp!

            scope = ctag_infos_ext[3]
            # 		if (scope != nil)
            # 			scope.chomp!
            # 		end

            result = CtagsTag.new(ctag_infos_base[0].chomp, ctag_infos_base[1].chomp, ctag_infos_ext[1].chomp, line, scope, inherits, className, access)
            # if the tag is already known..
            # 		if (knownTags.include?(result))
            # # 			puts "already known tag"
            # 			# don't parse it again
            # 			return nil
            # 		end
            return result
        end

        # is this tag a method? (language dependant)
        # (do it in the constructor and cache it?)
        def tagMethod?()
            lang = language()
            return (@type == "m" ||  @type=="f") if (lang == "java")
            return (@type == "f") if (lang == "cpp")
        end

        # is this tag defining a class? (language dependant)
        def tagClass?()
            return (@type == "c") || (@type == "i")
        end

        # language for this tag (do it in the constructor and cache it?)
        def language()
            return "java" if (@file =~ /java\Z/ )
            return "cpp" if ( (@file =~ /cpp\Z/) || (@file =~ /cc\Z/) || (@file =~ /h\Z/) || (@file =~ /hpp\Z/) )
        end

    end

    class CtagsTagList
        def initialize(tagsVar="./tags,")

            # TODO split normal tags and class tags.

            # will contain all the tags of the tag file.
            @nonClassTags = Array.new()
            @classTags = Array.new()
            @matchingTags = Array.new()
            # 		@classByName = Hash.new()

            # will contain an Array<String> containing
            # names of classes for which there is no tag
            # and that I do not have to look for again
            # in the future. eg if you use QT, you might
            # not have the tag info for all QT classes..
            # this is for performance (see classByName)
            @blacklist = Array.new()

            # will contain the name of all the classes that were
            # not found in the researches through the directories
            # may contain duplicate names
            # may contain classes that were not found in one directory
            # and found in another. you'll have to do a "detect" at
            # the end to find the relevant ones.
            @missingClasses = Array.new()

            @tagFiles = getTagFiles(tagsVar)
            @local_depth = 0
        end

        # parsing. TODO: parse only what I need..
        def parseTags(tagFile,classSearchedName,beginning,firstonly=false,classonly=false)

            #puts tagFile,classSearchedName,beginning
            # if we want to keep all info
            # in memory, don't remove the already
            # parsed tags. otherwise, remove them,
            # we'll keep the relevant stuff in
            # matchingTags.
            if (!$keepAllInfo)
                @nonClassTags = Array.new
            end

            seek = 0
            headLen = -1
            compareLen = -1
            if (beginning.length>0)
                if(FileTest.exist?(tagFile+".idx"))
                    idx = File.open(tagFile+".idx")
                    if ( compareLen ==-1)
                        str = idx.gets()
                        compareLen = str.index("\t")
                        headLen = compareLen
                        if ( compareLen > beginning.length)
                            compareLen = beginning.length
                        end
                    end
                    idx_line = idx.find { |line| line[0,compareLen]==beginning[0,compareLen]}
                    if (idx_line ==nil) 
                        return 
                    end
                    seek = idx_line[headLen+1,idx_line.length].to_i
                end
            end

            file = File.open(tagFile)
            file.seek(seek)
            # now we parse the ctags output
            ctags_line = file.gets
            file.each_line { |ctags_line|
                #while ( ctags_line != nil) 
                #next 
                if (ctags_line[0,2]== "!_")
                    #ctags_line= file.gets
                    next
                end
                if ( ctags_line[0,beginning.length]>beginning)
                    break
                end	       

                tag = Tag.getTagFromCtag(ctags_line, @matchingTags)
                next if tag==nil 
                #print tag.name,tag.className
                if (tag.tagClass?())
                    if (tag.name == classSearchedName)
                        @classTags.push(tag)
                        break if firstonly
                    end
                else if (!classonly)
                    if (tag.className== classSearchedName)
                        @nonClassTags.push(tag)
                        break if firstonly
                    end
                end
        end
        #ctags_line = file.gets
            }
            #end
            file.close
    end

    # list public methods of this taglist that
    # have the class name you give and which (the methods)
    #names start with "beginning".
    def listMethods(className, beginning,max_depth=1,curr=0)
        @tagFiles.each { |curFile|
            next if (!FileTest.exist?(curFile))

            @classSearched = classByName(className)
            if @classSearched == nil
                searchForMethods(curFile,className,className,true,true)
                @classSearched = classByName(className)

                if ( @classSearched!= nil)
                    searchForMethods(curFile, className, beginning)
                    if ( @classSearched.inherits!= nil&& curr<max_depth)
                        @classSearched.inherits.each { |ih|
                            listMethods(ih,beginning,max_depth,curr+1)
                        }
                    end
                end
            end

            @missingClasses += @blacklist
            @blacklist.clear
        }
        #find the tag , then , find the parent
    end

    def putsMethods()
        @missingClasses.uniq!
        @missingClasses.each { |className|
            item = @matchingTags.detect { |tag|
                (tag.name == className)
            }
            if (item == nil)
                puts "WARNING: did not find definition of " + className
            end
        }
        @matchingTags.uniq!
        if ( @matchingTags.size() ==0)
            puts "not found"
            return
        end
        @matchingTags.each { |tag|
            if ( tag.tagMethod?() && ( (tag.access == "public") \
                        || (tag.access == "") \
                        || (tag.access == "default") \
                        || (tag.access == nil) ) )
                puts tag.name + " [" + tag.className + "] " 
            end
        }
    end
    def methodsToLine()
        @missingClasses.uniq!
        @missingClasses.each { |className|
            item = @matchingTags.detect { |tag|
                (tag.name == className)
            }
            if (item == nil)
                puts "WARNING: did not find definition of " + className
            end
        }
        retstr = ""
        @matchingTags.uniq!
        @matchingTags.each { |tag|
            if ( tag.tagMethod?() && ( (tag.access == "public") \
                        || (tag.access == "") \
                        || (tag.access == "default") \
                        || (tag.access == nil) ) )
                #puts tag.name + " [" + tag.className + "] "  
                retstr += VIM::evaluate("s:pre_beginning")+tag.name+"\n"
            end
        }
        return retstr
    end
    def searchForMethods(tagFile, classSearchedName, beginning,firstonly=false,classonly=false)
        #if (VIM::evaluate("&verbose").to_i > 0)
        #	puts "parsing tags for " + tagFile
        #end
        parseTags(tagFile,classSearchedName,beginning,firstonly,classonly)
        @matchingTags.concat(@nonClassTags)
        @nonClassTags.clear()

        #@classSearched = classByName(classSearchedName)
        #if @classSearched == nil
        #	parseTags(tagFile,classSearchedName,classSearchedName,false)
        #	currentClass = classByName(classSearchedName)

        #if ( currentClass != nil)
        #if ( currentClass.inherits!= nil)
        #currentClass.inherits.each { |ih|

        #	listMethods(ih,beginning)
        #parseTags(tagFile,ih,beginning,false)
        #	}
        #end
        #end
        #end

        #@matchingTags.concat(@nonClassTags)
        #@nonClassTags.clear()

    end

    # get a Tag object from this TagList and a class name string.
    def classByName(className)
        # we keep a blacklist of classes. For instance
        # if you are using say QT, you'll have constant references
        # to QObject, that is not in your tag files.
        # to avoid checking all the tags looking for this class
        # each time that I'm asked for it, I just blacklist it once for all.
        # this happened with KoRect in kword, and the time went from
        # 12 seconds to instantaneous...
        #return nil if @blacklist.include?(className)
        @classTags.each { |tag|
            #puts "classByName: found " + tag.name
            if (tag.name == className)
                return tag
            end
        }

        return nil
    end


end

end
# this file separator API is badly broken
# or I missed something..

# puts "ruby invoked : " + Time.now.min.to_s + ":"+ Time.now.sec.to_s
#$keepAllInfo =false 
#Vjde.generateIndex('d:\workspace\vjde\plugin\vjde\tlds\jdk1.5.lst',6)
#Vjde.generateIndex("/usr/share/vim/vimfiles/plugin/vjde/tlds/jdk1.5.lst")

#taglist = TagList.new("/home/wangfc/workspace/smgpapp/tags,/tmp/tags,/usr/java/jdk/src/tags")
#taglist.listMethods("MySQL", "Ex",1)
#taglist.putsMethods()

