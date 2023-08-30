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
    T length() const 
    {
        return sqrt((x * x) + (y * y));
    }

    unittest 
    {
        auto vec = Vector2D!float(5.0f, 10.0f);
        assert (vec.length == sqrt(125.0f));
    }

    /** 
     * This function throws if the vector length is zero. 
     *
     * Returns: The result of the vector scaled to unit length.
     */
    Vector2D normalized() const 
    {
        return this / length();
    }

    unittest 
    {
        auto vec = Vector2D!float(10, 10);
        float correctLength = sqrt(200.0);
        assert(vec.normalized.x == 10 / correctLength);
        assert(vec.normalized.y == 10 / correctLength);
    }

    /** 
     * Overload of += and -= operators with another Vector2D value.
     */
    ref Vector2D opOpAssign(string op)(Vector2D rhs)
            if (["+", "-"].canFind(op))
    {
        mixin ("x " ~ op ~ "= rhs.x;");
        mixin ("y " ~ op ~ "= rhs.y;");
        return this; 
    }

    unittest 
    {
        auto vec = Vector2D!float(5, 5);
        vec += Vector2D!float(5, 5);

        assert(vec.x == 10);
        assert(vec.y == 10);

        vec -= Vector2D!float(2, 2);
        assert (vec.x == 8);
        assert (vec.y == 8);
    }

    /** 
     * Overload of * and / operators with a scalar
     */
    Vector2D opBinary(string op)(in T rhs) const
            if (["*", "/"].canFind(op)) 
    {
        return Vector2D(mixin("x " ~ op ~ " rhs"),
                        mixin("y " ~ op ~ " rhs"));
    }

    unittest 
    {
        auto vec = Vector2D!float (10, 10);
        auto dividedVec = vec / 2;
        assert(dividedVec.x == 5.0);
        assert(dividedVec.y == 5.0);
    }

    /** 
     * Overload of + and - operators with another Vector2D value.
     */
    Vector2D opBinary(string op)(in Vector2D rhs) const 
            if (["+", "-"].canFind(op))
    {
        Vector2D result;
        result.x = mixin("x " ~ op ~ "rhs.x");
        result.y = mixin("y " ~ op ~ "rhs.y");
        return result;
    }

    unittest 
    {
        auto vec1 = Vector2D!float(3, 2);
        auto vec2 = Vector2D!float(3, 8);
        auto vec3 = vec1 + vec2;
        auto vec4 = vec3 - Vector2D!float(1, 1);

        assert (vec3 == Vector2D!float(6, 10));
        assert (vec4 == Vector2D!float(5, 9));
    }

    T x = 0;
    T y = 0;
}

alias Vec2f = Vector2D!float;