module math.vector2d;

import std.traits: isFloatingPoint;
import std.algorithm.searching: canFind;
import std.math;

/** 
 * Templated 2D vector.
 */
struct Vector2D (T = float) if (isFloatingPoint!T)
{
    /// Returns the length (magnitude) of the vector.
    T length() const {
        return sqrt((x * x) + (y * y));
    }

    /** 
     * This function throws if the vector length is zero. 
     *
     * Returns: The result of the vector scaled to unit length.
     */
    Vector2D normalized() const {
        return this / length();
    }

    ref Vector2D opOpAssign(string op)(Vector2D rhs)
    if (op == "+") {
        x += rhs.x;
        y += rhs.y;
        return this; 
    }

    Vector2D opBinary(string op)(in T rhs) const
    if (["*", "/"].canFind(op)) {
        return Vector2D(mixin("x " ~ op ~ " rhs"),
                        mixin("y " ~ op ~ " rhs"));
    }

    T x = 0;
    T y = 0;
}

unittest
{
    import std.exception;

    auto vec = Vector2D!float(5, 5);

    assert(vec.x == 5);
    assert(vec.y == 5);

    vec += Vector2D!float(5, 5);

    assert(vec.x == 10);
    assert(vec.y == 10);

    float length = vec.length;
    float correctLength = sqrt(200.0);

    assert(length == correctLength);
    assert(vec.normalized.x == 10 / correctLength);
    assert(vec.normalized.y == 10 / correctLength);

    auto dividedVec = vec / 2.0;

    assert(dividedVec.x == 5.0);
    assert(dividedVec.y == 5.0);
}