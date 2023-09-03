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


enum TEXT_SPEED = 60UL;
enum FAST_TEXT_SPEED = 20UL;


/** 
 * A Top-down view such as the one in a typical RPG.
 */
class Dialog : UserInterface
{
    this(App* app)
    {
        m_pApp = app;
        loadFont();
        m_textPeriod = TEXT_SPEED;
        m_logger = new FileLogger(stdout);
        m_logger.logLevel = LogLevel.trace;
    }

    ~this()
    {
        if (m_pFont)
        {
            TTF_CloseFont(m_pFont);
        }
    }

    void setText(string text)
    {
        string[] lines;
        foreach (line; text.splitter("\n"))
        {
            lines ~= splitText(line);
        }
        m_text = chunks(lines, 3);
    }

    override void draw(scope SDL_Renderer* pRenderer)
    {
        // Draw Text Frame 
        SDL_Rect rect = SDL_Rect(0, 0, WINDOW_WIDTH, WINDOW_WIDTH / 4);
        fillMenuRect(pRenderer, rect, SDL_Color(0x00, 0x00, 0xAA, 0xFF));
        drawMenuRect(pRenderer, rect, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF), 5);

        // Draw the current lines
        size_t charsDrawn = 0;

        foreach (i, line; m_text.front)
        {
            if (charsDrawn == m_len)
            {
                break;
            }

            //calculate the character count to draw for this line. 
            ptrdiff_t prevLinesLength = m_text.front[0..i].map!(l => l.length).sum;
            ptrdiff_t lengthToDraw = min(max(m_len - prevLinesLength, 0), line.length);

            char[256] lineBuffer = 0;
            sformat(lineBuffer, "%s", line[0..lengthToDraw]);
            drawText(pRenderer, lineBuffer.ptr, 20, cast(int)(20 + i * 30), SDL_Color(0xFF, 0xFF, 0xFF, 0xFF));
            charsDrawn += lengthToDraw;
        }
    }

    override void update(ulong timeElapsedMs)
    {
        //if (!m_blocked)
        //{
            m_totalElapsed += timeElapsedMs;
            while (m_totalElapsed >= m_textPeriod)
            {
                m_len = min(m_text.front[].map!(l => l.length).sum, m_len + 1);
                m_totalElapsed -= m_textPeriod;
            }
        //}
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
        m_textPeriod = FAST_TEXT_SPEED;
        if (m_len >= m_text.front[].map!(l => l.length).sum)
        {
            m_text.popFront();
            m_len = 0;
            if (m_text.empty)
            {
                m_pApp.popInterface();
            }
        }
    }

    void drawText(scope SDL_Renderer* pRenderer, scope const(char)* text, int x, int y, SDL_Color color)
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
    Chunks!(string[]) m_text;
    ptrdiff_t m_len;


    ulong m_totalElapsed;
    /// Text speed in milliseconds per character
    ulong m_textPeriod;
    Logger m_logger;
}