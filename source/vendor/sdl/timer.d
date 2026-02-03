module vendor.sdl.timer;

@nogc extern (C)
{
    void SDL_Delay(uint ms);
    ulong SDL_GetTicks();
    ulong SDL_GetTicksNS();
}
