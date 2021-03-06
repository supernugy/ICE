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
module derelict.ogg.vorbisenc;

public
{
    import derelict.ogg.vorbistypes;
    import derelict.ogg.vorbisenctypes;
    import derelict.ogg.vorbisencfuncs;
}

private
{
    import derelict.util.loader;
}

class DerelictVorbisEncLoader : SharedLibLoader
{
public:
    this()
    {
        super(
            "vorbisenc.dll, libvorbisenc.dll",
            "libvorbisenc.so, libvorbisenc.so.0, libvorbisenc.so.0.3.0",
            ""
        );
    }

protected:
    override void loadSymbols()
    {
        bindFunc(cast(void**)&vorbis_encode_init, "vorbis_encode_init");
        bindFunc(cast(void**)&vorbis_encode_setup_managed, "vorbis_encode_setup_managed");
        bindFunc(cast(void**)&vorbis_encode_setup_vbr, "vorbis_encode_setup_vbr");
        bindFunc(cast(void**)&vorbis_encode_init_vbr, "vorbis_encode_init_vbr");
        bindFunc(cast(void**)&vorbis_encode_setup_init, "vorbis_encode_setup_init");
        bindFunc(cast(void**)&vorbis_encode_ctl, "vorbis_encode_ctl");
    }
}

DerelictVorbisEncLoader DerelictVorbisEnc;

static this()
{
    DerelictVorbisEnc = new DerelictVorbisEncLoader();
}

static ~this()
{
    if(SharedLibLoader.isAutoUnloadEnabled())
        DerelictVorbisEnc.unload();
}