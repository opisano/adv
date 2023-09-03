module game.dialog;

import bindbc.sdl;

import game.app: App, WINDOW_HEIGHT, WINDOW_WIDTH;
import game.basics;

import std.algorithm;
import std.exception;
import std.experimental.logger;
import std.format;
import std.range;
import std.stdio;
import std.uni;
import std.utf;

/// Normal text speed is one char every 60ms
enum TEXT_SPEED = 60UL;

/// Fast text speed is one char every 20ms
enum FAST_TEXT_SPEED = 20UL;


/** 
 * A Dialog view is used to display text when talking to 
 * NPCs into a frame.
 * 
 */
class Dialog : UserInterface
{
    /// Constructor
    this(App* app)
    {
        m_pApp = app;
        loadFont();
        m_textPeriod = TEXT_SPEED;
    }

    /// Destructor
    ~this()
    {
        if (m_pFont)
        {
            TTF_CloseFont(m_pFont);
        }
    }

    /** 
     * Loads text to display.
     * 
     * Before being displayed, text must be split into lines that fit 
     * this dialog frame width.
     * 
     * Params:
     *     text = Text to be displayed.
     */ 
    void setText(string text)
    {
        // First we (obviously) split on line breaks
        string[] lines;
        foreach (line; text.splitter("\n"))
        {
            // Then we wrap text that does not fit in the frame
            lines ~= splitText(line);
        }

        /* Since we display 3 lines simultaneously, create a range 
           to iterate on 3 lines at a time. */
        m_text = chunks(lines, 3);
    }

    override void draw(scope SDL_Renderer* pRenderer)
    {
        // Draw Text Frame 
        SDL_Rect rect = SDL_Rect(0, 0, WINDOW_WIDTH, WINDOW_WIDTH / 4);
        fillMenuRect(pRenderer, rect, SDL_Color(0x00, 0x00, 0xAA, 0xFF));
        drawMenuRect(pRenderer, rect, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF), 5);

        // Draw the current lines to be displayed

        // total character count drawn 
        size_t charsDrawn = 0;
        foreach (i, line; m_text.front)
        {
            // if we have drawn all the characters we had to, exit
            if (charsDrawn == m_cursor)
            {
                break;
            }

            //calculate the character count to draw for this line. 
            size_t prevLinesLength = m_text.front[0..i].map!(l => l.length).sum;
            size_t lengthToDraw = min(m_cursor - prevLinesLength, line.length);

            /* D-string to C-string conversion:
               Since SDL needs 0-terminated strings, copy line into a buffer on the stack */
            char[64] lineBuffer = 0;
            sformat(lineBuffer, "%s", line[0..lengthToDraw]);
            drawText(pRenderer, lineBuffer.ptr, 20, cast(int)(20 + i * 30), SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));
            charsDrawn += lengthToDraw;
        }
    }

    override void update(ulong timeElapsedMs) @nogc
    {
        // if enough time has passed, we can increment the number of characters to draw
        // (depends on text speed)
        m_totalElapsed += timeElapsedMs;
        while (m_totalElapsed >= m_textPeriod)
        {
            m_cursor = min(m_text.front[].map!(l => l.length).sum, m_cursor + 1);
            m_totalElapsed -= m_textPeriod;
        }
    }

    override void input()
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
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

    void doKeyDown(scope ref SDL_KeyboardEvent event)
    {
        if (event.repeat != 0)
        {
            return;
        }

        switch (event.keysym.sym)
        {
        case SDLK_SPACE:
            doAction();
            break;
        
        case SDLK_ESCAPE:
            m_pApp.popInterface();
            break;
            
        default:
            break;
        }
    }

    void doKeyUp(scope ref SDL_KeyboardEvent event)
    {
        if (event.repeat != 0)
        {
            return;
        }

        switch (event.keysym.sym)
        {
            // space was release, return to normal text speed
        case SDLK_SPACE:
            m_textPeriod = TEXT_SPEED;
            break;
            
        default:
            break;
        }   
    }

    void loadFont()
    {
        const(char)* filename = "./fonts/ManaspaceRegular.ttf";
        m_pFont = TTF_OpenFont(filename, 20);
        enforce(m_pFont != null, "Could not load file %s".format(filename));
    }

    void doAction()
    {
        // Space was pressed, fast text speed
        m_textPeriod = FAST_TEXT_SPEED;

        // If we cannot display more text
        if (m_cursor >= m_text.front[].map!(l => l.length).sum)
        {
            // Move to the next lines
            m_text.popFront();
            m_cursor = 0;

            // If there are no more lines to display
            if (m_text.empty)
            {
                m_pApp.popInterface();
            }
        }
    }

    void drawText(scope SDL_Renderer* pRenderer, scope const(char)* text, int x, int y, SDL_Color color) @nogc
    {
        SDL_Surface* pSurface = TTF_RenderText_Blended(m_pFont, text, color);
        scope (exit) SDL_FreeSurface(pSurface);

        SDL_Texture* pTexture = SDL_CreateTextureFromSurface(pRenderer, pSurface);
        scope (exit) SDL_DestroyTexture(pTexture);

        int width, height;
        SDL_QueryTexture(pTexture, null, null, &width, &height);

        SDL_Rect rect = SDL_Rect(x, y, width, height);
        SDL_RenderCopy(pRenderer, pTexture, null, &rect);
    }

    /** 
     * Divides a text to be displayed in lines that fit frame width.
     * 
     * Params:
     *     text = Text to be displayed, not split.
     * 
     * Returns:
     *     An array of string (one per line), that fit frame width
     */
    string[] splitText(string text)
    {
        string[] lines;
        string[] words = text.splitter!isWhite.array;
        immutable margin = 50; // margin in pixels on both sides of frame;
        immutable frameWidth = (WINDOW_WIDTH - 2 * margin);

        while (!words.empty)
        {
            // Process each word of current line
            size_t wordCount = 1;
            bool fitsIn = true;

            for (; fitsIn && wordCount < words.length; ++wordCount)
            {
                // Create a null terminated string of the first words 
                char[256] lineBuffer = 0;
                lineBuffer.sformat("%s", words.take(wordCount).joiner(" "));

                // Measure if the null terminated string fits in frame width 
                int w, h;
                TTF_SizeUTF8(m_pFont, lineBuffer.ptr, &w, &h);
                fitsIn = (w < frameWidth);
            }

            // if we left the for-loop because last word didn't fit in
            if (!fitsIn)
            {
                wordCount -= 1; // don't include last word
            }

            lines ~= words[0 .. wordCount].join(" ");
            words = words[wordCount .. $];
        }

        return lines;
    }

    App* m_pApp;
    TTF_Font* m_pFont;

    /// Iterator on lines to display in the dialog frame
    Chunks!(string[]) m_text;
    /// Store the current text cursor position
    size_t m_cursor;
    /// Stores time elapsed (for moving the cursor)
    ulong m_totalElapsed;
    /// Text speed in milliseconds per character
    ulong m_textPeriod;
}