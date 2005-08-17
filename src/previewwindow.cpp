#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include <string>
#include <vector>
#include <sstream>
#ifdef _WIN32
#include <windows.h>
#include <winuser.h>
#endif



#if defined(DLL) && defined(_WIN32)
#define _DL_EXPORT __declspec(dllexport) extern
#else
#define _DL_EXPORT 
#endif
#ifdef AS_C
extern "C" {
#endif
//ADD COMMENT
//Add by wangfc
	using std::string;
	using std::vector;

	static char pre_select_buffer[256];//user input
	string user_input;
	int key_release_count=0;
	int winposx = 0;
	int winposy = 0;
	gboolean useShort = FALSE;

	guint tag = 0;//timeout id
	guint intval = 1000; //interval


	enum COLUM { TAG_NAME,RET_VAL,COMMENT };

	GtkWidget *window=NULL;
	GtkWidget *input_label = NULL;
	GtkWidget *line_list = NULL;
	GtkWidget *scrolledwindow2=NULL;//		init_list_store();

	GtkListStore* list_store=NULL;

	vector<string> lines;
	string base("");

#ifdef _WIN32
	typedef struct _Rectangle {
		int x;
		int y;
		int width;
		int height;
	} MRectangle;
#else
	typedef GdkRectangle MRectangle;
#endif



	void init_window(int x,int y,int width,int height);
	void on_key_release_event( GtkWidget *widget, GdkEventKey *data );
	void destroy( GtkWidget *widget, gpointer   data );
	char* preview_window(vector<string> &v,const string& base,int x,int y,int width,int height);
	void update_label() ;
	void get_select_val();
	void init_list_store();
	void get_vim_text_area_rectangle(MRectangle &rect);
	void get_desktop_rectangle(MRectangle &rect) ;
	void get_vim_caret_pos(int &x1,int &y1,
			const int line,const int col, // cursor line and col for vim
			const int width1 , const int height1, // vim lines and cols in window
			const int width2 , const int height2); // tool window width heigth
	/*
	gboolean show_docment(gpointer data);
	void timeout_setup() {
		if (tag != -1) {
			g_source_remove(tag);
		}
		tag = g_timeout_add(intval,show_document,NULL)
	}
	*/
#ifdef _GTK_LINUX
	void get_window_rect(GdkWindow* window , MRectangle &rect)
	{
		//gdk_window_get_frame_extents(window,&rect);
		gdk_drawable_get_size(GDK_DRAWABLE(window),&rect.width,&rect.height);
		gdk_window_get_deskrelative_origin(window,&rect.x,&rect.y);
	}
	void get_vim_text_area_rectangle(MRectangle &rect) 
	{
		GdkWindow* root = gdk_get_default_root_window();
		GList *children = gdk_window_peek_children(root);
		GList* temp1 = g_list_first(children);
		GList* temp = NULL;
		int x ,y ;
		while ( temp1 != NULL) {
			gdk_window_get_root_origin(GDK_WINDOW(temp1->data),&x,&y);
			if ( x==winposx && y==winposy) {
				temp = gdk_window_peek_children(GDK_WINDOW(temp1->data));
				break;
			}
			temp1 = g_list_next(temp1);
		}
		if( temp != NULL) {
			get_window_rect(GDK_WINDOW(temp->data),rect);
			//if (rect.x == winposx &&  rect.y>winposy)
			//temp = g_list_next(temp);
		}
	}
	void get_desktop_rectangle(MRectangle &rect) 
	{
		GdkWindow* root = gdk_get_default_root_window();
		get_window_rect(GDK_WINDOW(root),rect);
	}
#endif
#ifdef _WIN32
	HWND m_vimHwnd;
	BOOL CALLBACK EnumWndProc(HWND hWnd,LPARAM lParam)
	{
		HWND* lhwnd=(HWND*)lParam;
		char buf[50];
		::GetClassName(hWnd,buf,50);
		//VimTextArea is the class name of main editing window of VIM
		if (strcmp(buf,"VimTextArea") == 0)
		{
			*lhwnd=hWnd; 
			return FALSE;
		}
		return TRUE;
	}
	void get_vim_text_area_rectangle(MRectangle &rect)
	{
		HWND hTempHwnd = GetForegroundWindow();
		if(hTempHwnd)
		{
			m_vimHwnd = hTempHwnd;
		}
		else
		{
			//but getting VIM window failed get the Desktop window. This is used to get the 
			//VIM rectangle. So even desktop window is also OK.
			m_vimHwnd = ::GetDesktopWindow();
		}
		RECT vimRect;

		HWND hwndText;
		//Get the editing window in the VIM.
		EnumChildWindows(m_vimHwnd,EnumWndProc,(LPARAM)&hwndText);

		
		::GetWindowRect(hwndText,&vimRect);
		rect.x = vimRect.left;
		rect.y = vimRect.top;
		rect.width = vimRect.right-vimRect.left+1;
		rect.height = vimRect.bottom-vimRect.top+1;
	}
	void get_desktop_rectangle(MRectangle &rect) 
	{
		RECT deskRect;
		::GetWindowRect(::GetDesktopWindow(),&deskRect);
		rect.x = deskRect.left;
		rect.y = deskRect.top;
		rect.width = deskRect.right-deskRect.left+1;
		rect.height = deskRect.bottom-deskRect.top +1;
	}
	

#endif
	void get_vim_caret_pos(int &x1,int &y1,
			const int line,const int col, // cursor line and col for vim
			const int width1 , const int height1, // vim lines and cols in window
			const int width2 , const int height2) // tool window width heigth
	{

		MRectangle vimRect ,deskRect;
		get_vim_text_area_rectangle(vimRect);
		get_desktop_rectangle(deskRect);

		int winHeight = vimRect.height;
		int winWidth = vimRect.width;

		
		double vimLine = line;
		double vimCol = col;
		double vimLines = height1;
		double vimCols = width1;

		double dy = (winHeight/(vimLines+1)) * vimLine;
		double dx = (winWidth/(vimCols+1)) * vimCol;
		
		int x = (int) dx + vimRect.x;
		int y = (int) dy + vimRect.y;
		int height = height2;
		int width = width2;

		// if list window is beyond desktop window put it accordingly
		if (y + height > deskRect.height)
		{
			y = y - height - 15;
		}
		if (x + width > deskRect.width)
		{
			//gputleft = true;
			x = x - width;
		}
		else
		{
		}
		x1 =x;
		y1 =y;
	}
	void get_select_val()
	{
		GtkTreeIter iter;
		if(gtk_tree_selection_get_selected(gtk_tree_view_get_selection(GTK_TREE_VIEW(line_list)),
				 ((GtkTreeModel**)(&list_store)),&iter))
		{
			gchar *val;
			gtk_tree_model_get (GTK_TREE_MODEL(list_store), &iter, TAG_NAME,&val, -1);
			user_input.clear();
			//user_input.append(val+(base.length()));
			user_input.append(val);
			g_free(val);
		}
	}
	string get_short_name(string name) 
	{
		if ( !useShort  )   
			return name;
		int index_dot = name.rfind('.');
		if ( index_dot>0) {
			return name.substr(index_dot+1);
		}	
		return name;
	}
	string get_short_tag(string tag)
	{
		if ( !useShort  ) 
			return tag;
		string stag = "";
		string temp;
		int index_dot;

		
		int index = tag.find('(');
		stag.append(tag.substr(0,index+1));
        
		int next = tag.find(',',index);
		index +=1;
		while ( next > 0  ) // find a parameter
		{
			temp = tag.substr(index,next-index);
			stag.append(get_short_name(temp));
			stag.append(",");
			index = next+1;
			next = tag.find(',',index);
		}
		next = tag.find(')',index);
		if ( next >0) 
		{
			temp = tag.substr(index,next-index);
			stag.append(get_short_name(temp));
			//index_dot = temp.rfind('.');
			//if ( index_dot>0) {
				//stag.append(temp.substr(index_dot+1));
			//}	
			//else {
				//stag.append(temp);
			//}
			stag.append(")");
			index = next+1;
			next = tag.find(',',index);
		}
		return stag;
	}
	void create_column(string &temp)
	{
		GtkTreeIter iter_tree;
		int index_space = temp.find_first_of(" \t");
		int index_comma = temp.find(';');
		int index_right = temp.find(')');
		if ( index_space > 0 ) 
		{
			gtk_list_store_append(list_store,&iter_tree);
			if ( index_right > 0 ) //method defination
			{
				if ( index_comma > 0 ) 
				{
					gtk_list_store_set(list_store,&iter_tree,
							RET_VAL,get_short_name(temp.substr(0,index_space)).c_str(),
							TAG_NAME,
								get_short_tag(temp.substr(index_space+1,index_right-index_space)).c_str(),
							COMMENT,index_right < index_comma-1?
								temp.substr(index_right+1,index_comma-index_right-1).c_str():"",
							-1);
				}
				else 
				{
					gtk_list_store_set(list_store,&iter_tree,
							RET_VAL,get_short_name(temp.substr(0,index_space)).c_str(),
							TAG_NAME,get_short_tag(temp.substr(index_space+1)).c_str(),
							COMMENT,""
							-1);
				}
				return;
			}
			if ( index_comma > 0 ) 
			{
				gtk_list_store_set(list_store,&iter_tree,
						RET_VAL,get_short_name(temp.substr(0,index_space)).c_str(),
						TAG_NAME,temp.substr(index_space+1,index_comma-index_space-1).c_str(),
						COMMENT,index_comma <temp.length()-1?temp.substr(index_comma+1).c_str():"",
						-1);
			}
			else 
			{
				gtk_list_store_set(list_store,&iter_tree,
						RET_VAL,get_short_name(temp.substr(0,index_space)).c_str(),
						TAG_NAME,temp.substr(index_space+1).c_str(),
						COMMENT,""
						-1);
			}
		}
	}
	void init_list_store()
	{
		vector<string>::const_iterator iter = lines.begin();
		//skip first line
		if ( iter != lines.end() ) iter++;

		for( ; iter != lines.end(); iter++)
		{
			string temp = *iter;
			create_column(temp);
		}
	}

	void update_label()
	{
		string text = "<span foreground=\"blue\" underline=\"low\">";//style=\"italic\">";
		text += base;
		text += user_input;
		text+="</span>";
		gtk_label_set_markup((GtkLabel*)input_label,text.c_str());
		GtkTreeIter iter  ;
		gchar *val;

		string text1 = base+user_input;
		if ( text1.length()==0) 
			return;
		if ( !gtk_tree_model_get_iter_first(GTK_TREE_MODEL(list_store),&iter)) 
			return;
		do {
			gtk_tree_model_get (GTK_TREE_MODEL(list_store), &iter, TAG_NAME,&val, -1);
			if (strlen(val)>=text1.length()) {
				if ( strncmp(text1.c_str(),val,text1.length())==0 ) { 
					gtk_tree_selection_select_iter(gtk_tree_view_get_selection(GTK_TREE_VIEW(line_list)),
						 &iter);
					gtk_tree_view_set_cursor(GTK_TREE_VIEW(line_list),
							gtk_tree_model_get_path(GTK_TREE_MODEL(list_store), &iter),
							NULL,
							FALSE);
					g_free(val);
					return;
				}
			}
			g_free(val);
		} while(gtk_tree_model_iter_next(GTK_TREE_MODEL(list_store),&iter));
	}

	_DL_EXPORT int has_gtk(char *str) 
	{
		return 1;
	}

	int read_int(string &firstline,char sp,int len,int &curr) 
	{
		int index = firstline.find(';',curr);
		index = index==-1?len:index;
		int x = atoi(firstline.substr(curr,index-curr).c_str());
		curr = index+1;
		return x;
	}
	//50;50;200;100;abc;
	//cursor col; cursor line;text area width;text area height;window width;window height;vim pos x;vim posy;a:base;
	_DL_EXPORT char* preview(char *str)
	{
		string para(str);

		std::istringstream input(para);
		string temp;
		while (getline(input,temp)) {
			lines.push_back(temp);
		}
		int x = 50;
		int y = 50;
		int width=250;
		int height=100;
		int tw=50;
		int th = 50;
		if ( lines.size()>0) 
		{
			string firstline=lines[0];
			int len = firstline.length();
			int curr = 0;
			if ( curr < len ) {
				x = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				y = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				tw = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				th = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				width = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				height = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				winposx = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				winposy = read_int(firstline,';',len,curr);
			}
			if ( curr < len ) {
				useShort = read_int(firstline,';',len,curr)>0;
			}
			if ( curr < len ) {
				int index = firstline.find(';',curr);
				index = index==-1?len:index;
				base = firstline.substr(curr,index-curr);
				curr = index+1;
			}
		}
		char buffer[128];
		//snprintf(buffer,127,"test x%d y%d  tw%d  th%d w%d h%d px%d py%d",x,y,tw,th,width,height,winposx,winposy);
		//lines.push_back(buffer);
		get_vim_caret_pos(x,y,x,y,tw,th,width,height);
		return preview_window(lines,base,x,y,width,height);
	}


	char* preview_window(vector<string> &v,const string& base,int x,int y,int width,int height)
	{
		user_input ="";// g_string_new("");
		gtk_init(0,NULL);


		init_window(x,y,width,height);

		gtk_main ();
		snprintf(pre_select_buffer,255,"%s",user_input.c_str());
		return pre_select_buffer;
	}

	void init_window(int x,int y,int width,int height)
	{
		window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
		gtk_window_set_decorated((GtkWindow*)window,FALSE);
		gtk_window_set_modal((GtkWindow*)window,TRUE);
		gtk_window_move((GtkWindow*)window,x,y);
		gtk_window_resize((GtkWindow*)window,width,height);
		gtk_window_set_title(GTK_WINDOW(window),"preview");


		list_store = gtk_list_store_new(3,G_TYPE_STRING,G_TYPE_STRING,G_TYPE_STRING);
		init_list_store();

		line_list = gtk_tree_view_new_with_model((GtkTreeModel*)list_store);

		GtkTreeViewColumn *column;
		GtkCellRenderer   *renderer = gtk_cell_renderer_text_new ();
		g_object_set(G_OBJECT(renderer),"cell-background","yellow",NULL);
 
		column = gtk_tree_view_column_new_with_attributes ("Title",
                                                      renderer,
						      "text",0,
                                                      NULL);
		gtk_tree_view_append_column((GtkTreeView*)line_list,column);
		column = gtk_tree_view_column_new_with_attributes ("Title2",
                                                      renderer,
						      "text",1,
                                                      NULL);
		gtk_tree_view_append_column((GtkTreeView*)line_list,column);
		column = gtk_tree_view_column_new_with_attributes ("Title3",
                                                      renderer,
						      "text",2,
                                                      NULL);
		gtk_tree_view_append_column((GtkTreeView*)line_list,column);
		gtk_tree_view_set_headers_visible((GtkTreeView*)line_list,FALSE);
		gtk_tree_selection_set_mode( gtk_tree_view_get_selection(GTK_TREE_VIEW(line_list)),
				GTK_SELECTION_SINGLE);
		
		GtkWidget* vbox = gtk_vbox_new(FALSE,1);
		

		input_label = gtk_label_new(base.c_str());
		gtk_widget_set_size_request(input_label,width,13);

		scrolledwindow2 = gtk_scrolled_window_new (NULL, NULL);
		
		gtk_scrolled_window_set_shadow_type (GTK_SCROLLED_WINDOW (scrolledwindow2), GTK_SHADOW_IN);
		
		gtk_box_pack_start((GtkBox*) vbox,input_label, FALSE,FALSE,1);
		gtk_box_pack_start((GtkBox*) vbox,scrolledwindow2, TRUE,TRUE,1);

		gtk_container_add(GTK_CONTAINER(window),vbox);
		gtk_container_add (GTK_CONTAINER (scrolledwindow2), line_list);

		g_signal_connect (G_OBJECT (window), "key_release_event",
				G_CALLBACK (on_key_release_event), NULL);


		gtk_widget_show (scrolledwindow2);
		gtk_widget_show(input_label);
		gtk_widget_show(line_list);
		gtk_widget_show(vbox);
		gtk_widget_show (window);


		update_label();
	}

/* 另一个回调函数 */
void destroy( GtkWidget *widget,
              gpointer   data )
{
	if ( window) {
		gtk_widget_destroy(window);
	}
	gtk_main_quit ();
}

void on_key_release_event( GtkWidget *widget,
            GdkEventKey *data )
{
	key_release_count+=1;
	switch ( data->keyval) {
		case 32://SPACE
			if ( key_release_count<=1) 
				return;
			get_select_val();
			destroy(widget,data);
			return;
		case 65288://BACKSPACE
			if (user_input.length()>=1) {
				user_input.erase(user_input.length()-1,1);
				update_label();
			}
			return;
		case 65289://TAB
			get_select_val();
			destroy(widget,data);
			return;
		case 65293: //ENTER
			if ( key_release_count<=1) 
				return;
			get_select_val();
			destroy(widget,data);
			return;
		case 65307: //ESC
			user_input.clear();
			destroy(widget,data);
			return;
		case GDK_Shift_L:
		case GDK_Shift_R:
		case GDK_Control_L:
		case GDK_Control_R:
		case GDK_Caps_Lock:
		case GDK_Shift_Lock:
		case GDK_Meta_L:
		case GDK_Meta_R:
		case GDK_Alt_L:
		case GDK_Alt_R:
		case GDK_VoidSymbol:
			return;
	}
	if ( data->keyval > 0x20 && data->keyval<=0x7D) {
		user_input+= char(data->keyval);
		update_label();
		//gtk_widget_grab_focus(line_list);
	}
}
int main(int argc,char* argv[])
{
	printf("%s\n",preview(argv[1]));
	printf("meger test");
	printf("meger 杨琳");
	return 0;
}

#ifdef AS_C
}
#endif

// vim:ts=4:sw=4
