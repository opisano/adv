module game.topdown;

import automem;
import bindbc.sdl;

import game.app: App, WINDOW_WIDTH, WINDOW_HEIGHT;
import game.basics;
import game.character;
import game.dialog;
import game.sprite;
import game.map;

import std.algorithm;
import std.experimental.logger;
import std.math;
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
                string text = candidates.front.interact(m_char);
                auto dlg = new Dialog(m_pApp);
                dlg.setText(text);
                m_pApp.pushInterface(dlg);
                m_input.setAction(false);
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
            SDL_Rect srcRect = m_map.tileSets[0][src];
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

