module video.shader;


import std.string;
import std.file;
import std.stdio;

import derelict.opengl.gl;

import file;

package struct GLShader
{
    invariant
    {
        assert(program != 0, "Shader program is null");
    }

    private:
		//GLSL linked shader program
        GLuint program = 0;

        //Initialize specified shader 
        void init(string name)
        {
            load_GLSL("data/shaders/" ~ name ~ ".vert", 
                      "data/shaders/" ~ name ~ ".frag");
        }

    public:
        //Fake constructor
        static GLShader opCall(string name)
        {
            GLShader shader;
            shader.init(name);
            return shader;
        }

        void start()
        {
            glUseProgram(program);
        }

        void die()
        {
            glDeleteProgram(program);
        }
        
    private:
        //Load a GLSL shader
        void load_GLSL(string vfname, string ffname)
        {
            char* vsrc;
            char* fsrc;
            try
            {
                //loading shader code
                string vstring = load_text_file(vfname);
                string fstring = load_text_file(ffname);
                vsrc = toStringz(vstring);
                fsrc = toStringz(fstring);
            }
            catch(FileException e)
            {
                throw new Exception("Couldn't load shader " ~ vfname ~
                                    " and/or " ~ ffname);
            }                                 
            
			//creating OpenGL objects for shaders
            GLuint vshader = glCreateShader(GL_VERTEX_SHADER);
            GLuint fshader = glCreateShader(GL_FRAGMENT_SHADER);

			//passing shader code to OpenGL
			glShaderSource(vshader, 1, &vsrc, null);
			glShaderSource(fshader, 1, &fsrc, null);

			//compiling shaders
			int compiled;
			glCompileShader(vshader);
			glGetShaderiv(vshader, GL_COMPILE_STATUS, &compiled);
			if(!compiled)
			{
				throw new Exception("Couldn't compile vertex shader " ~ vfname);
			}
			glCompileShader(fshader);
            glGetShaderiv(fshader, GL_COMPILE_STATUS, &compiled);
			if(!compiled)
			{
				throw new Exception("Couldn't compile fragment shader " ~ ffname);
			}

            program = glCreateProgram();

			//passing shaders to the program
			glAttachShader(program, vshader);
			glAttachShader(program, fshader);

			//linking shaders
			int linked;
			glLinkProgram(program);
			glGetProgramiv(program, GL_LINK_STATUS, &linked);
			if(!linked)
			{
                glDeleteProgram(program);
				throw new Exception("Couldn't link shaders " ~ vfname ~ " and "
                                     ~ ffname);
			}
        }
}
