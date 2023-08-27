module game.startmenu;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import game.app : App;
import game.basics;
import game.topdown;
import game.widgets.widget;
import std.exception;
import std.format;


final class StartMenu : UserInterface 
{
    this(App* app)
    {
        m_pApp = app;
        loadFont();
        createWidgets();
    }

    ~this()
    {
        if (m_pFont)
        {
            TTF_CloseFont(m_pFont);
        }
    }

    override void draw(SDL_Renderer* pRenderer)
    {
        auto rect = SDL_Rect(150, 180, 200, 140);
        fillMenuRect(pRenderer, rect, SDL_Color(0x00, 0x00, 0xAA, 0xFF));
        drawMenuRect(pRenderer, rect, SDL_Color(0xFF, 0xFF, 0xFF, 0xFF), 5);

        // Draw each widget
        foreach (i, widget; m_widgets[])
        {
            widget.draw(pRenderer, i == m_activeIndex);
        }
    }

    override void update(ulong timeElapsedMs)
    {
        // Do nothing
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
            
            default:
                break;
            }
        }
    }

private:

    void loadFont()
    {
        const(char)* filename = "./fonts/ManaspaceRegular.ttf";
        m_pFont = TTF_OpenFont(filename, 20);
        enforce(m_pFont != null, "Could not load file %s".format(filename));
    }

    void createWidgets()
    {
        m_widgets[0] = ActionWidgetBuilder("start")
                           .font(m_pFont)
                           .label("Start")
                           .position(200, 200)
                           .action(&onStart)
                           .build();

        m_widgets[1] = ActionWidgetBuilder("continue")
                           .font(m_pFont)
                           .label("Continue")
                           .position(200, 240)
                           .action(&onContinue)
                           .build();

        m_widgets[2] = ActionWidgetBuilder("exit")
                           .font(m_pFont)
                           .label("Exit")
                           .position(200, 280)
                           .action(&onExit)
                           .build();
    }

    void doKeyDown(scope ref SDL_KeyboardEvent event)
    {
        if (event.repeat != 0)
        {
            return;
        }

        switch (event.keysym.sym)
        {
        case SDLK_DOWN:
            m_activeIndex = (m_activeIndex + 1) % m_widgets.length;
            break;
        
        case SDLK_UP:
            m_activeIndex = m_activeIndex == 0 ? m_widgets.length - 1 : m_activeIndex - 1;
            break;
            
        default:
            m_widgets[m_activeIndex].onKeyDown(event);
            break;
        }
    }

    void onExit()
    {
        m_pApp.popInterface();
    }

    void onStart()
    {
        // Create 
        auto ui = new TopDown(m_pApp);
        ui.loadMap(m_pApp.renderer(), "./maps/01.map");

        // Remove start menu 
        m_pApp.popInterface();
        m_pApp.pushInterface(ui);

    }

    void onContinue()
    {

    }

    App* m_pApp;
    TTF_Font* m_pFont;
    Widget[3] m_widgets;
    size_t m_activeIndex;
}


