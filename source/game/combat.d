module game.combat;

import bindbc.sdl;
import game.app: App, WINDOW_WIDTH, WINDOW_HEIGHT;
import game.basics;
import math.vector2d;
import std.algorithm.comparison: min;
import std.string;

struct CombatBuilder 
{
    this(App* app)
    {
        m_combat = new Combat(app);
    }

    ref CombatBuilder background(SDL_Renderer* pRenderer, string filename) return 
    {
        m_combat.m_pBackground = IMG_LoadTexture(pRenderer, toStringz(filename));

        if (!m_combat.m_pBackground)
        {
            throw new Exception("Cannot load background %s: %s".format(filename, IMG_GetError()));
        }

        return this;
    }

    ref CombatBuilder addStats(EntityStats stats) return
    {
        m_combat.m_group ~= stats;

        return this;
    }

    Combat build()
    {
        return m_combat;
    }

private:
    Combat m_combat;
}

class Combat : UserInterface
{
    this(App* app)
    {
        m_pApp = app;
    }

    override void draw(scope SDL_Renderer* pRenderer)
    {
        drawBackground(pRenderer);
        drawOpponents(pRenderer);
        drawGroupInfo(pRenderer);
    }

    override void input()
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
            case SDL_QUIT:
                while (m_pApp.popInterface()) 
                {
                }
                break;

            case SDL_KEYDOWN:
                doKeyDown(event.key);
                break;
            
            default:
                break;
            }
        }
    }

    override void update(ulong timeElapsedMs)
    {

    }

private:

    void doKeyDown(ref SDL_KeyboardEvent event)
    {
        if (event.repeat != 0)
        {
            return;
        }

        switch (event.keysym.sym)
        {        
        case SDLK_ESCAPE:
            m_pApp.popInterface();
            break;
            
        default:
            break;
        }
    }

    void drawBackground(scope SDL_Renderer* pRenderer)
    {
        if (m_pBackground)
        {
            SDL_RenderCopy(pRenderer, m_pBackground, null, null);
        }
    }

    void drawOpponents(scope SDL_Renderer* pRenderer)
    {
        foreach (pOpponent; m_opponents)
        {
            pOpponent.draw(pRenderer);
        }
    }

    void drawGroupInfo(scope SDL_Renderer* pRenderer)
    {
        immutable dlgWidth = WINDOW_WIDTH / 4;
        immutable dlgHeight = WINDOW_HEIGHT / 4;
        char[32] linebuffer;

        foreach (i, ref stats; m_group)
        {
            auto rect = SDL_Rect(cast(int)(i * dlgWidth), 0, dlgWidth, dlgHeight );
            fillMenuRect(pRenderer, rect, SDL_Color(0x00, 0x00, 0xAA, 0xFF));
            drawMenuRect(pRenderer, rect, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF), 5);

            // draw name 
            linebuffer[] = 0;
            sformat(linebuffer, "%s", stats.name[0..min(31, stats.name.length)]);
            drawText(pRenderer, linebuffer.ptr, rect.x + 20, 10, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));

            // draw hp
            linebuffer[] = 0;
            sformat(linebuffer, "HP: %d", stats.hp);
            drawText(pRenderer, linebuffer.ptr, rect.x + 20, 40, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));

            // draw mp
            linebuffer[] = 0;
            sformat(linebuffer, "MP: %d", stats.mp);
            drawText(pRenderer, linebuffer.ptr, rect.x + 20, 70, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));
        }
    }

    void drawText(scope SDL_Renderer* pRenderer, scope const(char)* text, int x, int y , SDL_Color color) @nogc
    {
        SDL_Surface* pSurface = TTF_RenderUTF8_Blended(m_pApp.font, text, color);
        scope (exit) SDL_FreeSurface(pSurface);

        SDL_Texture* pTexture = SDL_CreateTextureFromSurface(pRenderer, pSurface);
        scope (exit) SDL_DestroyTexture(pTexture);

        int width, height;
        SDL_QueryTexture(pTexture, null, null, &width, &height);

        SDL_Rect rect = SDL_Rect(x, y, width, height);
        SDL_RenderCopy(pRenderer, pTexture, null, &rect);
    }

    App* m_pApp;

    SDL_Texture* m_pBackground;

    Opponent*[] m_opponents;

    EntityStats[] m_group;
}


/** 
 * Stores information about an opponent to draw
 */
struct Opponent
{
    this(scope SDL_Renderer* pRenderer, string filename)
    {
        m_pSprite = IMG_LoadTexture(pRenderer, toStringz(filename));
        if (m_pSprite == null)
        {
            throw new Exception("Cannot load texture " ~ filename);
        }

        SDL_QueryTexture(m_pSprite, null, null, &m_spriteWidth, &m_spriteHeight);
    }

    /** 
     * Disable copying
     */
    @disable this(ref Opponent);

    /** 
     * Free resources 
     */
    ~this()
    {
        SDL_DestroyTexture(m_pSprite);
    }

    /**
     * Draw this opponent
     */
    void draw(scope SDL_Renderer* pRenderer)
    {
        Vec2f pos = m_point + m_offset;
        auto srcRect = SDL_Rect(0, 0, m_spriteWidth, m_spriteHeight);
        auto dstRect = SDL_Rect(cast(int)pos.x, cast(int)pos.y, m_spriteWidth, m_spriteHeight);
        SDL_RenderCopy(pRenderer, m_pSprite, &srcRect, &dstRect);
    }

private:
    /// Opponent sprite
    SDL_Texture* m_pSprite;
    /// Base coordinates at which to draw this opponent
    Vec2f m_point;
    /// Offset from point (for animation)
    Vec2f m_offset;
    /// Sprite width 
    int m_spriteWidth;
    /// Sprite height
    int m_spriteHeight;
}