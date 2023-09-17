module ecs.system;

import automem.ref_counted;
import containers.ttree;
import ecs.entity;
import ecs.flatmap;

struct System 
{
    TTree!Entity m_entities;
}


struct SystemManager 
{
    RefCounted!T registerSystem(T)()
    {
        string typename = T.stringof;
        assert (m_systems.find(typename).isNull);

        auto system = RefCounted!(T)();
        m_systems.insert(typename, system);
        return system;
    }

    void setSignature(T)(Signature signature)
    {
        string typename = T.stringof;
        assert (m_systems.find(typename.isNull == false));

        m_signatures.insert(typename, signature);
    }

    void entityDestroyed(Entity entity)
    {
        foreach (ref system; m_systems.values)
        {
            system.m_entities.remove(entity);
        }
    }

    void entitySignatureChanged(Entity entity, Signature entitySignature)
    {
        foreach (type; m_systems.keys)
        {
            const systemSignature = m_signatures[type];
            auto system = m_systems[type];

            if ((entitySignature.value & systemSignature.value) == systemSignature.value)
            {
                system.m_entities.put(entity);
            }
            else 
            {
                system.m_entities.remove(entity);
            }
        }
    }

private:
    FlatMap!(string, Signature) m_signatures;
    FlatMap!(string, RefCounted!System) m_systems;
}