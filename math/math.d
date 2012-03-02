
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Math functions.
module math.math;


import std.algorithm;
import std.math;
import std.traits;


///Get epsilon value for a numeric type.
template epsilon(T)
{
    static if(isFloatingPoint!T){const T epsilon = T.epsilon * 500;}
    else static if(isIntegral!T){const T epsilon = 0;}
    else{static assert(false, "Unsupported type for epsilon: " ~ typeid(T).toString);}
}

/**
 * Fuzzy number equality test.
 *
 * Params:  a         = First number to compare.
 *          b         = Secont number to compare.
 *          tolerance = Comparison tolerance.
 *
 * Returns: True if the numbers are equal, false otherwise.
 */
bool equals(T)(const T a, const T b, const T tolerance = epsilon!T) pure
    if(isNumeric!T)
{
    return (a + tolerance >= b) && (a - tolerance <= b); 
}
unittest
{
    assert(equals(7.0f / 5.0f, 1.4f));
    assert(!equals(7.0f / 5.0f, 1.4002f));
    assert(equals(7.0f, 5.0f, 2.0f));

    assert(equals(7.0 / 5.0, 1.4));
    assert(!equals(7.0 / 5.0, 1.40001));
    assert(equals(7.0, 5.0, 2.0));
}

/**
 * Clamps a value to specified range.
 *
 * Params:  v       = Value to clamp.
 *          minimum = Minimum of the range. 
 *          maximum = Maximum of the range.
 *
 * Returns: Clamped value.
 */
T clamp(T)(const T v, const T minimum, const T maximum) pure
    if(isNumeric!T)
in{assert(minimum <= maximum, "Clamp range minimum greater than maximum");}
body{return min(maximum, max(minimum, v));}
///Unittest for clamp() .
unittest
{
    assert(clamp(1.1, -1.0, 2.0) == 1.1);
    assert(clamp(1.1, 2.0, 3.0) == 2.0);
    assert(clamp(1.1, -1.0, 1.0) == 1.0);
}

/**
 * Round a float value to nearest signed 32-bit int.
 *
 * Params:  f = Float to round.
 *
 * Returns: Nearest int to given value.
 */
int roundS32(T)(const T f) if(isNumeric!T){return cast(int)round(f);}

/**
 * Floor a float value to an unsigned 8-bit int.
 *
 * Params:  f = Float to round. Must be less than 256 and greater or equal to 0.
 *                                                                                   
 * Returns: Floor of given value as ubyte.
 */
ubyte floorU8(float f) pure
{
    f += 256.0f;
    return cast(ubyte)(((*cast(uint*)&f)&0x7fffff)>>15);
}
///Unittest for floorU8.
unittest
{
    assert(floorU8(255.001) == 255);
    assert(floorU8(8.001) == 8);
    assert(floorU8(7.999) == 7);
}

/**
 * Floor a double value to a signed 32-bit int
 *
 * Params:  f = Double to round. Must be less than 2^31 and greater or equal to -(2^31).
 *
 * Returns: Floor of given value as int.
 */
int floorS32(double f) pure
{
    //2 ^ 36 * 1.5,  (52 - 16 == 36) uses limited precisicion to floor
    f += 68719476736.0*1.5; 
    return (*cast(int*)&f) >> 16;
}                                                                                      
///Unittest for floorS32.
unittest
{
    assert(floorS32(8.00001) == 8);
    assert(floorS32(7.99999) == 7);
    assert(floorS32(-0.00001) == -1);
}

///Array of first 32 powers of 2.
uint[] powersOfTwo = generatePot();

///Generate the powersOfTwo array and return it.
private uint[] generatePot()
{
    uint[] pot;
    foreach(p; 0 .. 32){pot ~= cast(uint)pow(cast(real)2, p);}
    return pot;
}
///Unittest for generatePot().
unittest
{
    assert(powersOfTwo[0] == 1);
    assert(powersOfTwo[1] == 2);
    assert(powersOfTwo[8] == 256);
    assert(powersOfTwo[14] == 16384);
}

/**
 * Get the smallest power of two greater or equal to given number.
 *
 * Params:  num = Number to get ceiling power of two to.
 *
 * Returns: Smallest power of two greater or equal to given number.
 */
uint potCeil(const uint num) 
in{assert(num <= powersOfTwo[$ - 1], "Can't compute ceiling power of two for huge ints");}
body
{
    foreach(pot; powersOfTwo)
    {
        if(pot >= num){return pot;}
    }
    assert(false);
}
///Unittest for potCeil.
unittest
{
    assert(potCeil(65535) == 65536);
    assert(potCeil(8) == 8);
    assert(potCeil(9) == 16);
    assert(potCeil(12486) == 16384);
}

/**
 * Determine if the given number is a power of two.
 *
 * Params:  num = Number to check.
 *
 * Returns: True if the number is a power of two, false otherwise.
 */
bool isPot(const uint num)
{
    return powersOfTwo.canFind(num);
}
