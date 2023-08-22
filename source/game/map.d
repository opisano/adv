module game.map;

import automem.vector;
import core.exception;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.exception;
import std.format;
import std.stdio;


/** 
 * Contains Map data to be loaded by a TopDown view.
 * 
 */
struct Map
{
    /// Width in tiles
    ushort width;
    /// Height in tiles 
    ushort height;
    /// Width of a tile, in pixels
    ushort tileWidth;
    /// Height of a tile, in pixels
    ushort tileHeight;

    /// Stores tile sets to be loaded with this map
    Vector!(TileSet) tileSets;
    /// Stores Layers of tiles from bottom to top (0 is background, 1 is foreground...)
    Vector!(Layer) layers;

    /** 
     * Converts a tile index to a rectangle region in the map (in pixels).
     * 
     * 0 is the Top-leftmost tile, 1 is the tile at its right, and so on.
     * 
     * Params:
     *     index = Index to convert.
     * 
     * Returns:
     *     The Region in pixels as a SDL_Rect structure.
     */ 
    SDL_Rect opIndex(size_t index) pure const nothrow
    {
        immutable int row = cast(int) (index / width);
        immutable int col = index % width;
        immutable int x = col * tileWidth;
        immutable int y = row * tileHeight;

        return SDL_Rect(x, y, tileWidth, tileHeight);
    }

    int pixelWidth() const
    {
        return tileWidth * width;
    }

    int pixelHeight() const
    {
        return tileHeight * height;
    }
}

/** 
 * Holds information about a tile set, as used by a Map.
 */
struct TileSet
{
    /** 
     * Destructor
     *  
     * Frees texture resources.
     */
    ~this()
    {
        if (pTexture)
        {
            SDL_DestroyTexture(pTexture);
            pTexture = null;
        }
    }

    /** 
     * Converts a tile index to a rectangle region in this tile set (in pixels).
     * 
     * 0 is the Top-leftmost tile, 1 is the tile at its right, and so on.
     * 
     * Params:
     *     index = Index to convert.
     * 
     * Returns:
     *     The Region in pixels as a SDL_Rect structure.
     */ 
    SDL_Rect opIndex(size_t index) const pure nothrow
    {
        immutable int row = cast(int) (index / columns);
        immutable int col = cast(int) (index % columns);
        immutable int x = col * tileWidth;
        immutable int y = row * tileHeight;

        return SDL_Rect(x, y, tileWidth, tileHeight);
    }

    ushort firstGid;
    ushort tileWidth;
    ushort tileHeight;
    ushort tileCount;
    ushort columns;
    SDL_Texture* pTexture;
}

/** 
 * A layer of Tile data in a Map.
 */
struct Layer
{
    ushort id;
    Vector!(ushort) data;
}


/** 
 * Load a Map from a .map file on the disk.
 * 
 * Params:
 *     pRenderer: Renderer that will hold the textures in memory.
 *     filename: Path to the file on the disk to load.
 * 
 * Returns:
 *     A Map structure containing data loaded from file. 
 */
Map loadMap(scope SDL_Renderer* pRenderer, string filename) 
{
    Map result;
    File f = File(filename, "rb");

    // read magic number
    {
        ulong[1] buffer;
        f.rawRead(buffer[]);
        enforce(buffer[0] == 0x303150414d564441, "Cannot load %s: Invalid map format".format(filename));
    }

    // read map dimensions
    {
        ushort[4] buffer;
        ushort[] b = f.rawRead!ushort(buffer[]);

        result.width = b[0];
        result.height = b[1];
        result.tileWidth = b[2];
        result.tileHeight = b[3];
    }

    // Read tile sets 
    {
        ushort[1] buffer;
        f.rawRead!ushort(buffer[]);
        int len = buffer[0];
        result.tileSets.reserve(len);

        for (int i = 0; i < len; ++i)
        {
            ushort[5] buffer2;
            result.tileSets.put(TileSet());
            ushort[] b = f.rawRead!ushort(buffer2[]);
            result.tileSets[$-1].firstGid = b[0];
            result.tileSets[$-1].tileWidth = b[1];
            result.tileSets[$-1].tileHeight = b[2];
            result.tileSets[$-1].tileCount = b[3];
            result.tileSets[$-1].columns = b[4];

            Vector!char chars;
            f.rawRead!ushort(buffer[]);
            chars.put("tiles/");
            chars.length = buffer[0] + "tiles/".length;
            f.rawRead!char(chars[6..$]);
            chars.put('\0');

            result.tileSets[$-1].pTexture = IMG_LoadTexture(pRenderer, &chars[0]);
            enforce(result.tileSets[$-1].pTexture != null, "Could not load file %s".format(chars[]));
        }
    }

    // Read layers 
    {
        ushort[1] buffer;
        f.rawRead!ushort(buffer[]);
        int len = buffer[0];
        result.layers.reserve(len);

        for (int i = 0; i < len; ++i)
        {
            result.layers.put(Layer());
            f.rawRead!ushort(buffer[]);
            result.layers[$-1].id = buffer[0];

            f.rawRead!ushort(buffer[]);
            result.layers[$-1].data.length = buffer[0];
            f.rawRead!ushort(result.layers[$-1].data[]);
        }
    }

    return result;
}