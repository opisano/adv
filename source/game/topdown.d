module game.topdown;

import bindbc.sdl;

import game.app: App, WINDOW_WIDTH, WINDOW_HEIGHT;
import game.basics;
import game.dialog;
import game.sprite;
import game.map;

import math.vector2d;

import std.algorithm;
import std.experimental.logger;
import std.math;
import std.random;
import std.stdio;

/** 
 * A Top-down view such as the one in a typical RPG.
 */
final class TopDown : UserInterface
{
    this(App* app)
    {
        m_pApp = app;
        auto pSpriteSheet = SpriteSheetBuilder(app.renderer, "sprites/Actor1.png").width(12)
                                                                                  .height(8)
                                                                                  .spriteWidth(32)
                                                                                  .spriteHeight(32)
                                                                                  .build();

        m_char = createCharacter(pSpriteSheet, 0);
        m_input = m_char.m_input = new InputComponent(m_char);
        m_char.m_position.x = WINDOW_WIDTH / 2 - 16;
        m_char.m_position.y = WINDOW_HEIGHT / 2 - 16;

        m_pnj ~= createCharacter(pSpriteSheet, 5);
        m_pnj[$-1].m_position.x = 100;
        m_pnj[$-1].m_position.y = 50;
        m_pnj[$-1].m_orientation = Orientation.Bottom;
        m_pnj[$-1].m_input = new WalkingNPCComponent(m_pnj[$-1]);

        m_logger = new FileLogger(stdout);
        m_logger.logLevel = LogLevel.all;
    }

    /** 
     * Load the map
     * 
     * Params:
     *     pRenderer = The renderer (will store the tiles as textures).
     *     filename = The map file to load. 
     */
    void loadMap(SDL_Renderer* pRenderer, string filename)
    {
        m_map = game.map.loadMap(pRenderer, filename);
        m_char.m_collision = new MapCollisionComponent(m_char, &m_map);
        foreach (ref pnj; m_pnj)
        {
            pnj.m_collision = new MapCollisionComponent(pnj, &m_map);
        }
    }

    /** 
     * Draw the top-down view.
     */
    override void draw(scope SDL_Renderer* pRenderer)
    {
        drawMap(pRenderer);
        drawCharacters(pRenderer);
    }   

    override void update(ulong timeElapsedMs)
    {
        updateViewPort();
        m_char.update(timeElapsedMs);

        foreach (ref pnj; m_pnj)
        {
            pnj.update(timeElapsedMs);
        }

        // If user pressed the action button
        if (m_input.isAction)
        {
            // Search for a NPC that is near the hero, in the direction he's facing
            auto candidates = m_pnj[].filter!(chr => abs(m_char.distance(chr)) < 32 && m_char.facing(chr));
            if (!candidates.empty)
            {
                interact(candidates.front);
            }
        }
    }
 
    override void input()
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
            case SDL_QUIT:
                m_pApp.popInterface();
                break;

            case SDL_KEYDOWN:
                m_useJoystick = false;
                doKeyDown(event.key);
                break;
            
            case SDL_KEYUP:
                m_useJoystick = false;
                doKeyUp(event.key);
                break;

            case SDL_JOYBUTTONDOWN:
                doButtonDown(event.jbutton);
                m_useJoystick = true;
                break;

            case SDL_JOYBUTTONUP:
                doButtonUp(event.jbutton);
                m_useJoystick = true;
                break;

            case SDL_JOYAXISMOTION:
                m_useJoystick = true;
                break;
            
            default: 
                break;
            }
        }

        if (!m_useJoystick)
        {
            // Get current keystate
            int numKeys;
            const(ubyte)* pKeyboard = SDL_GetKeyboardState(&numKeys);
            const(ubyte)[] keyboard = pKeyboard[0 .. numKeys];

            m_input.setDirection(Orientation.Top, keyboard[SDL_SCANCODE_UP] != 0);
            m_input.setDirection(Orientation.Right, keyboard[SDL_SCANCODE_RIGHT] != 0);
            m_input.setDirection(Orientation.Bottom, keyboard[SDL_SCANCODE_DOWN] != 0);
            m_input.setDirection(Orientation.Left, keyboard[SDL_SCANCODE_LEFT] != 0);
        }
        else 
        {
            // Get current joystick axes state
            short axis;
            axis = SDL_GameControllerGetAxis(m_pApp.controller, SDL_CONTROLLER_AXIS_LEFTY);
            m_input.setDirection(Orientation.Top, axis < -5_000);
            m_input.setDirection(Orientation.Bottom, axis > 5_000);

            axis = SDL_GameControllerGetAxis(m_pApp.controller, SDL_CONTROLLER_AXIS_LEFTX);
            m_input.setDirection(Orientation.Left, axis < -5_000);
            m_input.setDirection(Orientation.Right, axis > 5_000);
        }
    }

private:
    void doKeyDown(scope ref SDL_KeyboardEvent keyEvent)
    {
        switch (keyEvent.keysym.scancode)
        {
        case SDL_SCANCODE_SPACE:
            m_input.setAction(true);
            break;

        default:
            break;
        }
    }

    void doKeyUp(scope ref SDL_KeyboardEvent keyEvent)
    {
        switch (keyEvent.keysym.scancode)
        {
        case SDL_SCANCODE_SPACE:
            m_input.setAction(false);
            break;
        
        default: 
            break;
        }
    }

    void doButtonDown(scope ref SDL_JoyButtonEvent event)
    {
        m_logger.tracef("Joystick button %s pressed", event.button);

        if (event.button == 0)
        {
            m_input.setAction(true);
        }
    }

    void doButtonUp(scope ref SDL_JoyButtonEvent event)
    {
        m_logger.tracef("Joystick button %s released", event.button);

        if (event.button == 0)
        {
            m_input.setAction(false);
        }
    }

    void updateViewPort()
    {
        m_viewport.x = clamp(cast(int)m_char.center.x - (WINDOW_WIDTH / 2),
                             0, 
                             m_map.pixelWidth - WINDOW_WIDTH);

        m_viewport.y = clamp(cast(int)m_char.center.y - (WINDOW_HEIGHT / 2),
                             0,
                             m_map.pixelHeight - WINDOW_HEIGHT);
    }

    void drawMap(scope SDL_Renderer* pRenderer)
    {
        foreach (i, ref layer; m_map.layers)
        {
            version (Collisions)
            {
                if (layer.name != "collision")
                {
                    drawMapLayer(pRenderer, layer);
                }
                else 
                {
                    drawMapCollisionLayer(pRenderer, layer);
                }
            }
            else 
            {
                if (layer.name != "collision")
                {
                    drawMapLayer(pRenderer, layer);
                }
            }
        }
    }

    void drawMapLayer(scope SDL_Renderer* pRenderer, scope ref Layer layer)
    {
        foreach (dst, src; layer.data)
        {
            TileSet* ts = m_map.tileSets[0];
            SDL_Rect srcRect = (*ts)[src];
            SDL_Rect dstRect = m_map[dst];
            dstRect.x -= m_viewport.x;
            dstRect.y -= m_viewport.y;

            SDL_RenderCopy(pRenderer, m_map.tileSets[0].pTexture, &srcRect, &dstRect);
        }
    }

    version (Collisions)
    {
        void drawMapCollisionLayer(scope SDL_Renderer* pRenderer, scope ref Layer layer)
        {
            foreach (dst, src; layer.data)
            {
                SDL_Rect srcRect = m_map.tileSets[$-1][src];
                SDL_Rect dstRect = m_map[dst];
                dstRect.x -= m_viewport.x;
                dstRect.y -= m_viewport.y;

                SDL_RenderCopy(pRenderer, m_map.tileSets[$-1].pTexture, &srcRect, &dstRect);
            }
        }
    }

    void drawCharacters(scope SDL_Renderer* pRenderer)
    {
        m_pnj[].sort!((a, b) => a.m_position.y < b.m_position.y);

        size_t i;
        for (i = 0; i < m_pnj.length; ++i)
        {
            if (m_pnj[i].m_position.y >= m_char.m_position.y)
            {
                break;
            }

            m_pnj[i].draw(pRenderer, m_viewport);
        }

        m_char.draw(pRenderer, m_viewport);

        for (; i < m_pnj.length; ++i)
        {
            m_pnj[i].draw(pRenderer, m_viewport);
        }
    }

    void interact(scope Character character)
    {
        string text = character.interact(m_char);
        auto dlg = new Dialog(m_pApp);
        dlg.setText(text);
        m_pApp.pushInterface(dlg);
        m_input.setAction(false);
    }

    Map m_map;
    App* m_pApp;
    /// Top Left corner of our camera
    SDL_Point m_viewport;

    InputComponent m_input;
    Character m_char;
    Character[] m_pnj;

    Logger m_logger;
    bool m_useJoystick;
}



/**
 * Abstract base class for all the entities 
 */
abstract class Entity : Updatable
{
    abstract void draw(scope SDL_Renderer* pRenderer, SDL_Point viewPort);

    /** 
     * Returns this entity bounding box.
     */
    abstract SDL_Rect bbox() const pure;

    /**
     * Returns this entity bounding box as if it were located at position "position"
     *
     * Params: 
     *     The position from which the bounding box will be calculated
     */
    abstract SDL_Rect bboxAtPosition(Vec2f position) const pure;

    /** 
     * Called when the Hero interacts with this entity
     * 
     * Params:
     *     The entity that interacts with this entity (the hero).
     */
    abstract string interact(scope const(Entity) );

    /** 
     * Returns the point at the center of character bounding box.
     */
    final Vec2f center() const pure
    {
        auto rect = bbox();
        return Vec2f(rect.x + rect.w / 2, 
                     rect.y + rect.h / 2); 
    }

    unittest 
    {
        class Stub : Entity
        {
            override void draw(scope SDL_Renderer* pRenderer, SDL_Point viewPort) { }
            override SDL_Rect bbox() const pure { return SDL_Rect( 0, 0, 32, 32); }
            override string interact(scope const(Entity)) { return ""; }
        }

        scope s1 = new Stub;
        auto c = s1.center;

        assert (c == Vec2f(16, 16));
    }

    /** 
     * Returns the distance to another Character
     */
    final float distance(scope const Entity other) const pure
    {
        Vec2f a = center();
        Vec2f b = other.center();
        Vec2f c = b - a;
        return c.length;
    }

    unittest 
    {
        class Stub1 : Entity
        {
            override void draw(scope SDL_Renderer* pRenderer, SDL_Point viewPort) { }
            override SDL_Rect bbox() const pure { return SDL_Rect( 0, 0, 32, 32); }
            override string interact(scope const(Entity)) { return ""; }
        }

        class Stub2 : Entity
        {
            override void draw(scope SDL_Renderer* pRenderer, SDL_Point viewPort) { }
            override SDL_Rect bbox() const pure { return SDL_Rect( 100, 0, 32, 32); }
            override string interact(scope const(Entity)) { return ""; }
        }

        scope Entity s1 = new Stub1;
        scope Entity s2 = new Stub2;

        float dist = s2.distance(s1);
        assert (dist == 100);        
    }
}



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
        // check collision with the next position of the character
        Vec2f nextXPosition = m_char.m_position + Vec2f(m_char.m_velocity.x, 0) * m_char.m_speed;
        Vec2f nextYPosition = m_char.m_position + Vec2f(0, m_char.m_velocity.y) * m_char.m_speed;

        SDL_Rect nextXPositionBbox = m_char.bboxAtPosition(nextXPosition);
        SDL_Rect nextYPositionBbox = m_char.bboxAtPosition(nextYPosition);

        // collision test depend on the direction the character is walking 

        if (m_char.m_velocity.x < 0)
        {
            testCollisionLeft(nextXPositionBbox);
        }
        else if (m_char.m_velocity.x > 0)
        {
            testCollisionRight(nextXPositionBbox);
        }

        if (m_char.m_velocity.y < 0)
        {
            testCollisionTop(nextYPositionBbox);
        }
        else if (m_char.m_velocity.y > 0)
        {
            testCollisionBottom(nextYPositionBbox);
        }
    }

private:

    void testCollisionLeft(SDL_Rect characterBbox)
    {
        // get the bounding box of the first colliding tile left from this character
        auto leftBbox = m_pMap.bboxLeftOf(characterBbox);

        if (collide(characterBbox, leftBbox))
        {
            m_char.m_velocity.x = 0;
        }
    }

    void testCollisionRight(SDL_Rect characterBbox)
    {
        // get the bounding box of the first colliding tile right from this character
        auto rightBbox = m_pMap.bboxRightOf(characterBbox);

        if (collide(characterBbox, rightBbox))
        {
            m_char.m_velocity.x = 0;
        }
    }

    void testCollisionTop(SDL_Rect characterBbox)
    {
        // get the bounding box of the first colliding tile top from this character
        auto topBbox = m_pMap.bboxTopOf(characterBbox);

        if (collide(characterBbox, topBbox))
        {
            m_char.m_velocity.y = 0;
        }
    }

    void testCollisionBottom(SDL_Rect characterBbox)
    {
        // get the bounding box of the first colliding tile bottom from this character
        auto bottomBbox = m_pMap.bboxBottomOf(characterBbox);

        if (collide(characterBbox, bottomBbox))
        {
            m_char.m_velocity.y = 0;
        }
    }

    Character m_char;
    Map* m_pMap;
}


struct CharacterBuilder
{
    this(SpriteSheet* pSpriteSheet)
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
    SpriteSheet* m_pSpriteSheet;
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

    override SDL_Rect bboxAtPosition(Vec2f position) const pure
    {
        return SDL_Rect(cast(int)position.x + 4, cast(int)position.y + 16, 24, 16);
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
    bool facing(scope const(Entity) other) const 
    {
        final switch (m_orientation)
        {
        case Orientation.Top:
            return center.y > other.center.y;
        case Orientation.Right:
            return center.x < other.center.x;
        case Orientation.Bottom:
            return center.y < other.center.y;
        case Orientation.Left:
            return center.x > other.center.x;
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

        return "Viens te battre !";
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

Character createCharacter(SpriteSheet* pSpriteSheet, int charIndex)
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
