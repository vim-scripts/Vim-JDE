require 'vjde_taglib_cfu.rb'
#puts loader.tlds
#loader.tlds.each { |key,val|
#        val.each_tag { |tg|
#            puts tg.get_text("name")
#        }
#}
class Generator
    attr_accessor   :ns
    attr_accessor :file
    def initialize(ns,file)
        @ns = ns
        @file = file
    end
    def to_stdout
        loader = Vjde::Tld_Loader.instance
        loader.load(@file)
        #loader = Vjde::DTD_Parser.new()
        #loader.parse(File.new(@file))
        puts "let g:xmldata_#{@ns}= {"
        dchar=''
        doc = nil
        loader.tlds.each { |k,v| doc = v } 
        line=''
        doc.each_tag { |a|
            puts "#{line}\\ '"+a.get_text("name").to_s+"': [ " 
            cs = [] 
            achar=''
            cchar=''
            print "\\ ["
            c = 0
            #loader.each_child(a.name) { |b| 
            #    if (b.class== Array ) 
            #        cs.concat( b)
            #    else
            #        cs << b
            #    end
            #}
            #cs.each { |b| 
            #    print "#{cchar}'#{b}'"
            #    cchar = ' , '
            #    c=c+1
            #    print "\n\\ " if c%6==5
            #}
            puts "],"
            print "\\ { "
            doc.each_attr(a) { |c|
                print "#{achar}'"+c.get_text("name").to_s+"' : ["
                bchar=''
                #loader.each_value(a.name,c.name) { |d| 
                #    if ( d.class==Array)
                #        print "#{bchar}'",d.join("' , '"),"'"
                #        bchar=','
                #    else
                #        print "#{bchar}'#{d}'"
                #        bchar=','
                #    end
                #}
                print "]"
                achar = ','
            }
            puts "}"
            line = "\\  ],\n"
        }
        puts "\\ ]}"
    end
end
if $*.length == 2
    gen = Generator.new($*[1],$*[0])
    gen.to_stdout
end

