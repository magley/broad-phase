module vendor.sdl.keyboard;

@nogc extern (C)
{
    alias SDL_KeyboardID = uint;

    const(bool*) SDL_GetKeyboardState(int* numkeys);
}
