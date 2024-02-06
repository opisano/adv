module game.widgets.widget;

import bindbc.sdl;
import std.exception;
import std.string;


static this()
{
    Widget.s_activeColor = SDL_Color(255, 255, 255, 255);
    Widget.s_normalColor = SDL_Color(255, 255, 0, 255);
}

/** 
 * Abstract base class for all the widgets 
 */
abstract class Widget
{
    this(string name)
    {
        m_name = name;
    }

    /** 
     * Draw this widget 
     */
    abstract void draw(scope SDL_Renderer* pRenderer, bool active);

    abstract void onKeyDown(ref const SDL_KeyboardEvent event);

protected:

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

    string m_name;
    TTF_Font* m_pFont;
    int m_x;
    int m_y;

private:
    static SDL_Color s_activeColor;
    static SDL_Color s_normalColor;
}

/** 
 * A widget with an action, similar to a button or a menu item.
 */
final class ActionWidget : Widget
{
    this(string name)
    {
        super(name);
    }

    override void draw(scope SDL_Renderer* pRenderer, bool active)
    {        
        SDL_Color color = void;

        if (active)
        {
            color = s_activeColor;
            drawText(pRenderer ,">", m_x - 40, m_y, color);
        }
        else 
        {
            color = s_normalColor;
        }

        drawText(pRenderer, m_label, m_x, m_y, color);
    }

    override void onKeyDown(ref const SDL_KeyboardEvent event)
    {
        if (event.keysym.sym == SDLK_RETURN)
        {
            action();
        }
    }

    void action()
    {
        if (m_action)
        {
            m_action();
        }
    }

private:
    const(char)* m_label;
    void delegate() m_action;
}


struct Choice 
{
    string name;
    string label;
}

/** 
 * A widget that can be used to select an option between several
 */
final class ChoiceWidget : Widget
{
    this(string name)
    {
        super(name);
    }

    override void draw(scope SDL_Renderer* pRenderer, bool active)
    {
        if (m_choices.length == 0)
        {
            return;
        }

        SDL_Color color = void;

        if (active)
        {
            color = s_activeColor;
        }
        else 
        {
            color = s_normalColor;
        }

        char[32] buffer = '\0';
        sformat(buffer, "%s", m_choices[m_activeIndex].label);
        buffer[31] = '\0';

        drawText(pRenderer, "= ", m_x - 20, m_y, color);
        drawText(pRenderer, buffer.ptr, m_x, m_y, color);
    }

    override void onKeyDown(ref const SDL_KeyboardEvent event)
    {
        switch (event.keysym.sym)
        {
        case SDLK_LEFT:
            prev();
            break;
        
        case SDLK_RIGHT:
            next();
            break;

        default:
            break;
        }
    }
    

    Choice selected() const 
    {
        return m_choices[m_activeIndex];
    }

private:

    void next()
    {
        m_activeIndex = (m_activeIndex + 1) % m_choices.length;
    }

    void prev()
    {
        ptrdiff_t len = m_choices.length;
        m_activeIndex = m_activeIndex > 0 ? m_activeIndex - 1 : len - 1;
    }

    Choice[] m_choices;
    size_t m_activeIndex;
}


struct ActionWidgetBuilder
{
    this(string name)
    {
        m_widget = new ActionWidget(name);
    }

    ref ActionWidgetBuilder label(string text) return
    {
        m_widget.m_label = text.toStringz;
        return this;
    }

    ref ActionWidgetBuilder font(TTF_Font* pFont) return
    {
        m_widget.m_pFont = pFont;
        return this;
    }

    ref ActionWidgetBuilder position(int x, int y) return
    {
        m_widget.m_x = x;
        m_widget.m_y = y;
        return this;
    }

    ref ActionWidgetBuilder action(void delegate() act) return 
    {
        m_widget.m_action = act;
        return this;
    }

    ActionWidget build()
    {
        return m_widget;
    }


private:
    ActionWidget m_widget;
}


struct ChoiceWidgetBuilder
{
    this(string name)
    {
        m_widget = new ChoiceWidget(name);
    }

    ref ChoiceWidgetBuilder choices(Choice[] choices) return 
    {
        m_widget.m_choices = choices;
        return this;
    }

    ref ChoiceWidgetBuilder font(TTF_Font* pFont) return
    {
        m_widget.m_pFont = pFont;
        return this;
    }

    ref ChoiceWidgetBuilder position(int x, int y) return
    {
        m_widget.m_x = x;
        m_widget.m_y = y;
        return this;
    }

    ChoiceWidget build()
    {
        enforce (m_widget.m_choices.length > 0, "Missing choices");
        return m_widget;
    }

private:
    ChoiceWidget m_widget;
}