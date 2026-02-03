module vendor.sdl.rect;

@nogc extern (C)
{
    struct SDL_Point
    {
        int x;
        int y;
    }

    struct SDL_FPoint
    {
        float x;
        float y;
    }

    struct SDL_Rect
    {
        int x, y;
        int w, h;
    }

    struct SDL_FRect
    {
        float x, y;
        float w, h;
    }
}
