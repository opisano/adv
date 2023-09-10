module ecs.bitset;

import std.traits: isUnsigned;

/** 
 * A fixed bitset structure backed by an integer value
 */
struct BitSet(T) if (isUnsigned!T)
{
    this(T value)
    {
        m_data = value;
    }

    T opAssign(T value)
    {
        return m_data = value;
    }

    /** 
     * Returns the state of bit at index.
     * 
     * Params:
     *     index = bit index to test 
     * 
     * Returns:
     *     true if bit is set, false otherwise. 
     */
    bool opIndex(size_t index) pure const nothrow @nogc
    in 
    {
        assert (index < length);
    }
    do
    {
        T mask = (T(1) << index);
        return (m_data & mask) != 0;
    }

    /** 
     * Sets the state of bit at index 
     * 
     * Params:
     *     index = bit index to set
     *     state = value to set 
     */
    void opIndexAssign(bool state, size_t index) pure nothrow @nogc
    in
    {
        assert (index < length);
    }
    do 
    {
        T mask = (1 << index);
        m_data = state ? (m_data | mask) : (m_data & ~mask); 
    }

    /** 
     * Returns size in bits.
     */
    static size_t length() pure nothrow @nogc
    {
        return T.sizeof * 8;
    }

    /** 
     * Returns the underlying value.
     */ 
    T value() pure const nothrow @nogc 
    {
        return m_data;
    }

private:
    T m_data;
}

unittest
{
    import std.format;

    // Test default size 
    BitSet!uint bs;
    assert (bs.length == 32);

    // Test bits are clear by default 
    foreach (bit; 0 .. 32)
    {
        assert (bs[bit] == false, "Error: bit %s is set".format(bit));
    }

    // Set bits 3, 5 and 7
    bs[3] = true;
    bs[5] = true;
    bs[7] = true;

    // Test bits 
    foreach (bit; 0..32)
    {
        if (bit == 3 || bit == 5 || bit == 7)
        {
            assert (bs[bit] == true, "Error: bit %s is not set".format(bit));
        }
        else 
        {
            assert (bs[bit] == false, "Error: bit %s is set".format(bit));
        }
    }

    assert (bs.value() == 0b1010_1000);

    // clear bit 5
    bs[5] = false;

    // Test bits 
    foreach (bit; 0..32)
    {
        if (bit == 3 || bit == 7)
        {
            assert (bs[bit] == true, "Error: bit %s is not set".format(bit));
        }
        else 
        {
            assert (bs[bit] == false, "Error: bit %s is set".format(bit));
        }
    }
}
