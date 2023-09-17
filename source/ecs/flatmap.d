module ecs.flatmap;

import automem.vector;

import std.algorithm.iteration: map;
import std.algorithm.searching: countUntil;
import core.exception;
import std.range;
import std.typecons;

version (unittest)
{
    import std.algorithm.comparison: equal;
}

struct FlatMap(K, V)
{

    void insert(K key, V value)
    {
        this[key] = value;
    }

    unittest
    {
        FlatMap!(string, int) fm;
        assert (fm.empty);

        fm.insert("Vivien", 22);
        assert (fm.length == 1);
    }

    bool empty() const 
    {
        return length == 0;
    }

    size_t length() const 
    {
        return m_keys.length;
    }

    invariant()
    {
        assert (m_keys.length == m_values.length);
    }

    Nullable!V find(K key)
    {
        ptrdiff_t index = m_keys[].countUntil(key);

        if (index < 0)
        {
            Nullable!V ret;
            return ret;
        }

        return nullable(m_values[index]);
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        fm.insert("Vivien", 22);
        fm.insert("Xavier", 30);

        auto someOne = fm.find("Vivien");
        assert (!someOne.isNull);
        assert (someOne.get == 22);

        someOne = fm.find("Jean-Pierre");
        assert (someOne.isNull);
    }

    
    V opIndex(K key)
    {
        auto found = find(key);
        
        if (found.isNull)
        {
            throw new RangeError("Cannot find key");
        }

        return found.get;
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        assert (fm.empty);

        fm.insert("Vivien", 22);
        assert (fm["Vivien"] == 22);
        assert (fm.length == 1);
    }

    void opIndexAssign(V value, K key)
    {                
        ptrdiff_t index = m_keys[].countUntil(key);

        if (index < 0)
        {
            m_keys.put(key);
            m_values.put(value);
        }
        else 
        {
            m_values[index] = value;   
        }
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        fm["Vivien"] = 22;

        assert (fm["Vivien"] == 22);
        fm["Vivien"] = 23;
        assert (fm["Vivien"] == 23);
    }

    auto keys()
    {
        return m_keys[];
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        fm["Vivien"] = 22;
        fm["Xavier"] = 30;

        assert (fm.keys.equal(["Vivien", "Xavier"]));
    }

    auto values()
    {
        return m_values[];
    }

    unittest 
    {
        FlatMap!(string, int) fm;
        fm["Vivien"] = 22;
        fm["Xavier"] = 30;

        assert (fm.values.equal([22, 30]));
    }



private:
    Vector!K m_keys;
    Vector!V m_values;
}