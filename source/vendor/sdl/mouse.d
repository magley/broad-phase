module vendor.sdl.mouse;

import vendor.sdl.video;

@nogc extern (C)
{
    alias SDL_MouseID = uint;

    struct SDL_Cursor
    {
        @disable this();
        @disable this(this);
    }

    alias SDL_SystemCursor = int;
    enum
    {
        SDL_SYSTEM_CURSOR_DEFAULT,
        SDL_SYSTEM_CURSOR_TEXT,
        SDL_SYSTEM_CURSOR_WAIT,
        SDL_SYSTEM_CURSOR_CROSSHAIR,
        SDL_SYSTEM_CURSOR_PROGRESS,
        SDL_SYSTEM_CURSOR_NWSE_RESIZE,
        SDL_SYSTEM_CURSOR_NESW_RESIZE,
        SDL_SYSTEM_CURSOR_EW_RESIZE,
        SDL_SYSTEM_CURSOR_NS_RESIZE,
        SDL_SYSTEM_CURSOR_MOVE,
        SDL_SYSTEM_CURSOR_NOT_ALLOWED,
        SDL_SYSTEM_CURSOR_POINTER,
        SDL_SYSTEM_CURSOR_NW_RESIZE,
        SDL_SYSTEM_CURSOR_N_RESIZE,
        SDL_SYSTEM_CURSOR_NE_RESIZE,
        SDL_SYSTEM_CURSOR_E_RESIZE,
        SDL_SYSTEM_CURSOR_SE_RESIZE,
        SDL_SYSTEM_CURSOR_S_RESIZE,
        SDL_SYSTEM_CURSOR_SW_RESIZE,
        SDL_SYSTEM_CURSOR_W_RESIZE,
        SDL_SYSTEM_CURSOR_COUNT,
    }

    alias SDL_MouseWheelDirection = int;
    enum
    {
        SDL_MOUSEWHEEL_NORMAL,
        SDL_MOUSEWHEEL_FLIPPED
    }

    alias SDL_MouseButtonFlags = uint;

    static SDL_MouseButtonFlags SDL_BUTTON_MASK(SDL_MouseButtonFlags X) => 1u << (X - 1);

    enum
    {
        SDL_BUTTON_LEFT = 1,
        SDL_BUTTON_MIDDLE = 2,
        SDL_BUTTON_RIGHT = 3,
        SDL_BUTTON_X1 = 4,
        SDL_BUTTON_X2 = 5,
        SDL_BUTTON_LMASK = SDL_BUTTON_MASK(
            SDL_BUTTON_LEFT),
        SDL_BUTTON_MMASK = SDL_BUTTON_MASK(SDL_BUTTON_MIDDLE),
        SDL_BUTTON_RMASK = SDL_BUTTON_MASK(SDL_BUTTON_RIGHT),
        SDL_BUTTON_X1MASK = SDL_BUTTON_MASK(
            SDL_BUTTON_X1),
        SDL_BUTTON_X2MASK = SDL_BUTTON_MASK(SDL_BUTTON_X2),
    }

    bool SDL_HasMouse();
    SDL_MouseID* SDL_GetMice(int* count);
    const(char)* SDL_GetMouseNameForID(SDL_MouseID instance_id);
    SDL_Window* SDL_GEtMouseFocus();
    SDL_MouseButtonFlags SDL_GetMouseState(float* x, float* y);
    SDL_MouseButtonFlags SDL_GetGlobalMouseState(float* x, float* y);
    SDL_MouseButtonFlags SDL_GetRelativeMouseState(float* x, float* y);
    void SDL_WarMouseInWindow(SDL_Window* window, float x, float y);
    void SDL_WarpMouseGlobal(SDL_Window* window, float x, float y);
    bool SDL_CaptureMouse(bool enabled);
    bool SDL_ShowCursor();
    bool SDL_HideCursor();
    bool SDL_CursorVisible();
}
