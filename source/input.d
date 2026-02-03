module input;

import std.conv;
import std.traits;
import vector;
import vendor.sdl;

struct InputState
{
    bool curr;
    bool prev;

    const static int start = 25;
    const static int repeat = 6;
    int current = 0;

    void update(bool is_held_down)
    {
        prev = curr;
        curr = is_held_down;

        if (curr)
        {
            current--;
            if (current < 0)
            {
                current = repeat;
            }
        }
        else
        {
            current = start;
        }
    }

    bool down() const => curr;
    bool press() const => curr && !prev;
    bool release() const => !curr && prev;
    bool down_repeat() const => press() || current == 0;
}

struct Input
{
    InputState[SDL_SCANCODE_COUNT] key;

    vec2 mouse_pos;
    vec2 mouse_pos_prev;
    vec2 mouse_spd() => mouse_pos - mouse_pos_prev;

    int mouse_btn_curr;
    int mouse_btn_prev;
    float wheel; // Updated while processing SDL events

    string to_str(SDL_Scancode scancode) const
    {
        return to!string(SDL_GetScancodeName(scancode));
    }

    void update()
    {
        const bool* state = SDL_GetKeyboardState(null);
        for (int i = 0; i < SDL_SCANCODE_COUNT; i++)
        {
            key[i].update(state[i]);
        }

        mouse_pos_prev = mouse_pos;
        mouse_btn_prev = mouse_btn_curr;
        SDL_MouseButtonFlags mouse_flags = SDL_GetMouseState(&mouse_pos.x, &mouse_pos.y);
        mouse_pos = (mouse_pos / 1.0).floor;
        mouse_btn_curr = cast(int) mouse_flags;
    }

    bool mb_down(int sdl_button_mask) const
    {
        return ((mouse_btn_curr & sdl_button_mask) != 0);
    }

    bool mb_press(int sdl_button_mask) const
    {
        return ((mouse_btn_curr & sdl_button_mask) != 0) && (
            (mouse_btn_prev & sdl_button_mask) == 0);
    }

    bool mb_release(int sdl_button_mask) const
    {
        return ((mouse_btn_curr & sdl_button_mask) == 0) && (
            (mouse_btn_prev & sdl_button_mask) != 0);
    }

    bool key_down(SDL_Scancode scancode) const => key[scancode].down();
    bool key_press(SDL_Scancode scancode) const => key[scancode].press();
    bool key_release(SDL_Scancode scancode) const => key[scancode].release();
    bool key_down_repeat(SDL_Scancode scancode) const => key[scancode].down_repeat();

    int key_axis_down(SDL_Scancode minor, SDL_Scancode major) const
    {
        return key_down(major) - key_down(minor);
    }

    int key_axis_press(SDL_Scancode minor, SDL_Scancode major) const
    {
        return key_press(major) - key_press(minor);
    }

    int key_axis_release(SDL_Scancode minor, SDL_Scancode major) const
    {
        return key_release(major) - key_release(minor);
    }

    int key_axis_down_repeat(SDL_Scancode minor, SDL_Scancode major) const
    {
        return key_down_repeat(major) - key_down_repeat(minor);
    }
}
