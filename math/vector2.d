
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module math.vector2;


import std.string;
import std.math;
import std.random;

import math.math;


///2D vector or point.
align(1) struct Vector2(T)
{
    //initialized to null vector by default
    ///X component of the vector.
    T x = 0;
    ///Y component of the vector.
    T y = 0;

    ///Negation.
    Vector2!(T) opNeg(){return Vector2!(T)(-x, -y);}

    ///Equality with a vector.
    bool opEquals(Vector2!(T) v){return equals(x, v.x) && equals(y, v.y);}

    ///Addition with a vector.
    Vector2!(T) opAdd(Vector2!(T) v){return Vector2!(T)(cast(T)(x + v.x), cast(T)(y + v.y));}

    ///Subtraction with a vector.
    Vector2!(T) opSub(Vector2!(T) v){return Vector2!(T)(cast(T)(x - v.x), cast(T)(y - v.y));}

    ///Multiplication with a scalar.
    Vector2!(T) opMul(T m){return Vector2!(T)(cast(T)(x * m), cast(T)(y * m));}

    ///Division by a scalar. 
    Vector2!(T) opDiv(T d)
    in{assert(d != 0, "Vector can not be divided by zero");}
    body{return Vector2!(T)(cast(T)(x / d), cast(T)(y / d));}

    ///Division by a vector. 
    Vector2!(T) opDiv(Vector2!(T) v)
    in{assert(v.x != 0 && v.y != 0, "Vector can not be divided by a vector with a zero component");}
    body{return Vector2!(T)(cast(T)(x / v.x), cast(T)(y / v.y));}

    ///Addition-assignment with a vector.
    void opAddAssign(Vector2!(T) v)
    {
        x += v.x;
        y += v.y;
    }

    ///Subtraction-assignment with a vector.
    void opSubAssign(Vector2!(T) v)
    {
        x -= v.x;
        y -= v.y;
    }

    ///Multiplication-assignment by a scalar.
    void opMulAssign(T m)
    {
        x *= m;
        y *= m;
    }

    ///Division-assignment by a scalar. 
    void opDivAssign(T d)
    in{assert(d != 0.0, "Vector can not be divided by zero");}
    body
    {
        x /= d;
        y /= d;
    }
    
    ///Get angle of this vector in radians.
    real angle()
    {
        real angle = atan2(cast(double)x, cast(double)y);
        if(angle < 0.0){return angle + 2 * PI;}
        return angle;
    }

    ///Set angle of this vector in radians, preserving its length.
    void angle(real angle)
    {
        T length = length();
        y = cast(T)cos(cast(double)angle);
        x = cast(T)sin(cast(double)angle);
        *this *= length;
    }

    ///Get squared length of the vector.
    T length_squared(){return x * x + y * y;}
    
    ///Get length of the vector fast at cost of some precision.
    T length()
    {
        version(sse3)
        {
            static if(typeid(T) is typeid(float))
            {
                Vector2!(T) vector = *this;
                asm
                {                             
                    //for some reason, movlps XMM0, [EAX]; segfaults.
                    //copy vector to lower half of xmm0
                    movlps XMM0, vector;
                    //square all floats in xmm0 
                    mulps XMM0, XMM0;        
                    //xmm0.x = x*x + y*y //aka squared length
                    //y,z,w don't matter
                    haddps XMM0, XMM0;
                    //square root of xmm0.x
                    sqrtss XMM0, XMM0;
                    //copy back to vector
                    movlps vector, XMM0;
                }
                return vector.x;
            }
            else{return length_safe();}
        }
        else{return length_safe();}
    }

    ///Get length of the vector with better precision.
    T length_safe(){return cast(T)(sqrt(cast(real)length_squared));}

    /**
     * Dot (scalar) product with another vector.
     *
     * Params:  v = Vector to get dot product with.
     *
     * Returns: Dot product of this and the other vector.
     */
    T dot_product(Vector2!(T) v){return x * v.x + y * v.y;}

    ///Get normal of this vector (a pependicular vector).
    Vector2!(T) normal(){return Vector2!(T)(-y, x);}

    /**
     * Turns this into a unit vector fast at cost of some precision. 
     *
     * Result is undefined if this is a zero vector.
     */
    void normalize()
    {
        version(sse3)
        {
            static if(typeid(T) is typeid(float))
            {
                asm
                {     
                    //this pointer is passed in EAX

                    //copy this vector to both low and high half of xmm0
                    //this instruction is supposed to take a double and
                    //duplicate it, but two floats works too
                    movddup XMM0, [EAX];
                    //copy vector to xmm2
                    movaps XMM2, XMM0;       
                    //square all floats in xmm0 
                    mulps XMM0, XMM0;        
                    //xmm0.x = xmm0.y = x*x + y*y //aka squared length
                    //z,w don't matter
                    haddps XMM0, XMM0;
                    //reciprocal square root to get reciprocal lengths
                    rsqrtps XMM0, XMM0 ;
                    //multiply x and y with that and we have a normalized 2D vector
                    mulps XMM2, XMM0;
                    //copy xmm2.x, xmm2y into this vector.
                    movlps [EAX], XMM2;
                }
                return;
            }
            else
            {
                T len = length();
                x /= len;
                y /= len;
                return;
            }
        }
        else
        {
            T len = length();
            x /= len;
            y /= len;
            return;
        }
    }

    ///Normalize with better precision, or don't do anything if this is a zero vector.
    void normalize_safe()
    {
        T len = length_safe();
        if(equals(length, cast(T)0)){return;}
        x /= len;
        y /= len;
        return;
    }

    ///Get unit vector of this vector. Result is undefined if this is a zero vector.
    Vector2!(T) normalized()
    {
        Vector2!(T) normalized = *this;
        normalized.normalize();
        return normalized;
    }

    ///Turn this vector into a zero vector.
    void zero(){x = y = cast(T)0;}
}

///Get a unit vector with a random direction.
Vector2!(T)random_direction(T)()
{
    long x_int = std.random.rand();
    long y_int = std.random.rand();
    T x = cast(T)(x_int % 2 ? x_int / 2 : -x_int / 2);
    T y = cast(T)(y_int % 2 ? y_int / 2 : -y_int / 2);
    return Vector2!(T)(x, y).normalized;
}

/**
 * Return a random position in a circle.
 *
 * Params:  center = Center of the circle.
 *          radius = Radius of the circle.
 *
 * Returns: Random position in the specified circle.
 */
Vector2!(T)random_position(T)(Vector2!(T) center, T radius)
{
    return center + random_direction!(T) * random(0, radius);
}

/**
 * Convert a Vector2 of one type to other. 
 *
 * Examples: 
 * --------------------
 * Vector2u v_uint = Vector2u(4, 2);
 * //convert to Vector2f
 * Vector2f V_float = to!(float)v_uint;
 * --------------------
 */                  
Vector2!(T)to(T, U)(Vector2!(U)v){return Vector2!(T)(cast(T)v.x, cast(T)v.y);}

///Vector2 of bytes.
alias Vector2!(byte) Vector2b;
///Vector2 of ubytes.
alias Vector2!(ubyte) Vector2ub;
///Vector2 of shorts.
alias Vector2!(short) Vector2s;
///Vector2 of ushorts.
alias Vector2!(ushort) Vector2us;
///Vector2 of ints.
alias Vector2!(int) Vector2i;
///Vector2 of uints.
alias Vector2!(uint) Vector2u;
///Vector2 of floats.
alias Vector2!(float) Vector2f;
///Vector2 of doubles.
alias Vector2!(double) Vector2d;
