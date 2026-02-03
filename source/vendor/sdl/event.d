module vendor.sdl.event;

import vendor.sdl.video;
import vendor.sdl.event;
import vendor.sdl.keyboard;
import vendor.sdl.scancode;
import vendor.sdl.keycode;
import vendor.sdl.mouse;

@nogc extern (C)
{
    alias SDL_EventType = int;
    enum
    {
        SDL_EVENT_FIRST = 0,
        SDL_EVENT_QUIT = 0x100,
        SDL_EVENT_TERMINATING,
        SDL_EVENT_LOW_MEMORY,
        SDL_EVENT_WILL_ENTER_BACKGROUND,
        SDL_EVENT_DID_ENTER_BACKGROUND,
        SDL_EVENT_WILL_ENTER_FOREGROUND,
        SDL_EVENT_DID_ENTER_FOREGROUND,
        SDL_EVENT_LOCALE_CHANGED,
        SDL_EVENT_SYSTEM_THEME_CHANGED,
        SDL_EVENT_DISPLAY_ORIENTATION = 0x151,
        SDL_EVENT_DISPLAY_ADDED,
        SDL_EVENT_DISPLAY_REMOVED,
        SDL_EVENT_DISPLAY_MOVED,
        SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED,
        SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED,
        SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED,
        SDL_EVENT_DISPLAY_FIRST = SDL_EVENT_DISPLAY_ORIENTATION,
        SDL_EVENT_DISPLAY_LAST = SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED,
        SDL_EVENT_WINDOW_SHOWN = 0x202,
        SDL_EVENT_WINDOW_HIDDEN,
        SDL_EVENT_WINDOW_EXPOSED,
        SDL_EVENT_WINDOW_MOVED,
        SDL_EVENT_WINDOW_RESIZED,
        SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
        SDL_EVENT_WINDOW_METAL_VIEW_RESIZED,
        SDL_EVENT_WINDOW_MINIMIZED,
        SDL_EVENT_WINDOW_MAXIMIZED,
        SDL_EVENT_WINDOW_RESTORED,
        SDL_EVENT_WINDOW_MOUSE_ENTER,
        SDL_EVENT_WINDOW_MOUSE_LEAVE,
        SDL_EVENT_WINDOW_FOCUS_GAINED,
        SDL_EVENT_WINDOW_FOCUS_LOST,
        SDL_EVENT_WINDOW_CLOSE_REQUESTED,
        SDL_EVENT_WINDOW_HIT_TEST,
        SDL_EVENT_WINDOW_ICCPROF_CHANGED,
        SDL_EVENT_WINDOW_DISPLAY_CHANGED,
        SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED,
        SDL_EVENT_WINDOW_SAFE_AREA_CHANGED,
        SDL_EVENT_WINDOW_OCCLUDED,
        SDL_EVENT_WINDOW_ENTER_FULLSCREEN,
        SDL_EVENT_WINDOW_LEAVE_FULLSCREEN,
        SDL_EVENT_WINDOW_DESTROYED,
        SDL_EVENT_WINDOW_HDR_STATE_CHANGED,
        SDL_EVENT_WINDOW_FIRST = SDL_EVENT_WINDOW_SHOWN,
        SDL_EVENT_WINDOW_LAST = SDL_EVENT_WINDOW_HDR_STATE_CHANGED,
        SDL_EVENT_KEY_DOWN = 0x300,
        SDL_EVENT_KEY_UP,
        SDL_EVENT_TEXT_EDITING,
        SDL_EVENT_TEXT_INPUT,
        SDL_EVENT_KEYMAP_CHANGED,
        SDL_EVENT_KEYBOARD_ADDED,
        SDL_EVENT_KEYBOARD_REMOVED,
        SDL_EVENT_TEXT_EDITING_CANDIDATES,
        SDL_EVENT_MOUSE_MOTION = 0x400,
        SDL_EVENT_MOUSE_BUTTON_DOWN,
        SDL_EVENT_MOUSE_BUTTON_UP,
        SDL_EVENT_MOUSE_WHEEL,
        SDL_EVENT_MOUSE_ADDED,
        SDL_EVENT_MOUSE_REMOVED,
        SDL_EVENT_JOYSTICK_AXIS_MOTION = 0x600,
        SDL_EVENT_JOYSTICK_BALL_MOTION,
        SDL_EVENT_JOYSTICK_HAT_MOTION,
        SDL_EVENT_JOYSTICK_BUTTON_DOWN,
        SDL_EVENT_JOYSTICK_BUTTON_UP,
        SDL_EVENT_JOYSTICK_ADDED,
        SDL_EVENT_JOYSTICK_REMOVED,
        SDL_EVENT_JOYSTICK_BATTERY_UPDATED,
        SDL_EVENT_JOYSTICK_UPDATE_COMPLETE,
        SDL_EVENT_GAMEPAD_AXIS_MOTION = 0x650,
        SDL_EVENT_GAMEPAD_BUTTON_DOWN,
        SDL_EVENT_GAMEPAD_BUTTON_UP,
        SDL_EVENT_GAMEPAD_ADDED,
        SDL_EVENT_GAMEPAD_REMOVED,
        SDL_EVENT_GAMEPAD_REMAPPED,
        SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN,
        SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION,
        SDL_EVENT_GAMEPAD_TOUCHPAD_UP,
        SDL_EVENT_GAMEPAD_SENSOR_UPDATE,
        SDL_EVENT_GAMEPAD_UPDATE_COMPLETE,
        SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED,
        SDL_EVENT_FINGER_DOWN = 0x700,
        SDL_EVENT_FINGER_UP,
        SDL_EVENT_FINGER_MOTION,
        SDL_EVENT_FINGER_CANCELED,
        SDL_EVENT_CLIPBOARD_UPDATE = 0x900,
        SDL_EVENT_DROP_FILE = 0x1000,
        SDL_EVENT_DROP_TEXT,
        SDL_EVENT_DROP_BEGIN,
        SDL_EVENT_DROP_COMPLETE,
        SDL_EVENT_DROP_POSITION,
        SDL_EVENT_AUDIO_DEVICE_ADDED = 0x1100,
        SDL_EVENT_AUDIO_DEVICE_REMOVED,
        SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED,
        SDL_EVENT_SENSOR_UPDATE = 0x1200,
        SDL_EVENT_PEN_PROXIMITY_IN = 0x1300,
        SDL_EVENT_PEN_PROXIMITY_OUT,
        SDL_EVENT_PEN_DOWN,
        SDL_EVENT_PEN_UP,
        SDL_EVENT_PEN_BUTTON_DOWN,
        SDL_EVENT_PEN_BUTTON_UP,
        SDL_EVENT_PEN_MOTION,
        SDL_EVENT_PEN_AXIS,
        SDL_EVENT_CAMERA_DEVICE_ADDED = 0x1400,
        SDL_EVENT_CAMERA_DEVICE_REMOVED,
        SDL_EVENT_CAMERA_DEVICE_APPROVED,
        SDL_EVENT_CAMERA_DEVICE_DENIED,
        SDL_EVENT_RENDER_TARGETS_RESET = 0x2000,
        SDL_EVENT_RENDER_DEVICE_RESET,
        SDL_EVENT_RENDER_DEVICE_LOST,
        SDL_EVENT_PRIVATE0 = 0x4000,
        SDL_EVENT_PRIVATE1,
        SDL_EVENT_PRIVATE2,
        SDL_EVENT_PRIVATE3,
        SDL_EVENT_POLL_SENTINEL = 0x7F00,
        SDL_EVENT_USER = 0x8000,
        SDL_EVENT_LAST = 0xFFFF,
        SDL_EVENT_ENUM_PADDING = 0x7FFFFFFF
    }

    struct SDL_CommonEvent
    {
        uint type;
        uint reserved;
        ulong timestamp;
    }

    struct SDL_DisplayEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_DisplayID displayID;
        int data1;
        int data2;
    }

    struct SDL_WindowEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        int data1;
        int data2;
    }

    struct SDL_KeyboardDeviceEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_KeyboardID which;
    }

    struct SDL_KeyboardEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        SDL_KeyboardID which;
        SDL_Scancode scancode;
        SDL_Keycode key;
        SDL_Keymod mod;
        ushort raw;
        bool down;
        bool repeat;
    }

    struct SDL_TextEditingEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        const char* text;
        int start;
        int length;
    }

    struct SDL_TextEditingCandidatesEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        const(const(char)*)* candidates;
        int num_candidates;
        int selected_candidate;
        bool horizontal;
        ubyte padding1;
        ubyte padding2;
        ubyte padding3;
    }

    struct SDL_TextInputEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        const(char)* text;
    }

    struct SDL_MouseDeviceEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_MouseID which;
    }

    struct SDL_MouseMotionEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        SDL_MouseID which;
        SDL_MouseButtonFlags state;
        float x;
        float y;
        float xrel;
        float yrel;
    }

    struct SDL_MouseButtonEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        SDL_MouseID which;
        ubyte button;
        bool down;
        ubyte clicks;
        ubyte padding;
        float x;
        float y;
    }

    struct SDL_MouseWheelEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        SDL_MouseID which;
        float x;
        float y;
        SDL_MouseWheelDirection direction;
        float mouse_x;
        float mouse_y;
    }

    struct SDL_DropEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        float x;
        float y;
        const char* source;
        const char* data;
    }

    struct SDL_ClipboardEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
        bool owner;
        int num_mime_types;
        const(char*)* mime_types;
    }

    struct SDL_QuitEvent
    {
        SDL_EventType type;
        uint reserved;
        ulong timestamp;
    }

    struct SDL_UserEvent
    {
        uint type;
        uint reserved;
        ulong timestamp;
        SDL_WindowID windowID;
        int code;
        void* data1;
        void* data2;
    }

    union SDL_Event
    {
        uint type;
        SDL_CommonEvent common;
        SDL_DisplayEvent display;
        SDL_WindowEvent window;
        SDL_KeyboardDeviceEvent kdevice;
        SDL_KeyboardEvent key;
        SDL_TextEditingEvent edit;
        SDL_TextEditingCandidatesEvent edit_candidates;
        SDL_TextInputEvent text;
        SDL_MouseDeviceEvent mdevice;
        SDL_MouseMotionEvent motion;
        SDL_MouseButtonEvent button;
        SDL_MouseWheelEvent wheel;
        // SDL_JoyDeviceEvent jdevice;
        // SDL_JoyAxisEvent jaxis;
        // SDL_JoyBallEvent jball;
        // SDL_JoyHatEvent jhat;
        // SDL_JoyButtonEvent jbutton;
        // SDL_JoyBatteryEvent jbattery;
        // SDL_GamepadDeviceEvent gdevice;
        // SDL_GamepadAxisEvent gaxis;
        // SDL_GamepadButtonEvent gbutton;
        // SDL_GamepadTouchpadEvent gtouchpad;
        // SDL_GamepadSensorEvent gsensor;
        // SDL_AudioDeviceEvent adevice;
        // SDL_CameraDeviceEvent cdevice;
        // SDL_SensorEvent sensor;
        SDL_QuitEvent quit;
        SDL_UserEvent user;
        // SDL_TouchFingerEvent tfinger;
        // SDL_PenProximityEvent pproximity;
        // SDL_PenTouchEvent ptouch;
        // SDL_PenMotionEvent pmotion;
        // SDL_PenButtonEvent pbutton;
        // SDL_PenAxisEvent paxis;
        // SDL_RenderEvent render;
        SDL_DropEvent drop;
        SDL_ClipboardEvent clipboard;

        // For ABI compatibility between VC++ and GCC.
        ubyte[128] padding;
    }

    bool SDL_PollEvent(SDL_Event* event);
}
