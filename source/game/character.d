module game.character;


import automem.ref_counted;
import bindbc.sdl;
import game.app: WINDOW_HEIGHT, WINDOW_WIDTH;
import game.basics;
import game.map;
import game.sprite;
import math.vector2d;
import std.algorithm.searching: any;
import std.experimental.logger;
import std.random;

/** 
 * A character State
 */
enum State 
{
    Standing,
    Walking
}


/** 
 * An updatable which handles input.
 */
class InputComponent: Updatable
{
    this(Character chr)
    {
        m_char = chr;
    }

    /** 
     * Transform input state into character state 
     */
    override void update(ulong timeElapsedMs)
    {
        // Get current state
        State oldState = m_char.m_state;

        // If no direction is pressed, return to Standing state
        if (!m_directionsPressed[].any)
        {
            m_char.m_state = State.Standing;
            m_char.m_velocity = Vector2D!(float).init;
        }
        else 
        {
            m_char.m_state = State.Walking;

            Vector2D!float velocity;
            if (m_directionsPressed[cast(size_t)Orientation.Top]) 
            {
                m_char.m_orientation = Orientation.Top;
                velocity.y -= 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Bottom])
            {
                m_char.m_orientation = Orientation.Bottom;
                velocity.y += 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Right])
            {
                m_char.m_orientation = Orientation.Right;
                velocity.x += 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Left])
            {
                m_char.m_orientation = Orientation.Left;
                velocity.x -= 1;
            }

            m_char.m_velocity = velocity;
        }

        // Update state duration
        if (m_char.m_state == oldState)
        {
            m_char.m_stateDurationMs += timeElapsedMs;
        }
        else 
        {
            tracef("State changed to %s ", m_char.m_state);
            m_char.m_stateDurationMs = 0;
        }
    }

    final void setDirection(Orientation orientation, bool value)
    {
        m_directionsPressed[orientation] = value;
    }

    final bool isDirection(Orientation orientation)
    {
        return m_directionsPressed[orientation];
    }

    final void setAction(bool value)
    {
        m_actionPressed = value;
    }

    final bool isAction() const 
    {
        return m_actionPressed;
    }

    

protected:
    Character m_char;
    bool[4] m_directionsPressed;
    bool m_actionPressed;
}

/** 
 * NPC Artificial Intelligence 
 * 
 * In towns, NPC wander in a random direction for a duration then stop.
 */
final class WalkingNPCComponent : InputComponent
{
    this(Character chr)
    {
        super(chr);
    }

    override void update(ulong timeElapsedMs)
    {
        m_remainingTimeMs -= cast(long)timeElapsedMs;
        if (m_remainingTimeMs <= 0)
        {
            changeState();
        }

        super.update(timeElapsedMs);
    }

private:
    void changeState()
    {
        if (m_directionsPressed[].any)
        {
            changeToStanding();
        }
        else 
        {
            changeToWalking();
        }
    }

    void changeToStanding()
    {
        int[7] durations = [250, 300, 500, 600, 750, 900, 1000];
        m_directionsPressed[] = false;

        // stay standing for a random duration
        m_remainingTimeMs = durations[].choice;
    }

    void changeToWalking()
    {
        int[4] durations = [200, 300, 400, 500];

        Orientation orient = [Orientation.Top, Orientation.Right, Orientation.Bottom, Orientation.Left].choice;
        m_directionsPressed[] = false;
        m_directionsPressed[cast(int)orient] = true;

        // stay walking for a random duration 
        m_remainingTimeMs = durations[].choice;
    }

    // Remaining time in current state
    long m_remainingTimeMs;
}

/** 
 * A component that tests collision against the map 
 */
class MapCollisionComponent : Updatable 
{
    this(Character chr, Map* pMap)
    {
        m_char = chr;
        m_pMap = pMap;
    }

    override void update(ulong elapsedTimeMs)
    {
        // collision test depend on the direction the character is walking 

        if (m_char.m_velocity.x < 0)
        {
            testCollisionLeft();
        }
        else if (m_char.m_velocity.x > 0)
        {
            testCollisionRight();
        }

        if (m_char.m_velocity.y < 0)
        {
            testCollisionTop();
        }
        else if (m_char.m_velocity.y > 0)
        {
            testCollisionBottom();
        }
    }

private:

    void testCollisionLeft()
    {
        auto charRect = m_char.bbox();
        // get the bounding box of the first colliding tile left from this character
        auto leftBbox = m_pMap.bboxLeftOf(charRect);

        if (collide(charRect, leftBbox))
        {
            m_char.m_velocity.x = 0;
        }
    }

    void testCollisionRight()
    {
        auto charRect = m_char.bbox();
        // get the bounding box of the first colliding tile right from this character
        auto rightBbox = m_pMap.bboxRightOf(charRect);

        if (collide(charRect, rightBbox))
        {
            m_char.m_velocity.x = 0;
        }
    }

    void testCollisionTop()
    {
        auto charRect = m_char.bbox();
        // get the bounding box of the first colliding tile top from this character
        auto rightBbox = m_pMap.bboxTopOf(charRect);

        if (collide(charRect, rightBbox))
        {
            m_char.m_velocity.y = 0;
        }
    }

    void testCollisionBottom()
    {
        auto charRect = m_char.bbox();
        // get the bounding box of the first colliding tile bottom from this character
        auto rightBbox = m_pMap.bboxBottomOf(charRect);

        if (collide(charRect, rightBbox))
        {
            m_char.m_velocity.y = 0;
        }
    }

    Character m_char;
    Map* m_pMap;
}


struct CharacterBuilder
{
    this(RC!SpriteSheet pSpriteSheet)
    {
        m_pSpriteSheet = pSpriteSheet;
        m_char = new Character();
    }

    ref CharacterBuilder standing(int top, int right, int bottom, int left) return 
    {
        m_char.m_standingAnimation[cast(int)Orientation.Top] = Animation(m_pSpriteSheet, [top]);
        m_char.m_standingAnimation[cast(int)Orientation.Right] = Animation(m_pSpriteSheet, [right]);
        m_char.m_standingAnimation[cast(int)Orientation.Bottom] = Animation(m_pSpriteSheet, [bottom]);
        m_char.m_standingAnimation[cast(int)Orientation.Left] = Animation(m_pSpriteSheet, [left]);
        return this;
    }

    ref CharacterBuilder walkingTop(int[] indices) return 
    {
        m_char.m_walkingAnimations[cast(int)Orientation.Top] = Animation(m_pSpriteSheet, indices);
        return this;
    }

    ref CharacterBuilder walkingRight(int[] indices) return 
    {
        m_char.m_walkingAnimations[cast(int)Orientation.Right] = Animation(m_pSpriteSheet, indices);
        return this;
    }

    ref CharacterBuilder walkingBottom(int[] indices) return 
    {
        m_char.m_walkingAnimations[cast(int)Orientation.Bottom] = Animation(m_pSpriteSheet, indices);
        return this;
    }

    ref CharacterBuilder walkingLeft(int[] indices) return 
    {
        m_char.m_walkingAnimations[cast(int)Orientation.Left] = Animation(m_pSpriteSheet, indices);
        return this;
    }

    Character build()
    {
        return m_char;
    }

private:
    RC!SpriteSheet m_pSpriteSheet;
    Character m_char;
}


/** 
 * Holds information about a character in a top down view.
 */
final class Character : Entity
{
    override void draw(scope SDL_Renderer* pRenderer, SDL_Point viewPort)
    {
        // Determine the animation phase to draw
        Animation* anim;
        SDL_Rect srcRect;

        final switch (m_state)
        {
        case State.Standing:
            anim = &m_standingAnimation[cast(int)m_orientation];
            srcRect = anim.front;
            break;

        case State.Walking:
            anim = &m_walkingAnimations[cast(int)m_orientation];
            while (m_stateDurationMs > m_walkingAnimationDurationMs)
            {
                anim.popFront();
                m_stateDurationMs -= m_walkingAnimationDurationMs;
            }
            srcRect = anim.front;
            break;
        }

        int screenX = cast(int)m_position.x - viewPort.x;
        int screenY = cast(int)m_position.y - viewPort.y;

        if ((screenX >= -32 && screenX < WINDOW_WIDTH)
            && (screenY >= -32 && screenY < WINDOW_HEIGHT))
        {
        
            // Determine where to draw on the screen
            SDL_Rect dstRect = SDL_Rect(screenX, screenY, srcRect.w, srcRect.h);
            SDL_RenderCopy(pRenderer, anim.texture, &srcRect, &dstRect);

            version (Collisions)
            {
                // For debug purpose, draw bbox 
                auto rect = bbox();
                rect.x -= viewPort.x;
                rect.y -= viewPort.y;
                SDL_RenderDrawRect(pRenderer, &rect);
            }
        }
    }

    override void update(ulong timeElapsedMs)
    {
        m_input.update(timeElapsedMs);
        m_collision.update(timeElapsedMs);

        if (m_velocity.length > 0) {
            m_position += m_velocity.normalized * m_speed;
        }
    }

    override SDL_Rect bbox() const pure
    {
        return SDL_Rect(cast(int)m_position.x + 4, cast(int)m_position.y + 16, 24, 16);
    }

    /** 
     * Returns the horizontal distance to another character 
     */
    float hdistance(scope const(Entity) other) const pure
    {
        Vec2f a = center();
        Vec2f b = other.center();
        return b.x - a.x;
    }

    float vdistance(scope const(Entity) other) const pure
    {
        Vec2f a = center();
        Vec2f b = other.center();
        return b.y - a.y;
    }

    /** 
     * Return true if this Character is facing the direction of another Character.
     * 
     * Params:
     *     other: The other character to check for orientation. 
     * 
     */
    bool facing(scope const(Entity) other) pure const 
    {
        final switch (m_orientation)
        {
        case Orientation.Top:
            return m_position.y > other.m_position.y;
        case Orientation.Right:
            return m_position.x < other.m_position.x;
        case Orientation.Bottom:
            return m_position.y < other.m_position.y;
        case Orientation.Left:
            return m_position.x > other.m_position.x;
        }
    }

    void setFacing(scope const(Entity) other) 
    {
        float hdist = hdistance(other);
        float vdist = vdistance(other);

        if (hdist > 0) // other is at our right
        {
            if (vdist > 0) // and other is at our bottom
            {
                m_orientation = hdist > vdist ? Orientation.Right : Orientation.Bottom;
            }
            else 
            {
                m_orientation = hdist > vdist ? Orientation.Right : Orientation.Top;
            }
        }
        else // other is at our left
        {
            if (vdist < 0) // and other is at our top
            {
                m_orientation = vdist < hdist ? Orientation.Top: Orientation.Left;
            }
            else 
            {
                m_orientation = vdist < hdist ? Orientation.Bottom : Orientation.Left;
            }
        }
    }

    override string interact(scope const(Entity) c)
    {
        setFacing(c);

        return "Bonjour, ceci est un texte qui doit etre decoupe en lignes.\nEt une troisieme.\n" 
               ~ "Si ce texte est trop long, il doit etre decoupe.";
    }

    // Animation data 
    Animation[4] m_walkingAnimations;
    Animation[4] m_standingAnimation;
    ulong m_stateDurationMs;
    ulong m_walkingAnimationDurationMs = 150;
    Orientation m_orientation;
    State m_state;

    // Position in map coordinates
    Vec2f m_position;

    // Velocity on axes
    Vec2f m_velocity;

    // Speed multiplier
    float m_speed = 1.0;

    // Component that react to user input
    InputComponent m_input;
    // Component that react to collisions 
    MapCollisionComponent m_collision;
}

Character createCharacter(RC!SpriteSheet pSpriteSheet, int charIndex)
{
    int animOffset = ((charIndex % 4) * 3) + ((charIndex / 4) * 48);

    int[] walkTop = [
        3 * pSpriteSheet.width + animOffset,
        3 * pSpriteSheet.width + animOffset + 1, 
        3 * pSpriteSheet.width + animOffset + 2,
        3 * pSpriteSheet.width + animOffset + 1,
    ];

    int[] walkRight = [
        2 * pSpriteSheet.width + animOffset,
        2 * pSpriteSheet.width + animOffset + 1, 
        2 * pSpriteSheet.width + animOffset + 2,
        2 * pSpriteSheet.width + animOffset + 1,
    ];

    int[] walkBottom = [
        0 * pSpriteSheet.width + animOffset,
        0 * pSpriteSheet.width + animOffset + 1, 
        0 * pSpriteSheet.width + animOffset + 2,
        0 * pSpriteSheet.width + animOffset + 1,
    ];

    int[] walkLeft = [
        1 * pSpriteSheet.width + animOffset,
        1 * pSpriteSheet.width + animOffset + 1, 
        1 * pSpriteSheet.width + animOffset + 2,
        1 * pSpriteSheet.width + animOffset + 1,
    ];

    return CharacterBuilder(pSpriteSheet)
                .standing(3 * pSpriteSheet.width + animOffset + 1, 
                          2 * pSpriteSheet.width + animOffset + 1,
                          0 * pSpriteSheet.width + animOffset + 1,
                          1 * pSpriteSheet.width + animOffset + 1)
                .walkingTop(walkTop)
                .walkingRight(walkRight)
                .walkingBottom(walkBottom)
                .walkingLeft(walkLeft)
                .build();
}