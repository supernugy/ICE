module video.glvideodriver;


import std.string;

import derelict.opengl.gl;
import derelict.util.exception;

import video.videodriver;
import video.glshader;
import video.gltexture;
import video.gltexturepage;
import video.shader;
import video.texture;
import video.font;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import platform.platform;
import color;
import image;
import allocator;



///Handles all drawing functionality.
abstract class GLVideoDriver : VideoDriver
{
    invariant{assert(ViewZoom > 0.0);}

    protected:
        uint ScreenWidth = 0;
        uint ScreenHeight = 0;

    private:
        GLVersion Version;

        real ViewZoom = 0.0;
        Vector2d ViewOffset = Vector2d(0.0, 0.0);

        //Is line antialiasing enabled?
        bool LineAA = false;

        Shader LineShader;
        Shader TextureShader;
        Shader FontShader;

        uint CurrentShader = uint.max;

        GLShader*[] Shaders;




        float LineWidth = 1.0;

        //Texture pages
        TexturePage*[] Pages;
        //Index of currently used page; uint.max means none.
        uint CurrentPage = uint.max;

        //Textures
        GLTexture*[] Textures;

    public:
        this()
        {
            singleton_ctor();
            DerelictGL.load();
            ViewZoom = 1.0;
        }

        override void die()
        {
            delete_shader(LineShader);
            delete_shader(TextureShader);
            delete_shader(FontShader);

            FontManager.get.die();

            //delete any remaining texture pages
            foreach(ref page; Pages)
            {
                if(page !is null)
                {
                    page.die();
                    free(page);
                    page = null;
                }
            }

            //delete any remaining textures
            foreach(ref texture; Textures)
            {
                if(texture !is null)
                {
                    free(texture);
                    texture = null;
                }
            }

            //delete any remaining shaders
            foreach(ref shader; Shaders)
            {
                if(shader !is null)
                {
                    free(shader);
                    shader = null;
                }
            }

            Pages = [];
            Textures = [];
            Shaders = [];
            DerelictGL.unload();
        }

        override void set_video_mode(uint width, uint height, 
                                     ColorFormat format, bool fullscreen);

        override void start_frame()
        {
            glClear(GL_COLOR_BUFFER_BIT);
            setup_viewport();
            CurrentPage = uint.max;
        }

        override void end_frame(){glFlush();}

        final override void draw_line(Vector2f v1, Vector2f v2, Color c1, Color c2)
        {
            set_shader(LineShader);
            //The line is drawn as a rectangle with width slightly lower than
            //LineWidth to prevent artifacts.
            Vector2f offset_base = (v2 - v1).normal.normalized;
            float half_width = LineWidth / 2.0;
            Vector2f offset = offset_base * (half_width);
            Vector2f r1, r2, r3, r4;
            r1 = v1 + offset;
            r2 = v1 - offset;
            r3 = v2 + offset;
            r4 = v2 - offset;

            if(LineAA)
            {
                //If AA is on, add two transparent vertices to the sides of the 
                //rectangle.
                Vector2f offset_aa = offset_base * (half_width + 0.4);
                Vector2f aa1, aa2, aa3, aa4;
                aa1 = v1 + offset_aa;
                aa2 = v1 - offset_aa;
                aa3 = v2 + offset_aa;
                aa4 = v2 - offset_aa;

                glBegin(GL_TRIANGLE_STRIP);
                glColor4ub(c1.r, c1.g, c1.b, 0);
                glVertex2f(aa1.x, aa1.y);
                glColor4ub(c2.r, c2.g, c2.b, 0);
                glVertex2f(aa3.x, aa3.y);

                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r1.x, r1.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r3.x, r3.y);
                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r2.x, r2.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r4.x, r4.y);

                glColor4ub(c1.r, c1.g, c1.b, 0);
                glVertex2f(aa2.x, aa2.y);
                glColor4ub(c2.r, c2.g, c2.b, 0);
                glVertex2f(aa4.x, aa4.y);
                glEnd();
            }
            else
            {
                glBegin(GL_TRIANGLE_STRIP);
                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r1.x, r1.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r3.x, r3.y);
                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r2.x, r2.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r4.x, r4.y);
                glEnd();
            }
        }

        final override void draw_texture(Vector2i position, ref Texture texture)
        in{assert(texture.index < Textures.length);}
        body
        {
            set_shader(TextureShader);

            GLTexture* gl_texture = Textures[texture.index];
            assert(gl_texture !is null, "Trying to draw a nonexistent texture");
            uint page_index = gl_texture.page_index;
            assert(Pages[page_index] !is null, "Trying to draw a texture from"
                                               " a nonexistent page");
            if(CurrentPage != page_index)
            {
                Pages[page_index].start();
                CurrentPage = page_index;
            }

            Vector2f vmin = to!(float)(position);
            Vector2f vmax = vmin + to!(float)(texture.size);

            Vector2f tmin = gl_texture.texcoords.min;
            Vector2f tmax = gl_texture.texcoords.max;

            glColor4ub(255, 255, 255, 255);
            glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2f(tmin.x, tmin.y);
            glVertex2f(vmin.x, vmin.y);
            glTexCoord2f(tmin.x, tmax.y);
            glVertex2f(vmin.x, vmax.y);
            glTexCoord2f(tmax.x, tmin.y);
            glVertex2f(vmax.x, vmin.y);
            glTexCoord2f(tmax.x, tmax.y);
            glVertex2f(vmax.x, vmax.y);
            glEnd();
        }
        
        final override void draw_text(Vector2i position, string text, Color color)
        {
            //font textures are grayscale and use a shader
            //to convert grayscale to alpha
            set_shader(FontShader);

            FontRenderer renderer = FontManager.get.renderer();
            renderer.start();

            //offset of the current character relative to position
            Vector2u offset;

            Texture* texture;
            GLTexture* gl_texture;
            uint page_index;

            //vertices and texcoords for current character
            Vector2f vmin;
            Vector2f vmax;
            Vector2f tmin;
            Vector2f tmax;

            //make up for the fact that fonts are drawn from lower left corner
            //instead of upper left
            position.y += renderer.height;

            glColor4ub(color.r, color.g, color.b, color.a);

            //iterating over utf-32 chars (conversion is automatic)
            foreach(dchar c; text)
            {
                texture = renderer.glyph(c, offset);
                gl_texture = Textures[texture.index];
                page_index = gl_texture.page_index;

                //change texture page if needed
                if(CurrentPage != page_index)
                {
                    Pages[page_index].start();
                    CurrentPage = page_index;
                }

                //generate vertices, texcoords
                vmin.x = position.x + offset.x;
                vmin.y = position.y + offset.y;
                vmax.x = vmin.x + texture.size.x;
                vmax.y = vmin.y + texture.size.y;
                tmin = gl_texture.texcoords.min;
                tmax = gl_texture.texcoords.max;

                //draw the character
                glBegin(GL_TRIANGLE_STRIP);
                glTexCoord2f(tmin.x, tmin.y);
                glVertex2f(vmin.x, vmin.y);
                glTexCoord2f(tmin.x, tmax.y);
                glVertex2f(vmin.x, vmax.y);
                glTexCoord2f(tmax.x, tmin.y);
                glVertex2f(vmax.x, vmin.y);
                glTexCoord2f(tmax.x, tmax.y);
                glVertex2f(vmax.x, vmax.y);
                glEnd();
            }
        }
        
        final override Vector2u text_size(string text)
        {
            return FontManager.get.text_size(text);
        }

        final override void line_aa(bool aa){LineAA = aa;}
        
        final override void line_width(float width){LineWidth = width;}

        final override void font(string font_name){FontManager.get.font = font_name;}

        final override void font_size(uint size){FontManager.get.font_size = size;}
        
        final override void zoom(real zoom)
        in
        {
            assert(zoom > 0.0001, "Can't zoom out further than 0.0001x");
            assert(zoom < 100.0, "Can't zoom in further than 100x");
        }
        body
        {
            ViewZoom = zoom;
            setup_ortho();
        }
        
        final override real zoom(){return ViewZoom;}

        final override void view_offset(Vector2d offset)
        {
            ViewOffset = offset;
            setup_ortho();
        }

        final override Vector2d view_offset(){return ViewOffset;}

        final override uint screen_width(){return ScreenWidth;}

        final override uint screen_height(){return ScreenHeight;}

        final override uint max_texture_size(ColorFormat format)
        {
            GLenum gl_format, type;
            GLint internal_format;
            gl_color_format(format, gl_format, type, internal_format);

            uint size = 0;

            //try powers of two up to the maximum that works
            for(uint index; index < powers_of_two.length; ++index)
            {
                size = powers_of_two[index];
                glTexImage2D(GL_PROXY_TEXTURE_2D, 0, internal_format,
                             size, size, 0, gl_format, type, null);
                GLint width = size;
                GLint height = size;
                glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0,
                                         GL_TEXTURE_WIDTH, &width);
                glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0,
                                         GL_TEXTURE_HEIGHT, &height);

                if(width == 0 || height == 0){return powers_of_two[index - 1];}
            }
            return size;
        }

        final override string pages_info()
        {
            string info = "Pages: " ~ std.string.toString(Pages.length) ~ "\n"; 
            foreach(index, page; Pages)
            {
                info ~= std.string.toString(index) ~ ": \n";

                if(page is null){info ~= "null\n";}
                else{info ~= page.info ~ "\n";}
            }
            return info;
        }

		final override Texture create_texture(ref Image image, bool force_page)
        in
        {
            if(force_page)
            {
                assert(is_pot(image.size.x) && is_pot(image.size.y),
                       "When forcing a single texture to have its"
                       "own page, power of two texture is required");
            }
        }
        body
		{
            Rectanglef texcoords;
            //offset of the texture on the page
            Vector2u offset;

            //create new GLTexture with specified parameters.
            void new_texture(uint page_index)
            {
                GLTexture* texture = alloc!(GLTexture)();
                texture.texcoords = texcoords;
                texture.offset = offset;
                texture.page_index = page_index;
                Textures ~= texture;
            }

            //if the texture needs its own page
            if(force_page)
            {
                create_page(image.size, image.format, force_page);
                Pages[$ - 1].insert_texture(image, texcoords, offset);
                new_texture(Pages.length - 1);
                assert(Textures[$ - 1].texcoords == 
                       Rectanglef(0.0, 0.0, 1.0, 1.0), 
                       "Texture coordinates of a single page texture must "
                       "span the whole texture");
                return Texture(image.size, Textures.length - 1);
            }

            //try to find a page to fit the new texture to
            foreach(index, ref page; Pages)
            {
                if(page !is null && 
                   page.insert_texture(image, texcoords, offset))
                {
                    new_texture(index);
                    return Texture(image.size, Textures.length - 1);
                }
            }
            //if we're here, no page has space for our texture, so create
            //a new page. This will throw if we can't create a page large 
            //enough for the image.
            create_page(image.size, image.format);
            return create_texture(image, false);
		}

        final override void delete_texture(Texture texture)
        {
            GLTexture* gl_texture = Textures[texture.index];
            assert(gl_texture !is null, "Trying to delete a nonexistent texture");
            uint page_index = gl_texture.page_index;
            assert(Pages[page_index] !is null, "Trying to delete a texture from"
                                               " a nonexistent page");
            Pages[page_index].remove_texture(Rectangleu(gl_texture.offset,
                                                        gl_texture.offset + 
                                                        texture.size));
            free(Textures[texture.index]);
            Textures[texture.index] = null;

            //If we have null textures at the end of the Textures array, we
            //can remove them without messing up indices
            while(Textures.length > 0 && Textures[$ - 1] is null)
            {
                Textures = Textures[0 .. $ - 1];
            }
            if(Pages[page_index].empty())
            {
                Pages[page_index].die();
                free(Pages[page_index]);
                Pages[page_index] = null;

                //If we have null pages at the end of the Pages array, we
                //can remove them without messing up indices
                while(Pages.length > 0 && Pages[$ - 1] is null)
                {
                    Pages = Pages[0 .. $ - 1];
                }
            }
        }

    protected:
        //Initialize OpenGL context.
        final void init_gl()
        {
            //Force font manager to load if not yet loaded. 
            //Placed here because font manager ctor needs working videodriver
            //and a call to font manager ctor from videodriver ctor would
            //result in infinite recursion.
            FontManager.initialize!(FontManager);
            try
            {
                //Loads the newest available OpenGL version
                Version = DerelictGL.availableVersion();
                if(Version < GLVersion.Version20)
                {
                    throw new Exception("Could not load OpenGL 2.0 or greater."
                                        " Try updating graphics card driver.");
                }
            }
            catch(SharedLibProcLoadException e)
            {
                throw new Exception("Could not load OpenGL. Try updating graphics "
                                    "card driver.");
            } 

            glEnable(GL_CULL_FACE);
            glCullFace(GL_BACK);
			glEnable(GL_BLEND);
            glEnable(GL_TEXTURE_2D);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

            LineShader = create_shader("line");
            TextureShader = create_shader("texture");
            FontShader = create_shader("font");
        }

    private:
        //not ready for public interface yet- will take shader spec file in future
        //Load shader with specified name.
        final Shader create_shader(string name)
        {
            GLShader* gl_shader = alloc!(GLShader)();
            *gl_shader = GLShader(name);
            Shaders ~= gl_shader;
            return Shader(Shaders.length - 1);
        }

        //not ready for public interface yet
        //Delete a shader.
        final void delete_shader(Shader shader)
        {
            GLShader* gl_shader = Shaders[shader.index];
            assert(gl_shader !is null, "Trying to delete a nonexistent shader");
            free(Shaders[shader.index]);
            Shaders[shader.index] = null;

            //If we have null shaders at the end of the Shaders array, we
            //can remove them without messing up indices
            while(Shaders.length > 0 && Shaders[$ - 1] is null)
            {
                Shaders = Shaders[0 .. $ - 1];
            }
        }

        //not ready for public interface yet
        //Use specified shader for drawing.
        final void set_shader(Shader shader)
        {
            uint index = shader.index;

            if(CurrentShader != index)
            {
                Shaders[index].start;
                CurrentShader = index;
            }
        }

        ///Create a texture page with at least specified size, color format
        /**
         * Throws an exception if it's not possible to create a page with
         * required parameters.
         * @param size_image Size of image we need to fit on the page, i.e.
         *                   minimum size of the page
         * @param format     Color format of the page.
         * @param force_size Force page size to be exactly size_image.
         */
        final void create_page(Vector2u size_image, ColorFormat format, 
                               bool force_size = false)
        {
            //1/16 MiB grayscale, 1/4 MiB RGBA8
            static uint size_min = 256;
            uint supported = max_texture_size(format);
            if(size_min > supported)
            {
                throw new Exception("GL Video driver doesn't support minimum "
                                    "texture size for specified color format.");
            }

            size_image.x = pot_greater_equal(size_image.x);
            size_image.y = pot_greater_equal(size_image.y);
            if(size_image.x > supported || size_image.y > supported)
            {
                throw new Exception("GL Video driver doesn't support requested "
                                    "texture size for specified color format.");
            }
            //determining recommended maximum page size:
            //we want at least 1024 but will settle for less if not supported.
            //if supported / 4 > 1024, we take that.
            //1024*1024 is 1 MiB grayscale, 4MiB RGBA8
            uint max_recommended = min(max(1024u, supported / 4), supported);

            Vector2u size = Vector2u(size_min, size_min);

            void page_size(uint index)
            {
                index = min(powers_of_two.length - 1, index);
                //every page has double the page area of the previous one.
                //i.e. page 0 is 255, 255, page 1 is 512, 255, etc;
                //until we reach max_recommended, max_recommended.
                //We only create pages greater than that if size_image
                //is greater.
                size.x *= powers_of_two[index / 2 + index % 2];
                size.y *= powers_of_two[index / 2];
                size.x = max(min(size.x, max_recommended), size_image.x);
                size.y = max(min(size.y, max_recommended), size_image.y);

                if(force_size){size = size_image;}
            }
            
            //Look for page indices with null pages to insert page there if possible
            foreach(index, ref page; Pages)
            {
                if(page is null)
                {
                    page_size(index);
                    page = alloc!(TexturePage)();
                    *page = TexturePage(size, format);
                    return;
                }
            }
            page_size(Pages.length);
            Pages ~= alloc!(TexturePage)();
            *Pages[$ - 1] = TexturePage(size, format);
        }

        //Set up OpenGL viewport.
        final void setup_viewport()
        {
            glViewport(0, 0, ScreenWidth, ScreenHeight);
            setup_ortho();
        }

        //Set up orthographic projection.
        final void setup_ortho()
        {
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glOrtho(0.0f, ScreenWidth / ViewZoom, ScreenHeight / ViewZoom, 
                    0.0f, -1.0f, 1.0f);
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            glTranslatef(-ViewOffset.x, -ViewOffset.y, 0.0f);
        }
}
