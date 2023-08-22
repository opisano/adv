module game.topdown;

import app: App, WINDOW_WIDTH, WINDOW_HEIGHT;
import derelict.sdl2.sdl;

import game.basics;
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