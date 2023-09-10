module ecs.entity;

import ecs.bitset;
import ecs.queue;

/// A simple type alias 
alias Entity = ushort;
enum INVALID_ENTITY = Entity.max;

/// Used to define the size of arrays
enum Entity MAX_ENTITIES = 5_000;



/// A simple type alias
alias ComponentType = ubyte;

/// Used 
enum ComponentType MAX_COMPONENTS = 32;
alias Signature = BitSet!uint;


/** 
 * An EntityManager is in charge of distributing entity IDs and keeping record 
 * of which IDs are in use and which are not.
 * 
 */
struct EntityManager
{
    /**
     * Create an EntityManager. 
     * 
     * Just a simple trick to workaround the fact that D structs don't have 
     * default constructors.
     */
    static EntityManager opCall()
    {
        EntityManager em;

        // make all the entities available 
        foreach (i; 0 .. MAX_ENTITIES)
        {
            em.m_availableEntities.push(cast(Entity)i);
        }

        return em;
    }

    /** 
     * Create an entity 
     */ 
    Entity createEntity()
    {
        Entity id = m_availableEntities.pop();
        m_livingEntityCount++;
        return id;
    }

    unittest 
    {
        auto em = EntityManager();
        Entity e1 = em.createEntity();
        Entity e2 = em.createEntity();

        assert (e1 != e2);
        assert (em.livingEntityCount == 2);
    }    

    /** 
     * Clears the resources used for tracking an entity.
     */
    void destroyEntity(Entity entity)
    {
        m_signatures[entity] = Signature.init;
        m_availableEntities.push(entity);
        m_livingEntityCount--;
    }

    unittest
    {
        auto em = EntityManager();
        Entity e1 = em.createEntity();
        Entity e2 = em.createEntity();

        em.destroyEntity(e2);
        assert (em.livingEntityCount == 1);
    }

    /** 
     * Returns the number of entities currently living.
     */
    size_t livingEntityCount() const 
    {
        return m_livingEntityCount;
    }

    /** 
     * Returns the Signature associated to an Entity
     */
    Signature getSignature(Entity entity) const
    {
        return m_signatures[entity];
    }

    /** 
     * Set an Entity's signature
     */
    void setSignature(Entity entity, Signature signature)
    {
        m_signatures[entity] = signature;
    }

    unittest 
    {
        auto em = EntityManager();
        Entity e = em.createEntity();
        em.setSignature(e, Signature(0b101));

        Signature sig = em.getSignature(e);
        assert (sig[0] == true);
        assert (sig[1] == false);
        assert (sig[2] == true);
        assert (sig[3] == false);
    }

private:
    invariant()
    {
        assert (m_livingEntityCount <= MAX_ENTITIES);
    }

    Queue!(Entity, MAX_ENTITIES) m_availableEntities;
    Signature[MAX_ENTITIES] m_signatures;


    size_t m_livingEntityCount;
}

