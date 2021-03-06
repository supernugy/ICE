/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.allegro.font;

private
{
    import derelict.allegro.allegrotypes;

    import derelict.util.compat;
    import derelict.util.loader;
}

struct ALLEGRO_FONT
{
    void* data;
    int height;
    ALLEGRO_FONT_VTABLE* vtable;
}

struct ALLEGRO_FONT_VTABLE
{
    extern(C)
    {
        int function(in ALLEGRO_FONT*) font_height;
        int function(in ALLEGRO_FONT*) font_ascent;
        int function(in ALLEGRO_FONT*) font_descent;
        int function(in ALLEGRO_FONT*,int) char_length;
        int function(in ALLEGRO_FONT*,in ALLEGRO_USTR*) text_length;
        int function(in ALLEGRO_FONT*,ALLEGRO_COLOR,int,float,float) render_char;
        int function(in ALLEGRO_FONT*,ALLEGRO_COLOR,in ALLEGRO_USTR*,float,float) render;
        void function(ALLEGRO_FONT*) destroy;
        void function(in ALLEGRO_FONT*,in ALLEGRO_USTR*,int*,int*,int*,int*) get_text_dimensions;
    }
}

enum
{
    ALLEGRO_ALIGN_LEFT = 0,
    ALLEGRO_ALIGN_CENTRE = 1,
    ALLEGRO_ALIGN_RIGHT = 2
}

extern(C)
{
    alias bool function(in char*,ALLEGRO_FONT* function(in char*,int,int)) da_al_register_font_loader;
    alias ALLEGRO_FONT* function(in char*) da_al_load_bitmap_font;
    alias ALLEGRO_FONT* function(in char*,int size,int flags) da_al_load_font;
    alias ALLEGRO_FONT* function(ALLEGRO_BITMAP*,int,int*) da_al_grab_font_from_bitmap;
    alias void function(in ALLEGRO_FONT*,ALLEGRO_COLOR,float,float,int,in ALLEGRO_USTR) da_al_draw_ustr;
    alias void function(in ALLEGRO_FONT*,ALLEGRO_COLOR,float,float,int,in char*) da_al_draw_text;
    alias void function(in ALLEGRO_FONT*,ALLEGRO_COLOR,float,float,float,float,int,in char*) da_al_draw_justified_text;
    alias void function(in ALLEGRO_FONT*,ALLEGRO_COLOR,float,float,float,float,int,in ALLEGRO_USTR*) da_al_draw_justified_ustr;
    alias void function(in ALLEGRO_FONT*,ALLEGRO_COLOR,float,float,int,in char*,...) da_al_draw_textf;
    alias void function(in ALLEGRO_FONT*,ALLEGRO_COLOR,float,float,float,float,int,in char*) da_al_draw_justified_textf;
    alias int function(in ALLEGRO_FONT*,in char*) da_al_get_text_width;
    alias int function(in ALLEGRO_FONT*,in ALLEGRO_USTR*) da_al_get_ustr_width;
    alias int function(in ALLEGRO_FONT*) da_al_get_font_line_height;
    alias int function(in ALLEGRO_FONT*) da_al_get_font_ascent;
    alias int function(in ALLEGRO_FONT*) da_al_get_font_descent;
    alias void function(ALLEGRO_FONT*) da_al_destroy_font;
    alias void function(in ALLEGRO_FONT*,in ALLEGRO_USTR*,int*,int*,int*,int*) da_al_get_ustr_dimensions;
    alias void function(in ALLEGRO_FONT*,in char*,int*,int*,int*,int*) da_al_get_text_dimensions;
    alias void function() da_al_init_font_addon;
    alias void function() da_al_shutdown_font_addon;
    alias uint function() da_al_get_allegro_font_version;
}

mixin(gsharedString!() ~
"
da_al_register_font_loader al_register_font_loader;
da_al_load_bitmap_font al_load_bitmap_font;
da_al_load_font al_load_font;
da_al_grab_font_from_bitmap al_grab_font_from_bitmap;
da_al_draw_ustr al_draw_ustr;
da_al_draw_text al_draw_text;
da_al_draw_justified_text al_draw_justified_text;
da_al_draw_justified_ustr al_draw_justified_ustr;
da_al_draw_textf al_draw_textf;
da_al_draw_justified_textf al_draw_justified_textf;
da_al_get_text_width al_get_text_width;
da_al_get_ustr_width al_get_ustr_width;
da_al_get_font_line_height al_get_font_line_height;
da_al_get_font_ascent al_get_font_ascent;
da_al_get_font_descent al_get_font_descent;
da_al_destroy_font al_destroy_font;
da_al_get_ustr_dimensions al_get_ustr_dimensions;
da_al_get_text_dimensions al_get_text_dimensions;
da_al_init_font_addon al_init_font_addon;
da_al_shutdown_font_addon al_shutdown_font_addon;
da_al_get_allegro_font_version al_get_allegro_font_version;
");

class DerelictAllegroFontLoader : SharedLibLoader
{
public:
    this()
    {
        super(
        // Windows
        "allegro_font-5.0.5-mt.dll,allegro_font-5.0.4-mt.dll,allegro_font-5.0.3-mt.dll,"
        "allegro_font-5.0.2-mt.dll,allegro_font-5.0.1-mt.dll,allegro_font-5.0.0-mt.dll",
        // Linux
        "liballegro_font-5.0.5.so,liballegro_font-5.0.so",
        // OSX
        "../Frameworks/AllegroFont-5.0.framework,/Library/Frameworks/AllegroFont-5.0.framwork,"
        "liballegro_font-5.0.5.dylib,liballegro_font-5.0.dylib"
        );
    }

protected:
    override void loadSymbols()
    {
        bindFunc(cast(void**)&al_register_font_loader, "al_register_font_loader");
        bindFunc(cast(void**)&al_load_bitmap_font, "al_load_bitmap_font");
        bindFunc(cast(void**)&al_load_font, "al_load_font");
        bindFunc(cast(void**)&al_grab_font_from_bitmap, "al_grab_font_from_bitmap");
        bindFunc(cast(void**)&al_draw_ustr, "al_draw_ustr");
        bindFunc(cast(void**)&al_draw_text, "al_draw_text");
        bindFunc(cast(void**)&al_draw_justified_text, "al_draw_justified_text");
        bindFunc(cast(void**)&al_draw_justified_ustr, "al_draw_justified_ustr");
        bindFunc(cast(void**)&al_draw_textf, "al_draw_textf");
        bindFunc(cast(void**)&al_draw_justified_textf, "al_draw_justified_textf");
        bindFunc(cast(void**)&al_get_text_width, "al_get_text_width");
        bindFunc(cast(void**)&al_get_ustr_width, "al_get_ustr_width");
        bindFunc(cast(void**)&al_get_font_line_height, "al_get_font_line_height");
        bindFunc(cast(void**)&al_get_font_ascent, "al_get_font_ascent");
        bindFunc(cast(void**)&al_get_font_descent, "al_get_font_descent");
        bindFunc(cast(void**)&al_destroy_font, "al_destroy_font");
        bindFunc(cast(void**)&al_get_ustr_dimensions, "al_get_ustr_dimensions");
        bindFunc(cast(void**)&al_get_text_dimensions, "al_get_text_dimensions");
        bindFunc(cast(void**)&al_init_font_addon, "al_init_font_addon");
        bindFunc(cast(void**)&al_shutdown_font_addon, "al_shutdown_font_addon");
        bindFunc(cast(void**)&al_get_allegro_font_version, "al_get_allegro_font_version");
    }
}

DerelictAllegroFontLoader DerelictAllegroFont;

static this()
{
    DerelictAllegroFont = new DerelictAllegroFontLoader();
}

static ~this()
{
    if(SharedLibLoader.isAutoUnloadEnabled())
        DerelictAllegroFont.unload();
}