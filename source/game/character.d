module game.character;


import automem.ref_counted;
import derelict.sdl2.sdl;
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
    this(Character* pChar)
    {
        m_pChar = pChar;
    }

    /** 
     * Transform input state into character state 
     */
    override void update(ulong timeElapsedMs)
    {
        // Get current state
        State oldState = m_pChar.m_state;

        // If no direction is pressed, return to Standing state
        if (!m_directionsPressed[].any)
        {
            m_pChar.m_state = State.Standing;
            m_pChar.m_velocity = Vector2D!(float).init;
        }
        else 
        {
            m_pChar.m_state = State.Walking;

            Vector2D!float velocity;
            if (m_directionsPressed[cast(size_t)Orientation.Top]) 
            {
                m_pChar.m_orientation = Orientation.Top;
                velocity.y -= 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Bottom])
            {
                m_pChar.m_orientation = Orientation.Bottom;
                velocity.y += 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Right])
            {
                m_pChar.m_orientation = Orientation.Right;
                velocity.x += 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Left])
            {
                m_pChar.m_orientation = Orientation.Left;
                velocity.x -= 1;
            }

            m_pChar.m_velocity = velocity;
        }

        // Update state duration
        if (m_pChar.m_state == oldState)
        {
            m_pChar.m_stateDurationMs += timeElapsedMs;
        }
        else 
        {
            tracef("State changed to %s ", m_pChar.m_state);
            m_pChar.m_stateDurationMs = 0;
        }
    }

    void setDirectionPressed(Orientation orientation)
    {        
        m_directionsPressed[cast(size_t)orientation] = true;

    }

    void setDirectionReleased(Orientation orientation)
    {
        m_directionsPressed[cast(size_t)orientation] = false;
    }

    void setActionPressed()
    {
        m_actionPressed = true;
    }

    void setActionReleased()
    {
        m_actionPressed = false;
    }

protected:
    Character* m_pChar;
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
    this(Character* pChar)
    {
        super(pChar);
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
        m_directionsPressed[] = false;

        // stay standing for a random duration
        m_remainingTimeMs = [250, 300, 500, 600, 750, 900, 1000].choice;
    }

    void changeToWalking()
    {
        Orientation orient = [Orientation.Top, Orientation.Right, Orientation.Bottom, Orientation.Left].choice;
        m_directionsPressed[] = false;
        m_directionsPressed[cast(int)orient] = true;

        // stay walking for a random duration 
        m_remainingTimeMs = [200, 300, 400, 500].choice;
    }

    // Remaining time in current state
    long m_remainingTimeMs;
}

/** 
 * A component that tests collision agains the map 
 */
class CollisionComponent : Updatable 
{
    this(Character* pChar, Map* pMap)
    {
        m_pChar = pChar;
        m_pMap = pMap;
    }

    override void update(ulong elapsedTimeMs)
    {
        // collision test depend on the direction the character is walking 

        if (m_pChar.m_velocity.x < 0)
        {
            testCollisionLeft();
        }
        else if (m_pChar.m_velocity.x > 0)
        {
            testCollisionRight();
        }

        if (m_pChar.m_velocity.y < 0)
        {
            testCollisionTop();
        }
        else if (m_pChar.m_velocity.y > 0)
        {
            testCollisionBottom();
        }
    }

private:

    void testCollisionLeft()
    {
        auto charRect = m_pChar.bbox();
        // get the bounding box of the first colliding tile left from this character
        auto leftBbox = m_pMap.bboxLeftOf(charRect);

        if (collide(charRect, leftBbox))
        {
            m_pChar.m_velocity.x = 0;
        }
    }

    void testCollisionRight()
    {
        auto charRect = m_pChar.bbox();
        // get the bounding box of the first colliding tile right from this character
        auto rightBbox = m_pMap.bboxRightOf(charRect);

        if (collide(charRect, rightBbox))
        {
            m_pChar.m_velocity.x = 0;
        }
    }

    void testCollisionTop()
    {
        auto charRect = m_pChar.bbox();
        // get the bounding box of the first colliding tile top from this character
        auto rightBbox = m_pMap.bboxTopOf(charRect);

        if (collide(charRect, rightBbox))
        {
            m_pChar.m_velocity.y = 0;
        }
    }

    void testCollisionBottom()
    {
        auto charRect = m_pChar.bbox();
        // get the bounding box of the first colliding tile bottom from this character
        auto rightBbox = m_pMap.bboxBottomOf(charRect);

        if (collide(charRect, rightBbox))
        {
            m_pChar.m_velocity.y = 0;
        }
    }

    /** 
     * Return whether there is a collision between two boxes or not 
     */
    static bool collide(scope ref const(SDL_Rect) rect1, scope ref const(SDL_Rect) rect2) pure 
    {
        if((rect2.x >= rect1.x + rect1.w)
	            || (rect2.x + rect2.w <= rect1.x) 
	            || (rect2.y >= rect1.y + rect1.h) 
	            || (rect2.y + rect2.h <= rect1.y))
            return false; 
        else
            return true;
    }


    Character* m_pChar;
    Map* m_pMap;
}


struct CharacterBuilder
{
    this(RC!SpriteSheet pSpriteSheet)
    {
        m_pSpriteSheet = pSpriteSheet;
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
 * Holds tracermation about a character in a top down view.
 */
struct Character 
{
    void draw(scope SDL_Renderer* pRenderer, SDL_Point viewPort)
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

    void update(ulong timeEllapsedMs)
    {
        m_input.update(timeEllapsedMs);
        m_collision.update(timeEllapsedMs);

        if (m_velocity.length > 0) {
            m_position += m_velocity.normalized * m_speed;
        }
    }

    SDL_Rect bbox() const 
    {
        return SDL_Rect(cast(int)m_position.x + 4, cast(int)m_position.y + 16, 24, 16);
    }

    // Animation data 
    Animation[4] m_walkingAnimations;
    Animation[4] m_standingAnimation;
    ulong m_stateDurationMs;
    ulong m_walkingAnimationDurationMs = 150;
    Orientation m_orientation;
    State m_state;

    // Position in map coordinates
    Vector2D!float m_position;

    // Velocity on axes
    Vector2D!float m_velocity;

    // Speed multiplier
    float m_speed = 1.0;

    // Component that react to user input
    InputComponent m_input;
    // Component that react to collisions 
    CollisionComponent m_collision;
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