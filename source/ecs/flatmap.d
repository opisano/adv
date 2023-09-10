module source.ecs.flatmap;

import automem.vector;

import std.algorithm.searching: countUntil;
import std.typecons;



struct FlatMap(K, V)
{

    void insert(K key, V value)
    {
        m_array.put(tuple(key, value));
    }

    unittest
    {
        FlatMap!(string, int) fm;
        assert (fm.empty);

        fm.insert("Vivien", 22);
        assert (fm.length == 1);
    }

    ref K opIndex(K key)
    {
        ptrdiff_t index = m_array[].countUntil!((k,v) => k == key);
        
        if (index < 0)
        {
            throw new RangeError("Cannot find key");
        }

        return m_array[index][1];
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        assert (fm.empty);

        fm.insert("Vivien", 22);
        assert (fm["Vivien"] == 22);
        assert (fm.length == 1);
    }

    ref K opIndexAssign(V value, K key)
    {                
        ptrdiff_t index = m_array[].countUntil!((k,v) => k == key);

        if (index < 0)
        {
            insert(key, value);
            return m_array[$-1][1];
        }
        else 
        {
            return m_array[index][1];   
        }
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        fm["Vivien"] = 22;

        assert (fm["Vivien"] == 22);
        fm["Vivien"]++;
        assert (fm["Vivien"] == 23);
    }

    size_t length() const 
    {
        return m_array.length;
    }

    bool empty() const 
    {
        return length == 0;
    }

private:
    Vector!(Tuple!(const K, V)) m_array;
}