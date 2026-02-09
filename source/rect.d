module rect;

import std.algorithm;
import std.format;
import std.math;
import vector;

struct box2
{
    union
    {
        struct
        {
            union
            {
                float x = 0;
                float left;
            }

            union
            {
                float y = 0;
                float top;
            }

            float right = 0;
            float bottom = 0;
        }

        struct
        {
            vec2 ul;
            vec2 dr;
        }
    }

    vec2 center() const => (ul + dr) / 2;
    vec2 size() const => dr - ul + vec2(1, 1);
    float w() const => size().x;
    float h() const => size().y;
    float area() const => w * h;
    float perimiter() const => 2 * (w + h);

    vec2 dl() const => vec2(left, bottom);
    vec2 ur() const => vec2(right, top);

    static box2 uldr(vec2 ul, vec2 dr)
    {
        box2 b;
        b.ul = ul;
        b.dr = dr;
        return b;
    }

    static box2 pos_sz(vec2 pos, vec2 size)
    {
        box2 b;
        b.ul = pos;
        b.dr = pos + size - vec2(1, 1);
        return b;
    }

    box2 expanded(vec2 expansion) const
    {
        return box2.uldr(ul - expansion, dr + expansion);
    }

    box2 opBinary(string op)(vec2 rhs) const
    {
        static if (op == "+")
            return box2.uldr(ul + rhs, dr + rhs);
        else static if (op == "-")
            return box2.uldr(ul - rhs, dr - rhs);
        else
            static assert(0, "Operator " ~ op ~ " not implemented");
    }

    box2 floor() const
    {
        return box2.uldr(ul.floor, dr.floor);
    }

    bool contains(vec2 p) const
    {
        return (p.x >= left && p.x <= right && p.y >= top && p.y <= bottom);
    }

    bool contains_x(float px) const
    {
        return (px >= left && px <= right);
    }

    bool contains_y(float py) const
    {
        return (py >= top && py <= bottom);
    }

    bool intersect(box2 b) const
    {
        return (left < b.right && right > b.left && top < b.bottom && bottom > b.top);
    }

    bool intersect_x(box2 b) const
    {
        return (left < b.right && right > b.left);
    }

    bool intersect_y(box2 b) const
    {
        return (top < b.bottom && bottom > b.top);
    }

    bool intersect_inc(box2 b) const
    {
        return (left <= b.right && right >= b.left && top <= b.bottom && bottom >= b.top);
    }

    bool intersect_x_inc(box2 b) const
    {
        return (left <= b.right && right >= b.left);
    }

    bool intersect_y_inc(box2 b) const
    {
        return (top <= b.bottom && bottom >= b.top);
    }

    box2 with_top(float new_top) const
    {
        box2 res = this;
        float delta = new_top - res.top;
        res.ul.y += delta;
        res.dr.y += delta;
        return res;
    }

    box2 with_middle_y(float new_middle_y) const
    {
        box2 res = this;
        float delta = new_middle_y - res.center.y;
        res.ul.y += delta;
        res.dr.y += delta;
        return res;
    }

    box2 with_bottom(float new_bottom) const
    {
        box2 res = this;
        float delta = new_bottom - res.bottom;
        res.ul.y += delta;
        res.dr.y += delta;
        return res;
    }

    box2 with_left(float new_left) const
    {
        box2 res = this;
        float delta = new_left - res.left;
        res.ul.x += delta;
        res.dr.x += delta;
        return res;
    }

    box2 with_middle_x(float new_middle_x) const
    {
        box2 res = this;
        float delta = new_middle_x - res.center.x;
        res.ul.x += delta;
        res.dr.x += delta;
        return res;
    }

    box2 with_right(float new_right) const
    {
        box2 res = this;
        float delta = new_right - res.right;
        res.ul.x += delta;
        res.dr.x += delta;
        return res;
    }

    box2 shifted(vec2 amount) const
    {
        return box2.uldr(ul + amount, dr + amount);
    }

    box2 expand_to_contain(vec2 point) const
    {
        return box2.uldr(
            vec2(min(left, point.x), min(top, point.y)),
            vec2(max(right, point.x), max(bottom, point.y))
        );
    }

    box2 expand_to_contain(box2 rect) const
    {
        return box2.uldr(
            vec2(min(left, rect.left), min(top, rect.top)),
            vec2(max(right, rect.right), max(bottom, rect.bottom))
        );
    }

    string toString() const
    {
        return format("box2(pos=%s, size=%s)", ul.toString(), size().toString());
    }

    float dist_x(box2 rect) const
    {
        return min(abs(left - rect.right), abs(right - rect.left));
    }

    float dist_y(box2 rect) const
    {
        return min(abs(top - rect.bottom), abs(bottom - rect.top));
    }

    import vendor.sdl;

    SDL_FRect sdlrect() const
    {
        SDL_FRect res;
        res.x = x;
        res.y = y;
        res.w = w;
        res.h = h;
        return res;
    }
}
