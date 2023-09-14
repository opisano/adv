module ecs.component;

import ecs.entity;
import ecs.flatmap;

/** 
 * Implementation of the Observable design pattern to track Entity lifetime.
 */
interface EntityObserver
{
    void entityDestroyed(Entity entity);
}


/** 
 * Stores a Component for various Entites
 */
final class ComponentArray(T) : EntityObserver
{
    enum INVALID_INDEX = ushort.max;

    /** 
     * default constructor
     */
    this()
    {
        m_indexToEntity[] = INVALID_ENTITY;
        m_entityToIndex[] = INVALID_INDEX;
    }

    /** 
     * Insert a component for a given Entity in the array
     */
    void insert(Entity entity, T component)
    in (m_entityToIndex[entity] == INVALID_INDEX, "Entity already in array")
    {
        m_components[m_size] = component;
        m_indexToEntity[m_size] = entity;
        m_entityToIndex[entity] = cast(Entity)m_size;
        m_size++;
    }

    /** 
     * Remove component for a given entity from the array.
     */
    void remove(Entity entity)
    {
        /*
        When a entity is removed, the last value takes place of the one being removed 
        and m_size is decremented.

        Indices are then modified accordingly
        */ 

        size_t indexOfRemovedEntity = m_entityToIndex[entity];
        size_t indexOfLastElement = m_size - 1;

        m_components[indexOfRemovedEntity] = m_components[indexOfLastElement];
        m_components[indexOfLastElement] = T.init;

		Entity entityOfLastElement = m_indexToEntity[indexOfLastElement];
		m_entityToIndex[entityOfLastElement] = cast(Entity)indexOfRemovedEntity;
		m_indexToEntity[indexOfRemovedEntity] = INVALID_ENTITY;

        --m_size;
    }

    ref T get(Entity entity)
    in (m_entityToIndex[entity] != INVALID_INDEX, "Entity not in array")
    {
        return m_components[m_entityToIndex[entity]];
    }

    override void entityDestroyed(Entity entity)
    {
        // When an entity is destroyed, we remove it from the array
        remove(entity);
    }

    size_t length() const 
    {
        return m_size;
    }

    /// Stores component T for entities
    T[MAX_ENTITIES] m_components;

    /// Maps entities to indices in the m_component array
    Entity[MAX_ENTITIES] m_entityToIndex;

    /// Maps indices in the m_component array to entities
    Entity[MAX_ENTITIES] m_indexToEntity;

    /// Current size of m_component array
    size_t m_size;
}

unittest 
{
    scope em = EntityManager();
    scope e1 = em.createEntity();
    scope e2 = em.createEntity();

    scope arr = new ComponentArray!int();
    arr.insert(e1, 42);
    arr.insert(e2, 18);

    assert (arr.length == 2);

    // Check that get works correctly 
    arr.get(e1) += 10;
    assert (arr.get(e1) == 52);
    assert (arr.get(e2) == 18);

    // Check that remove works correctly
    arr.remove(e1);
    assert (arr.length == 1);
    assert (arr.get(e2) == 18);
    assert (arr.get(e2) *= 2);
    assert (arr.get(e2) == 36);

}


/** 
 * The ComponentManager is in charge of talking to all of the different 
 * ComponentArrays when a component needs to be added or removed.
 */
struct ComponentManager
{
    /** 
     * Adds support for a new type of Component.
     * 
     */
    void registerComponent(T)()
    {
        string typeName = T.stringof;
        assert (m_componentTypes.find(typeName).isNull);

        m_componentTypes.insert(typeName, m_nextComponentType);
        m_componentArrays.insert(typeName, new ComponentArray!T);
        m_nextComponentType++;
    }

    /** 
     * Returns the internal component type identifier of a type.
     */
    ComponentType getComponentType(T)()
    {
        string typeName = T.stringof;
        assert (!m_componentTypes.find(typeName).isNull);

        return m_componentTypes[typeName];
    }

    /** 
     * Adds a new Entity - Component association.
     */
    void addComponent(T)(Entity entity, T component)
    {
        getComponentArray!T.insert(entity, component);
    }

    /** 
     * Deletes an existing Entity - Component association.
     */
    void removeComponent(T)(Entity entity)
    {
        getComponentArray!T.remove(entity);
    }

    /** 
     * Get the Component associated to an entity.
     *
     * Params:
     *     entity = The entity to get the component for.
     */
    ref T getComponent(T)(Entity entity)
    {
        return getComponentArray!T.get(entity);
    }

    /** 
     * Clears every resource used by an entity.
     */
    void entityDestroyed(Entity entity)
    {
        foreach (ref component; m_componentArrays.values)
        {
            component.entityDestroyed(entity);
        }
    }

private:
    FlatMap!(string, ComponentType) m_componentTypes;
    FlatMap!(string, EntityObserver) m_componentArrays;
    ComponentType m_nextComponentType;

    ComponentArray!T getComponentArray(T)()
    {
        string typeName = T.stringof;
        assert (!m_componentTypes.find(typeName).isNull);
        return cast(ComponentArray!T) m_componentArrays[typeName];
    }
}

unittest 
{
    Entity e = 42;

    ComponentManager mgr;
    mgr.registerComponent!int();
    mgr.registerComponent!double();

    ComponentType ctInt = mgr.getComponentType!int;
    ComponentType ctDbl = mgr.getComponentType!double;

    assert (ctInt != ctDbl);

    mgr.addComponent!int(e, 18);
    mgr.addComponent!double(e, 3.14);

    assert (mgr.getComponent!int(e) == 18);
    assert (mgr.getComponent!double(e) == 3.14);

    mgr.getComponent!int(e) += 1;

    assert (mgr.getComponent!int(e) == 19);

    mgr.removeComponent!int(e);
    mgr.removeComponent!double(e);
}
