module game.sprite;

import automem.ref_counted;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.format;
import std.range;
import std.string;


/** 
 * Builder pattern for a sprite sheet.
 */
struct SpriteSheetBuilder
{
    this(scope SDL_Renderer* pRenderer, string filename)
    {
        m_pSpriteSheet = RC!SpriteSheet(pRenderer, filename);
    }

    ref SpriteSheetBuilder width(int w) return 
    {
        m_pSpriteSheet.width = w;
        return this;
    }

    ref SpriteSheetBuilder height(int h) return 
    {
        m_pSpriteSheet.height = h;
        return this;
    }

    ref SpriteSheetBuilder spriteWidth(int tw) return 
    {
        m_pSpriteSheet.spriteWidth = tw;
        return this;
    }

    ref SpriteSheetBuilder spriteHeight(int th) return 
    {
        m_pSpriteSheet.spriteHeight = th;
        return this;
    }

    RC!SpriteSheet build()
    {
        return m_pSpriteSheet;
    }

private:
    RC!SpriteSheet m_pSpriteSheet;
}


/** 
 * Holds a Texture for Sprite
 */
struct SpriteSheet
{
    this(scope SDL_Renderer* pRenderer, string filename)
    {
        m_pTexture = IMG_LoadTexture(pRenderer, toStringz(filename));

        if (!m_pTexture)
        {
            throw new Exception("Cannot load spritesheet %s: %s".format(filename, IMG_GetError()));
        }
    }

    /** 
     * Prevent Copying
     */
    @disable this(ref SpriteSheet);

    /** 
     * Free resources 
     */
    ~this()
    {
        if (m_pTexture)
        {
            SDL_DestroyTexture(m_pTexture);
            m_pTexture = null;
        }
    }

    /** 
     * Get the Rect of the sprite at the provided index 
     * 
     * Params:
     *     index = The index of the sprite to look at 
     * 
     * Returns: 
     *     The Rect of the sprite for the provided index
     */
    SDL_Rect opIndex(int index) const pure nothrow
    {
        immutable int row = index / width;
        immutable int col = index % width;
        immutable int x = col * spriteWidth;
        immutable int y = row * spriteHeight;

        return SDL_Rect(x, y, spriteWidth, spriteHeight);
    }

    /// Width of image in number of sprites 
    int width;

    /// Height of image in number of sprites 
    int height;

    /// Width of a sprite in pixels
    int spriteWidth;

    /// Height of a sprite in pixels
    int spriteHeight;

private:
    SDL_Texture* m_pTexture;
}

/** 
 * An animation associates a SpriteSheet to a sequence of sprite indices.
 */
struct Animation 
{
    /** 
     * Constructs an Animation 
     * 
     * Params:
     *     pSpriteSheet = the sprite sheet 
     *     indices = an array of size_t indices.
     */
    this(RC!SpriteSheet pSpriteSheet, int[] indices)
    {
        m_spriteSheet = pSpriteSheet;

        // Construct an infinite range (iterator) over indices.
        m_indices = cycle(indices);
    }

    /// Animation is infinite (repeat itself)
    enum bool empty = false;

    /// Get Rect of current animation frame
    SDL_Rect front() const
    {
        return (*m_spriteSheet)[m_indices.front];
    }

    /// skip to next frame
    void popFront()
    {
        m_indices.popFront();
    }

    SDL_Texture* texture()
    {
        return m_spriteSheet.m_pTexture;
    }

private:
    RC!SpriteSheet m_spriteSheet;
    Cycle!(int[]) m_indices;
}