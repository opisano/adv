module game.character;


import app: WINDOW_HEIGHT, WINDOW_WIDTH;
import automem.ref_counted;
import derelict.sdl2.sdl;
import game.basics;
import game.sprite;
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
            m_pChar.hVelocity = m_pChar.vVelocity = 0;
        }
        else 
        {
            m_pChar.m_state = State.Walking;

            int hVelocity, vVelocity;
            if (m_directionsPressed[cast(size_t)Orientation.Top]) 
            {
                m_pChar.m_orientation = Orientation.Top;
                vVelocity += -1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Right])
            {
                m_pChar.m_orientation = Orientation.Right;
                hVelocity += 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Bottom])
            {
                m_pChar.m_orientation = Orientation.Bottom;
                vVelocity += 1;
            }

            if (m_directionsPressed[cast(size_t)Orientation.Left])
            {
                m_pChar.m_orientation = Orientation.Left;
                hVelocity += -1;
            }

            m_pChar.vVelocity = vVelocity;
            m_pChar.hVelocity = hVelocity;
        }

        // Update state duration
        if (m_pChar.m_state == oldState)
        {
            m_pChar.m_stateDurationMs += timeElapsedMs;
        }
        else 
        {
            infof("State changed to %s ", m_pChar.m_state);
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
 * Holds information about a character in a top down view.
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

        int screenX = x - viewPort.x;
        int screenY = y - viewPort.y;

        if ((screenX >= -32 && screenX < WINDOW_WIDTH)
            && (screenY >= -32 && screenY < WINDOW_HEIGHT))
        {
        
            // Determine where to draw on the screen
            SDL_Rect dstRect = SDL_Rect(screenX, screenY, srcRect.w, srcRect.h);
            SDL_RenderCopy(pRenderer, anim.texture, &srcRect, &dstRect);
        }
    }

    void update(ulong timeEllapsedMs)
    {
        m_input.update(timeEllapsedMs);

        x += hVelocity;
        y += vVelocity;
    }

    // Animation data 
    Animation[4] m_walkingAnimations;
    Animation[4] m_standingAnimation;
    ulong m_stateDurationMs;
    ulong m_walkingAnimationDurationMs = 150;
    Orientation m_orientation;
    State m_state;

    // Position in map coordinates
    int x;
    int y;

    // Velocity on axes
    int hVelocity;
    int vVelocity;

    // Component that change animation state
    InputComponent m_input;
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