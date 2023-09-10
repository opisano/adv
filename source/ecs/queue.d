module ecs.queue;

import core.exception;

/** 
 * A queue structure backed by a static array of Size elements.
 */
struct Queue(T, size_t Size)
{
    /** 
     * Returns next item in the queue.
     */
    T peek() 
    {
        return m_data[front];
    }

    /** 
     * Returns the element count in the queue.
     */
    size_t length() const 
    {
        return m_length;
    }

    /** 
     * returns true if queue is empty, false otherwise.
     */
    bool empty() const 
    {
        return m_length == 0;
    }


    /** 
     * Push a value to this queue.
     * 
     * Params:
     *     value = Value to enqueue
     * 
     * Throws: 
     *     RangeError if this queue is full 
     */
    void push(T value)
    {
        if (m_length == Size)
        {
            throw new RangeError("Queue overflow");
        }
        
        rear = (rear + 1) % Size;
        m_data[rear] = value;
        m_length++;
    }

    /** 
     * Pop a value from this queue
     * 
     * Returns:
     *     The first value in the queue.
     */
    T pop()
    {
        if (empty())
        {
            throw new RangeError("Queue is empty");
        }

        T ret = m_data[front];
        front = (front + 1) % Size;
        m_length--;
        return ret;
    }

private:
    invariant()
    {
        assert (m_length <= Size );
    }

    T[Size] m_data;
    size_t m_length;
    int rear = -1;
    int front;
}

unittest 
{
    Queue!(int, 10) q;

    assert (q.empty);
    assert (q.length == 0);

    q.push(1);
    q.push(16);
    q.push(76);

    assert (!q.empty);
    assert (q.length == 3);

    assert (q.pop() == 1);
    assert (q.pop() == 16);
    assert (q.pop() == 76);

    assert (q.empty);
    assert (q.length == 0);
}