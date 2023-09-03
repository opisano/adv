module game.basics;

import bindbc.sdl;

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
 * Something to be drawn on the screen
 */
interface Drawable 
{
    void draw(scope SDL_Renderer* pRenderer);
}

/** 
 * Something that needs to be updated over time.
 */
interface Updatable 
{
    /** 
     * Update the current object
     * 
     * Params:
     *     timeElapsedMs = Time elapsed since start (in milliseconds)
     */
    void update(ulong timeElapsedMs);
}

/** 
 * A game user interface 
 */
interface UserInterface : Drawable, Updatable
{
    /** 
     * Handles user input.
     */
    void input();
}

/** 
 * Draw a rectangle to be used in menus.
 * 
 * Params:
 *     pRenderer = A pointer to the SDL renderer to draw to.
 *     rect      = Coordinates of the rectangle to draw
 *     color     = Color to draw
 *     thickness = thickness in pixels
 */
void drawMenuRect(scope SDL_Renderer* pRenderer, scope ref const(SDL_Rect) rect, SDL_Color color, int thickness=5) @nogc
{
    // Save render color, in order to restore it later
    ubyte old_r, old_g, old_b, old_a;
    SDL_GetRenderDrawColor(pRenderer, &old_r, &old_g, &old_b, &old_a);
    scope(exit) SDL_SetRenderDrawColor(pRenderer, old_r, old_g, old_b, old_a);
    
    // Apply the color
    SDL_SetRenderDrawColor(pRenderer, color.r, color.g, color.b, color.a);

    // Fill four rects (one for each side our rectangle)
    SDL_Rect[4] rects = void;
    rects[0] = SDL_Rect(rect.x, rect.y, rect.x + rect.w - rect.x, thickness);
    rects[1] = SDL_Rect(rect.x, rect.y, thickness, rect.y + rect.h - rect.y);
    rects[2] = SDL_Rect(rect.x + rect.w - thickness, rect.y, thickness, rect.y + rect.h - rect.y);
    rects[3] = SDL_Rect(rect.x, rect.y + rect.h - thickness, rect.x + rect.w - rect.x, thickness);

    SDL_RenderFillRects(pRenderer, rects.ptr, rects.length);
}

/** 
 * Fill a rectangle, for menu background.
 * 
 * Params:
 *     pRenderer = A pointer to the SDL renderer to draw to.
 *     rect      = Coordinates of the rectangle to draw
 *     color     = Color to draw
 */
void fillMenuRect(scope SDL_Renderer* pRenderer, scope ref const(SDL_Rect) rect, SDL_Color color) @nogc
{
    // Save render color, in order to restore it later
    ubyte old_r, old_g, old_b, old_a;
    SDL_GetRenderDrawColor(pRenderer, &old_r, &old_g, &old_b, &old_a);
    scope(exit) SDL_SetRenderDrawColor(pRenderer, old_r, old_g, old_b, old_a);

    // Apply the color
    SDL_SetRenderDrawColor(pRenderer, color.r, color.g, color.b, color.a);

    SDL_RenderFillRect(pRenderer, &rect);
} 

/** 
    * Return whether there is a collision between two boxes or not 
    */
bool collide(scope ref const(SDL_Rect) rect1, scope ref const(SDL_Rect) rect2) pure nothrow @nogc
{
    if((rect2.x >= rect1.x + rect1.w)
            || (rect2.x + rect2.w <= rect1.x) 
            || (rect2.y >= rect1.y + rect1.h) 
            || (rect2.y + rect2.h <= rect1.y))
        return false; 
    else
        return true;
}


