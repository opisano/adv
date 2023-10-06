module game.combat.model;

import bindbc.sdl;
import std.algorithm;
import std.random;
import std.range;
import std.string;
import std.sumtype;
import tools.stack;


class Entity 
{
    string name;

    int m_maxHp;
    int m_hp;

    int m_maxSp;
    int m_sp;

    invariant()
    {
        assert (m_hp <= m_maxHp);
        assert (m_sp <= m_maxSp);
    }

    /** 
     * HP setter
     */
    void hp(int value)
    {
        value = clamp(value, 0, m_maxHp);
        m_hp = value;
    }

    /** 
     * HP getter 
     */
    int hp() const 
    {
        return m_hp;
    }

    /** 
     * SP setter 
     */
    void sp(int value)
    {
        value = clamp(value, 0, m_maxSp);
        m_sp = value;
    }

    /** 
     * SP getter
     */
    int sp() const 
    {
        return m_sp;
    }

    /** 
     * Max HP setter 
     */
    void maxHp(int value)
    {
        m_maxHp = value;
        m_hp = min(m_hp, m_maxHp);
    }

    /** 
     * Max HP getter 
     */
    int maxHp() const 
    {
        return m_maxHp;
    }

    /** 
     * Max SP setter 
     */
    void maxSp(int value)
    {
        m_maxSp = value;
        m_sp = min(m_sp, m_maxSp);
    }

    /** 
     * Max SP getter 
     */ 
    int maxSp() const 
    {
        return m_maxSp;
    }
}

class Enemy : Entity
{
    int xpReward;

    /** 
     * Items drop rate
     * 
     * Key is the ItemId, Value is the drop rate in 10_000ths 
     */
    int[ItemId] drops;
}

alias ItemId = int;
alias SpellId = int;
alias AbilityId = int;


/** 
 * Returns the total XP amount won for defeating some enemies.
 */
int xpReward(const(Enemy)[] enemies) pure nothrow @nogc
{
    return enemies[].map!(e => e.xpReward).sum;
}




/** 
 * Stores all the data used by CombatView to display the combat.
 */
struct CombatModel
{
    ~this()
    {
        if (m_pBackground != null)
        {
            SDL_DestroyTexture(m_pBackground);
            m_pBackground = null;
        }
    }

    void loadBackground(scope SDL_Renderer* pRenderer, string filename)
    {
        if (m_pBackground != null)
        {
            SDL_DestroyTexture(m_pBackground);
        }

        m_pBackground = IMG_LoadTexture(pRenderer, toStringz(filename));
    }

    SDL_Texture* background() 
    {
        return m_pBackground;
    }

    /** 
     * Calculates the XP amount given to the player's team at the end of combat
     */
    int xpReward() const 
    {
        return m_deadAntagonists[].map!(e => e.xpReward).sum;
    }

    /** 
     * Provides item drops at the end of combat according to their drop rate.
     * 
     * Params:
     *     OR = An output range Type
     *     output = The output range which will receive items
     */
    void drops(OR)(OR output) if (isOutputRange!(OR, ItemId))
    {
        foreach (enemy; m_deadAntagonists)
        {
            foreach (drop; enemy.drops.byKeyValue)
            {
                int step = uniform(0, 10_000);
                if (step < drop.value)
                {
                    output.put(drop.key);
                }
            }
        }
    }

    Entity frontProtagonist()
    {
        return m_protagonists[m_memberIndex];
    }

    void popFrontProtagonist()
    {
        ++m_memberIndex;
        if (m_memberIndex >= m_protagonists.length)
            m_memberIndex = 0;
    }

    void pushAction(CombatAction ca)
    {
        m_actionStack.push(ca);
    }

private:
    /// The background picture
    SDL_Texture* m_pBackground;

    /// Stores actions decided so far 
    Stack!(CombatAction, 10) m_actionStack;

    /// Player's team
    Entity[] m_protagonists;

    /// Alive ennemies 
    Enemy[] m_antagonists;

    /// Dead ennemies
    Enemy[] m_deadAntagonists;

    size_t m_memberIndex;
}


/** 
 * A combat action is a (subject, action, target) association.
 */
struct CombatAction
{
    Entity subject;
    Action action;
    Entity target;
}

/** 
 * An attack: the subject uses equipped weapon to deal physical damage.
 */
struct AttackAction 
{

}

/** 
 * An item action: the subject uses some item in its inventory.
 */
struct ItemAction
{
    /// The item to use
    ItemId item;
}

/** 
 * A spell action: the subject casts a spell.
 */
struct SpellAction
{
    /// The spell to cast
    SpellId spell;
}

/** 
 * A defend action: the subject protects themselves
 */
struct DefendAction
{

}

/** 
 * An ability action: the subject uses one of their special ability.
 */
struct AbilityAction
{
    /// The ability to use
    AbilityId ability;
}

/** 
 * Flee action: the subject tries to flee.
 */
struct FleeAction
{

}


alias Action = SumType!(AttackAction, ItemAction, SpellAction, DefendAction, AbilityAction, FleeAction);