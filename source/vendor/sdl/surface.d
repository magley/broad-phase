module vendor.sdl.surface;

import vendor.sdl.pixels;

@nogc extern (C)
{
    alias SDL_SurfaceFlags = uint;
    enum
    {
        SDL_SURFACE_PREALLOCATED = 0x00000001u,
        SDL_SURFACE_LOCK_NEEDED = 0x00000002u,
        SDL_SURFACE_LOCKED = 0x00000004u,
        SDL_SURFACE_SIMD_ALIGNED = 0x00000008u,
    }

    alias SDL_ScaleMode = uint;
    enum
    {
        SDL_SCALEMODE_INVALID = -1,
        SDL_SCALEMODE_NEAREST,
        SDL_SCALEMODE_LINEAR,
        SDL_SCALEMODE_PIXELART,
    }

    alias SDL_FlipMode = uint;
    enum
    {
        SDL_FLIP_NONE,
        SDL_FLIP_HORIZONTAL,
        SDL_FLIP_VERTICAL
    }

    struct SDL_Surface
    {
        SDL_SurfaceFlags flags;
        SDL_PixelFormat format;
        int w;
        int h;
        int pitch;
        void* pixels;
        int refcount;
        void* reserved;
    }

    SDL_Surface* SDL_CreateSurface(int width, int height, SDL_PixelFormat format);
    SDL_Surface* SDL_CreateSurfaceFrom(int width, int height, SDL_PixelFormat format, void* pixels, int pitch);
    void SDL_DestroySurface(SDL_Surface* surface);
}
