module game.topdown;

import app: App, WINDOW_WIDTH, WINDOW_HEIGHT;
import automem;
import derelict.sdl2.sdl;

import game.basics;
import game.sprite;
import game.map;

import std.algorithm.comparison: min, max;
import std.experimental.logger;


/** 
 * A Top-down view such as the one in a typical RPG.
 */
final class TopDown : UserInterface
{
    this(App* app)
    {
        m_pApp = app;
        m_input = new InputComponent(this);
        auto pSpriteSheet = SpriteSheetBuilder(app.renderer, "sprites/Actor1.png").width(12)
                                                                                  .height(8)
                                                                                  .spriteWidth(32)
                                                                                  .spriteHeight(32)
                                                                                  .build();

        m_char = CharacterBuilder(pSpriteSheet).standing(37, 25, 1, 13)
                                               .walkingTop([36, 37, 38, 37])
                                               .walkingRight([24, 25, 26, 25])
                                               .walkingBottom([0, 1, 2, 1])
                                               .walkingLeft([12, 13, 14, 13])
                                               .build();

        m_char.x = 50;
        m_char.y = 50;
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
    }

    /** 
     * Draw the top-down view.
     */
    override void draw(scope SDL_Renderer* pRenderer)
    {
        drawMap(pRenderer);
        drawChar(pRenderer);
    }   

    override void update(ulong timeElapsedMs)
    {
        m_input.update(timeElapsedMs);
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
                doKeyDown(event.key);
                break;
            
            case SDL_KEYUP:
                doKeyUp(event.key);
                break;
            
            default: 
                break;
            }
        }
    }

private:

    void drawMap(scope SDL_Renderer* pRenderer)
    {
        foreach (i, ref layer; m_map.layers)
        {
            foreach (dst, src; layer.data)
            {
                SDL_Rect srcRect = m_map.tileSets[0][src-1];
                SDL_Rect dstRect = m_map[dst];
                dstRect.x += m_viewport.x;
                dstRect.y += m_viewport.y;

                SDL_RenderCopy(pRenderer, m_map.tileSets[0].pTexture, &srcRect, &dstRect);
            }
        }
    }

    void drawChar(scope SDL_Renderer* pRenderer)
    {
        m_char.draw(pRenderer, m_viewport);
    }

    void doKeyDown(scope ref SDL_KeyboardEvent event)
    {
        if (event.repeat > 0)
            return;

        switch (event.keysym.sym)
        {
            case SDLK_UP:
                info("Up pressed");
                m_input.setDirectionPressed(Orientation.Top);
                break;
            
            case SDLK_RIGHT:
                info("Right pressed");
                m_input.setDirectionPressed(Orientation.Right);
                break;

            case SDLK_DOWN:
                info("Down pressed"); 
                m_input.setDirectionPressed(Orientation.Bottom);
                break;
            
            case SDLK_LEFT:
                info("Left pressed");
                m_input.setDirectionPressed(Orientation.Left);
                break;

            default:
                break;
        }
    }

    void doKeyUp(scope ref SDL_KeyboardEvent event)
    {
        if (event.repeat > 0)
            return;

        switch (event.keysym.sym)
        {
            case SDLK_UP:
                info("Up released");
                m_input.setDirectionReleased(Orientation.Top);
                break;
            
            case SDLK_RIGHT:
                info("Right released");
                m_input.setDirectionReleased(Orientation.Right);
                break;

            case SDLK_DOWN: 
                info("Down released");
                m_input.setDirectionReleased(Orientation.Bottom);
                break;
            
            case SDLK_LEFT:
                info("Left released");
                m_input.setDirectionReleased(Orientation.Left);
                break;

            default:
                break;
        }
    }

    Map m_map;
    App* m_pApp;
    /// Top Left corner of our camera
    SDL_Point m_viewport;

    InputComponent m_input;
    Character m_char;
}


/** 
 * Direction a character is facing. 
 */
enum Orientation
{
    Top,
    Right,
    Bottom,
    Left
}

enum State 
{
    Standing,
    Walking
}


/** 
 * An updatable which handles input.
 */
class InputComponent : Updatable
{
    this(TopDown topDown)
    {
        m_topDown = topDown;
    }

    override void update(ulong timeElapsedMs)
    {
        enum VIEWPORT_SPEED = 1;
        const distance = timeElapsedMs * VIEWPORT_SPEED;

        if (m_directionsPressed[cast(size_t)Orientation.Top])
        {
            m_topDown.m_viewport.y = cast(int) (m_topDown.m_viewport.y + distance);
        }

        if (m_directionsPressed[cast(size_t)Orientation.Right])
        {
            m_topDown.m_viewport.x = cast(int) (m_topDown.m_viewport.x - distance);
        }

        if (m_directionsPressed[cast(size_t)Orientation.Bottom])
        {
            m_topDown.m_viewport.y = cast(int) (m_topDown.m_viewport.y - distance);
        }

        if (m_directionsPressed[cast(size_t)Orientation.Left])
        {
            m_topDown.m_viewport.x = cast(int) (m_topDown.m_viewport.x + distance);
        }
    }

    void setDirectionPressed(Orientation orientation)
    {
        size_t index = cast(size_t) orientation;
        m_directionsPressed[index] = true;
    }

    void setDirectionReleased(Orientation orientation)
    {
        size_t index = cast(size_t) orientation;
        m_directionsPressed[index] = false;
    }

    void setActionPressed()
    {
        m_actionPressed = true;
    }

    void setActionReleased()
    {
        m_actionPressed = false;
    }

private:
    TopDown m_topDown;
    bool[4] m_directionsPressed;
    bool m_actionPressed;
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
        final switch (m_state)
        {
        case State.Standing:
            anim = &m_standingAnimation[cast(int)m_orientation];
            break;

        case State.Walking:
            anim = &m_walkingAnimations[cast(int)m_orientation];
            break;
        }

        SDL_Rect srcRect = anim.front;

        // Determine where to draw on the screen
        SDL_Rect dstRect = SDL_Rect(x + viewPort.x, y + viewPort.y, srcRect.w, srcRect.h);
        
        SDL_RenderCopy(pRenderer, anim.texture, &srcRect, &dstRect);
    }


    // Animation data 
    Animation[4] m_walkingAnimations;
    Animation[4] m_standingAnimation;
    Orientation m_orientation;
    State m_state;

    // Position in map coordinates
    int x;
    int y;
}