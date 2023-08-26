module math.vector2d;

import std.math;

/** 
 * Templated 2D vector.
 */
struct Vector2D (T = float)
{
    static Vector2D!T ZERO() {
        return Vector2D!T(0, 0);
    }

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

    Vector2D opBinary(string op)(const T rhs) const 
    if (op == "/") {
        return Vector2D(x / rhs, y / rhs);
    }

    Vector2D opBinary(string op)(const T rhs) const
    if (op == "*") {
        return Vector2D(x * rhs, y * rhs);
    }

    T x;
    T y;
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