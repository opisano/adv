module game.combat.view;

import game.app;
import game.basics;
import game.combat.model;
import game.widgets.widget;

import bindbc.sdl;


final class CombatView: UserInterface
{
    this(App* app)
    {
        m_pApp = app;
    }

    override void draw(scope SDL_Renderer* pRenderer) 
    {
        drawBackground();
    }

    override void update(ulong timeElapsedMs)
    {
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

            case SDL_KEYUP:
                doKeyUp(event.key);
                break;

            case SDL_JOYBUTTONDOWN:
                doButtonDown(event.jbutton);
                break;

            case SDL_JOYBUTTONUP:
                doButtonUp(event.jbutton);
                break;
            
            default:
                break;
            }
        }
    }

private:

    void doKeyDown(scope ref SDL_KeyboardEvent event)
    {
    }

    void doKeyUp(scope ref SDL_KeyboardEvent event)
    {
    }

    void doButtonDown(scope ref SDL_JoyButtonEvent event)
    {
    }

    void doButtonUp(scope ref SDL_JoyButtonEvent event)
    {
    }

    void drawBackground()
    {
        SDL_Texture* pBackground = m_model.background;
        SDL_RenderCopy(m_pApp.renderer, pBackground, null, null);
    }

    App* m_pApp;
    CombatModel m_model;
}


/** 
 * 
 */
final class CombatMenu : UserInterface
{
    this(App* app, CombatModel* model)
    {
        m_pFont = app.font();
        m_pModel = model;
        createWidgets();
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

            case SDL_JOYBUTTONDOWN:
                doButtonDown(event.jbutton);
                break;

            default:
                break;
            }
        }
    }

    override void draw(scope SDL_Renderer* pRenderer)
    {
        SDL_Rect rect = SDL_Rect(0, (WINDOW_HEIGHT * 3) / 4, 
                                 WINDOW_WIDTH, WINDOW_HEIGHT / 4);
        fillMenuRect(pRenderer, rect, SDL_Color(0x00, 0x00, 0xAA, 0xFF));
        drawMenuRect(pRenderer, rect, SDL_Color(0xFF, 0xFF, 0xFF, 0xFf), 5);

        foreach (i, widget; m_widgets[])
        {
            widget.draw(pRenderer, i == m_activeIndex);
        }
    }

    override void update(ulong timeElapsedMs)
    {

    }

private: 

    void createWidgets()
    {
        auto yPos = WINDOW_HEIGHT - (WINDOW_WIDTH / 4);

        m_widgets[0] = ActionWidgetBuilder("attack")
                            .font(m_pFont)
                            .label("Attack")
                            .position( 20, yPos + 30 )
                            .action(&onAttack)
                            .build();

        m_widgets[1] = ActionWidgetBuilder("item")
                            .font(m_pFont)
                            .label("Item")
                            .position( 20, yPos + 60 )
                            .action(&onItem)
                            .build();

        m_widgets[2] = ActionWidgetBuilder("spell")
                            .font(m_pFont)
                            .label("Spell")
                            .position( 70, yPos + 30)
                            .action(&onSpell)
                            .build();
        
        m_widgets[3] = ActionWidgetBuilder("defend")
                            .font(m_pFont)
                            .label("Defend")
                            .position( 70, yPos + 60)
                            .action(&onDefend)
                            .build();

        m_widgets[4] = ActionWidgetBuilder("ability")
                            .font(m_pFont)
                            .label("Ability")
                            .position(120, yPos + 30)
                            .action(&onAbility)
                            .build();

        m_widgets[5] = ActionWidgetBuilder("flee")
                            .font(m_pFont)
                            .label("Flee")
                            .position(120, yPos + 60)
                            .action(&onFlee)
                            .build();
    }

    void doKeyDown(scope ref const SDL_KeyboardEvent event)
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

        case SDLK_RIGHT:
            m_activeIndex = (m_activeIndex + 2) % m_widgets.length;
            break;

        case SDLK_LEFT:
            m_activeIndex = m_activeIndex < 2 ? m_widgets.length - (m_activeIndex + 1) : m_activeIndex - 2;
            break;

        default:
            m_widgets[m_activeIndex].onKeyDown(event);
        }
    }

    void doButtonDown(scope ref const SDL_JoyButtonEvent event)
    {
        // TODO
    }

    void onAttack()
    {
    }

    void onItem()
    {
    }

    void onSpell()
    {
    }

    void onDefend()
    {
        CombatAction act = CombatAction(m_pModel.frontProtagonist, Action(DefendAction()), null);
        m_pModel.popFrontProtagonist();
        m_pModel.pushAction(act);
    }

    void onAbility()
    {
    }

    void onFlee()
    {

        CombatAction act = CombatAction(m_pModel.frontProtagonist, Action(FleeAction()), null);
        m_pModel.popFrontProtagonist();
        m_pModel.pushAction(act);
    }

    TTF_Font* m_pFont;
    CombatModel* m_pModel;
    Widget[6] m_widgets;
    size_t m_activeIndex;
}