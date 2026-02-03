module vector;

import std.format;
import std.math;

struct vec2
{
    float x = 0;
    float y = 0;

    this(float x, float y)
    {
        this.x = x;
        this.y = y;
    }

    this(const vec2 v)
    {
        x = v.x;
        y = v.y;
    }

    vec2 perform(real function(real) func) const
    {
        return vec2(func(x), func(y));
    }

    vec2 round() const => perform(&std.math.round);
    vec2 floor() const => perform(&std.math.floor);
    vec2 ceil() const => perform(&std.math.ceil);
    vec2 abs() const => perform((real f) pure nothrow @nogc @safe => std.math.abs(f));
    vec2 sign() const => perform((real f) => std.math.signbit(f) * 2 - 1);

    vec2 opBinary(string op)(vec2 rhs) const
    {
        static if (op == "+")
            return opAdd(rhs);
        else static if (op == "-")
            return odSubtract(rhs);
        else static if (op == "*")
            return opTimes(rhs);
        else static if (op == "/")
            return opDiv(rhs);
        else
            static assert(0, "Operator " ~ op ~ " not implemented");
    }

    vec2 opAdd(vec2 rhs) const => vec2(x + rhs.x, y + rhs.y);
    vec2 odSubtract(vec2 rhs) const => vec2(x - rhs.x, y - rhs.y);
    vec2 opTimes(vec2 rhs) const => vec2(x * rhs.x, y * rhs.y);
    vec2 opDiv(vec2 rhs) const => vec2(x / rhs.x, y / rhs.y);
    vec2 opNeg() const => vec2(-x, -y);
    vec2 opTimesScalar(float rhs) const => vec2(x * rhs, y * rhs);
    vec2 opDivScalar(float rhs) const => vec2(x / rhs, y / rhs);

    vec2 opBinary(string op)(float rhs) const
    {
        vec2 o = vec2(rhs, rhs);
        return opBinary!(op)(o);
    }

    vec2 opOpAssign(string op)(vec2 o)
    {
        static if (op == "+")
        {
            this = this + o;
        }
        else static if (op == "-")
            return this = this - o;
        else
            static assert(0, "Operator " ~ op ~ " not implemented");

        return this;
    }

    vec2 opUnary(string op)() const if (op == "-")
    {
        return opNeg();
    }

    bool opEquals(const vec2 a) const @nogc @safe pure nothrow
    {
        return a.x == x && a.y == y;
    }

    size_t toHash() const @nogc @safe pure nothrow
    {
        return (cast(size_t)(x * 73_856_093) ^ cast(size_t)(y * 83_492_791));
    }

    vec2 normalized() const
    {
        float magn = magnitude();
        if (magn == 0)
            magn = 1;
        return vec2(x, y) / magn;
    }

    float magnitude() const
    {
        return sqrt(x * x + y * y);
    }

    vec2 rotated(float ang_degrees) const
    {
        float cs = cos(ang_degrees * PI / 180.0f);
        float sn = sin(ang_degrees * PI / 180.0f);
        return vec2(
            x * cs - y * sn,
            x * sn + y * cs
        );
    }

    vec2 rotated_around(vec2 point, float ang_degrees) const
    {
        vec2 offset = this - point;
        vec2 rotated_offset = offset.rotated(ang_degrees);
        return rotated_offset + point;
    }

    string toString() const
    {
        return format("vec2(%.2f, %.2f)", x, y);
    }
}
