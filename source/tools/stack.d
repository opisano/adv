module tools.stack;

struct Stack(T, size_t size)
{
    bool empty() const 
    {
        return m_length == 0;
    }

    bool full() const 
    {
        return m_length == m_data.length;
    }

    ref T top() 
    {
        return m_data[m_length - 1];
    }

    void push()(auto ref T value)
    {
        m_data[m_length++] = value;
    }

    T pop()
    {
        return m_data[--m_length];
    }

    size_t length() const 
    {
        return m_length;
    }

private:
    T[size] m_data;
    size_t m_length;
}

unittest
{
    Stack!(int, 3) s;
    assert (s.empty);

    s.push(1);
    assert (!s.empty);
    assert (!s.full);
    assert (s.length == 1);
    assert (s.top == 1);

    s.push(2);
    assert (!s.empty);
    assert (!s.full);
    assert (s.length == 2);
    assert (s.top == 2);

    s.push(3);
    assert (!s.empty);
    assert (s.full);
    assert (s.length == 3);
    assert (s.top == 3);
}