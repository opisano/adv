module game.topdown;

import app: App, WINDOW_WIDTH, WINDOW_HEIGHT;
import automem;
import derelict.sdl2.sdl;

import game.basics;
import game.character;
import game.sprite;
import game.map;

import std.experimental.logger;


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
        m_input = m_char.m_input = new InputComponent(&m_char);
        m_char.x = WINDOW_WIDTH / 2 - 16;
        m_char.y = WINDOW_HEIGHT / 2 - 16;

        m_pnj = createCharacter(pSpriteSheet, 5);
        m_pnj.x = 100;
        m_pnj.y = 50;
        m_pnj.m_orientation = Orientation.Bottom;
        m_pnj.m_input = new WalkingNPCComponent(&m_pnj);
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
        updateViewPort();
        m_char.update(timeElapsedMs);
        m_pnj.update(timeElapsedMs);
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
    void updateViewPort()
    {
        m_viewport.x = m_char.x - (WINDOW_WIDTH / 2);
        m_viewport.y = m_char.y - (WINDOW_HEIGHT / 2);
    }

    void drawMap(scope SDL_Renderer* pRenderer)
    {
        foreach (i, ref layer; m_map.layers)
        {
            drawMapLayer(pRenderer, layer);
        }
    }

    void drawMapLayer(scope SDL_Renderer* pRenderer, scope ref Layer layer)
    {
        foreach (dst, src; layer.data)
        {
            SDL_Rect srcRect = m_map.tileSets[0][src-1];
            SDL_Rect dstRect = m_map[dst];
            dstRect.x -= m_viewport.x;
            dstRect.y -= m_viewport.y;

            SDL_RenderCopy(pRenderer, m_map.tileSets[0].pTexture, &srcRect, &dstRect);
        }
    }

    void drawChar(scope SDL_Renderer* pRenderer)
    {
        m_char.draw(pRenderer, m_viewport);
        m_pnj.draw(pRenderer, m_viewport);
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
    Character m_pnj;
}

