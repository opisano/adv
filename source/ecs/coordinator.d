module ecs.coordinator;

import ecs.entity;
import ecs.component;
import ecs.system;

import automem.ref_counted;

/** 
 * Binds together an entity manager, a component manager and a system manager and
 * offers methods to make usage safer and simpler.
 */
struct Coordinator
{
    // Entity methods 

    Entity createEntity()
    {
        return m_entityManager.createEntity();
    }

    void destroyEntity(Entity entity)
    {
        m_entityManager.destroyEntity(entity);
        m_componentManager.entityDestroyed(entity);
        m_systemManager.entityDestroyed(entity);
    }

    // Component methods

    void registerComponent(T)()
    {
        m_componentManager.registerComponent!T();
    }

    void addComponent(T)(Entity entity, T component)
    {
        m_componentManager.addComponent!T(entity, component);

        auto signature = m_entityManager.getSignature(entity);
        signature[m_componentManager.getComponentType!T()] = true;
        m_entityManager.setSignature(entity, signature);

        m_systemManager.entitySignatureChanged(entity, signature);
    }

    void removeComponent(T)(Entity entity)
    {
        m_componentManager.removeComponent!T(entity);

        auto signature = m_entityManager.getSignature(entity);
        signature[m_componentManager.getComponentType!T()] = false;

        m_systemManager.entitySignatureChanged(entity, signature);
    }

    ref T getComponent(T)(Entity entity) 
    {
        return m_componentManager.getComponent!T(entity);
    }

    ComponentType getComponentType(T)() 
    {
        return m_componentManager.getComponentType!T();
    }

    // System methods 

    RefCounted!T registerSystem(T)()
    {
        return m_systemManager.registerSystem!T();
    }

    void setSystemSignature(T)(Signature signature)
    {
        m_systemManager.setSignature!T(signature);
    }
    

private:
    EntityManager m_entityManager;
    ComponentManager m_componentManager;
    SystemManager m_systemManager;
}