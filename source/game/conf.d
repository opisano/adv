module game.conf;

/** 
 * This module contains configuration utilities.
 */

import inifiled;
import std.algorithm;
import std.experimental.logger;
import std.file;
import std.path;
import std.process;
import std.range;


struct Configuration
{
    @INI("Window configuration", "Window")
    Window window;

    @INI("Joypad configuration", "Joypad")
    Joypad joypad;
}

@INI("Window configuration", "Window")
struct Window
{
    @INI("The width of the window in pixels")
    int width;

    @INI("The height of the window in pixels")
    int height;
}

/** 
 * Test Window configuration validity.
 * 
 * Params: 
 *     window = Configuration to test
 * 
 * Returns:
 *     true if configuration is valid, false otherwise.
 */
bool check(ref const Window window)
{
    bool res = true;
    if (window.width < 512)
    {
        error("Window width cannot be lesser than 512");
        res = false;
    }
    
    if (window.height < 448)
    {
        error("Window height cannot be lesser than 448");
        res = false;
    }

    return res;
}

@INI("Joypad configuration", "Joypad")
struct Joypad
{
    @INI("Enable joypad controller")
    bool enableJoypad;

    @INI("Name of the controller to use")
    string controllerName;

    @INI("Controller button for action")
    int action;

    @INI("Controller button for cancel")
    int cancel;

    @INI("Controller button for menu")
    int menu;
}

/** 
 * Test joypad configuration validity.
 * 
 * Params: 
 *     joypad = Configuration to test
 * 
 * Returns:
 *     true if configuration is valid, false otherwise.
 */
bool check(ref const Joypad joypad)
{
    // Test each button is unique 
    int[3] buttons = [joypad.action, joypad.cancel, joypad.menu];

    buttons[].sort();

    if (buttons[].uniq.array.length < 3)
    {
        error("Joypad buttons have duplicate values");
        return false;
    }
    return true;
}


/** 
 * Write default configuration to a file 
 * 
 * Params:
 *     filename = filename where to write default configuration.
 */
void writeDefaultConfig(string filename)
{
    Configuration cfg;

    cfg.window.width = 512;
    cfg.window.height = 448;
    cfg.joypad.enableJoypad = false;
    cfg.joypad.controllerName = "";
    cfg.joypad.action = 0;
    cfg.joypad.cancel = 1;
    cfg.joypad.menu = 2;

    writeINIFile(cfg, filename);
}

/** 
 * Read configuration from file.
 * 
 * Params:
 *     filename = filename where to read configuration.
 * 
 * Returns:
 *     Configuration read from disk.
 */
Configuration readConfig(string filename) 
{
    Configuration cfg;
    readINIFile(cfg, filename);
    return cfg;
}


/** 
 * Returns path to where configuration should be stored on disk.
 */
string configFilename()
{

    version(linux)
    {
        /* 
           On linux, the freedesktop guidelines specify that user-level configuration must be put 
           in the path pointed by $XDG_CONFIG_HOME. If this environment variable is not set, it 
           defaults to ~/.config.
        */
        return buildPath(environment.get("XDG_CONFIG_HOME", 
                                         buildPath(environment["HOME"], ".config")), 
                         "adv", 
                         "adv.cfg");
    }
    else version (Windows)
    {
        return buildPath(environment.get("LocalAppData"), 
                         "adv", 
                         "adv.cfg");
    }

}

/** 
 * Make sure the directories needed to store configuration exist on file.
 * 
 * Params:
 *     filename = Path to configuration filename.
 */
void createDirectories(string filename)
{
    string directory = dirName(filename);

    if (!exists(directory))
    {
        mkdir(directory);
    }
}
