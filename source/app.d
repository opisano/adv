import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import derelict.sdl2.image;

import std.algorithm;
import std.file;
import std.format;
import std.range;
import std.stdio;
import std.string;

import game.basics;
import game.startmenu;

void main(string[] args)
{
	auto app = App(args);
	app.loop();
}


// we want our game to run at 50 fps
enum MS_PER_UPDATE = 20L;

// window size in pixels
enum WINDOW_WIDTH = 512;
enum WINDOW_HEIGHT = 448;

/** 
 * An Application is a structure that contains a stack of UserInterface objects 
 * and a main loop.
 * 
 * The loop consists in three steps : input(), update() and display().
 * 
 * The application delegates in main loop steps to its UserInterface stack. 
 */
struct App 
{
    /** 
     * Initializes the application and loads resources.
     * 
     * Params: 
     *     args = Command-line arguments
     */
    this(string[] args)
    {
        initializeSDL;
        createWindow;
        createStartMenu;
    }

    /** 
     * Frees loaded resources
     */
    ~this()
    {
        if (m_pRenderer != null)
        {
            SDL_DestroyRenderer(m_pRenderer);
            m_pRenderer = null;
        }

        if (m_pWindow != null)
        {
            SDL_DestroyWindow(m_pWindow);
            m_pWindow = null;
        }
    }

    /** 
     * Main loop
     */
    void loop()
    {
        m_active = true;
        ulong previous = SDL_GetTicks();

        while (m_active)
        {
            ulong current = SDL_GetTicks();
            ulong elapsed = current - previous;
            doInput;
            doUpdate(elapsed);
            doDisplay;
            previous = current;

            // determine how much time to sleep until next frame
            long toSleepMs = MS_PER_UPDATE - elapsed;
            if (toSleepMs > 0)
            {
                SDL_Delay(cast(uint) toSleepMs);
            }
        }
    }

    /** 
     * Remove the UserInterface at the top of the stack.
     */
    void popInterface()
    {
        m_uis.popBack();
    }

    /** 
     * Put some UserInterface on the top of the stack.
     */
    void pushInterface(UserInterface intf)
    {
        m_uis ~= intf;
    }

    /** 
     * Access the renderer component.
     */
    SDL_Renderer* renderer()
    {
        return m_pRenderer;
    }

private:

	/** 
     * SDL-related initialization
     */
    void initializeSDL()
    {
        DerelictSDL2.load;
        DerelictSDL2ttf.load;
        DerelictSDL2Image.load;

        if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0)
        {
            throw new Exception("Could not initialize SDL: %s".format(SDL_GetError));
        }

        if (TTF_Init() < 0)
        {
	        throw new Exception("Could not initialize SDL_TTF: %s".format(TTF_GetError));
        }

        if (IMG_Init(IMG_INIT_PNG) < 0)
        {
            throw new Exception("Could not initialize SDL_IMG: %s".format(IMG_GetError));
        }
    }

    /** 
     * Create window and graphical resources
     */
    void createWindow()
    {
        const winFlags = SDL_WINDOW_RESIZABLE;
        m_pWindow = SDL_CreateWindow("Adventure", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 
                                     WINDOW_WIDTH, WINDOW_HEIGHT, winFlags);
        if (!m_pWindow)
        {
            throw new Exception("Could not create Window: %s\n".format(SDL_GetError));
        }

        const rendererFlags = SDL_RENDERER_ACCELERATED;
        m_pRenderer = SDL_CreateRenderer(m_pWindow, -1, rendererFlags);
        if (!m_pRenderer)
        {
            throw new Exception("Could not create Renderer: %s\n".format(SDL_GetError));
        }
    }

    /** 
     * Create the Start menu and put it at the top of the stack
     */
    void createStartMenu()
    {
        pushInterface(new StartMenu(&this));
    }

    /** 
     * The main loop display step, performs the rendering.
     */
	void doDisplay()
	{
		SDL_RenderClear(m_pRenderer);

        // Render the whole UI stack
        foreach (ui; m_uis)
        {
            ui.draw(m_pRenderer);
        }

		SDL_RenderPresent(m_pRenderer);
	}

    /** 
     * The main loop update step, updates the world state.
     */
    void doUpdate(ulong timeElapsedMs)
    {
        if (m_uis.length)
            m_uis[$-1].update(timeElapsedMs);
    }

    /** 
     * The main loop input step, reacts to player input.
     */
	void doInput()
	{
        if (m_uis.length)
        {
            m_uis[$-1].input();
        }
        else // if there is no more UI on the stack, exit main loop
        {
            m_active = false;
        }
	}

    /// The user interface stack
    UserInterface[] m_uis;
    /// The SDL component that talks to the GPU
	SDL_Renderer* m_pRenderer;
    /// The Application window
	SDL_Window* m_pWindow;
    /// Main loop condition, exit application when set to false
	bool m_active;
}


