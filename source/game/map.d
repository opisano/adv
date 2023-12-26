module game.map;

import bindbc.sdl;
import core.exception;
import std.algorithm.searching;
import std.range.primitives;
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
    TileSet*[] tileSets;
    /// Stores Layers of tiles from bottom to top (0 is background, 1 is foreground...)
    Layer[] layers;

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
    in 
    {
        assert (index >= 0);
        assert (index < layers[0].data.length);
    }
    do
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

    /** 
     * Returns the bounding box of the first tile on the left of a position 
     * which can collide
     */
    SDL_Rect bboxLeftOf(scope ref SDL_Rect charRect)
    {
        // grab the collision layer
        auto l = layers[].countUntil!(l => l.name == "collision");

        // convert x to tile column index
        int col = charRect.x / tileWidth;

        // convert y to tile row index 
        int topRow = charRect.y / tileHeight;
        int bottomRow = (charRect.y + charRect.h) / tileHeight;

        while (col >= 0)
        {
            size_t topIndex = topRow * width + col;
            size_t bottomIndex = bottomRow * width + col;

            if (layers[l].data[topIndex] != 0) 
            {
                return this[topIndex];
            }

            if (layers[l].data[bottomIndex] != 0)
            {
                return this[bottomIndex];
            }

            col--;
        }

        // No collision found, return a rect with a negative X
        size_t index = topRow * width;
        SDL_Rect result = this[index];
        result.x -= tileWidth;
        return result;
    }

    /** 
     * Returns the bounding box of the first tile on the left of a position 
     * which can collide
     */
    SDL_Rect bboxRightOf(scope ref SDL_Rect charRect)
    {
        // grab the collision layer
        auto l = layers[].countUntil!(l => l.name == "collision");

        // convert x to tile column index
        int col = charRect.x / tileWidth;

        // convert y to tile row index 
        int topRow = charRect.y / tileHeight;
        int bottomRow = (charRect.y + charRect.h) / tileHeight;

        while (++col < width)
        {
            size_t topIndex = topRow * width + col;
            size_t bottomIndex = bottomRow * width + col;

            if (layers[l].data[topIndex] != 0)
            {
                return this[topIndex];
            }

            if (layers[l].data[bottomIndex] != 0)
            {
                return this[bottomIndex];
            }
        }

        // No collision found, return a rect with outside the map
        size_t index = topRow * width + (width -1);
        SDL_Rect result = this[index];
        result.x += tileWidth;
        return result;
    }

    SDL_Rect bboxTopOf(scope ref SDL_Rect charRect)
    {
        // grab the collision layer
        auto l = layers[].countUntil!(l => l.name == "collision");

        // convert x to tile column index
        int leftCol = charRect.x / tileWidth;
        int rightCol = (charRect.x + charRect.w) / tileWidth;

        // convert y to tile row index 
        int row = charRect.y / tileHeight;

        while (row >= 0)
        {
            size_t leftIndex = row * width + leftCol;
            size_t rightIndex = row * width + rightCol;

            if (layers[l].data[leftIndex] != 0)
            {
                return this[leftIndex];
            }

            if (layers[l].data[rightIndex] != 0)
            {
                return this[rightIndex];
            }

            row--;
        }

        // No collision found, return a rect with outside the map
        size_t index = row * width + (width -1);
        SDL_Rect result = this[index];
        result.y -= tileHeight;
        return result;
    }

    SDL_Rect bboxBottomOf(scope ref SDL_Rect charRect)
    {
        // grab the collision layer
        auto l = layers[].countUntil!(l => l.name == "collision");

        // convert x to tile column index
        int leftCol = charRect.x / tileWidth;
        int rightCol = (charRect.x + charRect.w) / tileWidth;

        // convert y to tile row index 
        int row = charRect.y / tileHeight;

        while (++row < height)
        {
            size_t leftIndex = row * width + leftCol;
            size_t rightIndex = row * width + rightCol;

            if (layers[l].data[leftIndex] != 0)
            {
                return this[leftIndex];
            }

            if (layers[l].data[rightIndex] != 0)
            {
                return this[rightIndex];
            }
        }

        // No collision found, return a rect with outside the map
        size_t index = (row-1) * width + leftCol;
        SDL_Rect result = this[index];
        result.y += tileHeight;
        return result;
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
        index -= firstGid;
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
    char[] name;
    ushort[] data;
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
            result.tileSets ~= new TileSet();
            ushort[] b = f.rawRead!ushort(buffer2[]);
            result.tileSets[$-1].firstGid = b[0];
            result.tileSets[$-1].tileWidth = b[1];
            result.tileSets[$-1].tileHeight = b[2];
            result.tileSets[$-1].tileCount = b[3];
            result.tileSets[$-1].columns = b[4];

            char[] chars;
            f.rawRead!ushort(buffer[]);
            chars ~= "tiles/";
            chars.length = buffer[0] + "tiles/".length;
            f.rawRead!char(chars[6..$]);
            chars ~= '\0';

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
            ushort[2] buffer2;
            result.layers ~= Layer();
            auto b = f.rawRead!ushort(buffer2[]);
            result.layers[$-1].id = b[0];
            result.layers[$-1].name.length = b[1];
            f.rawRead!char(result.layers[$-1].name[]);
             

            f.rawRead!ushort(buffer[]);
            result.layers[$-1].data.length = buffer[0];
            f.rawRead!ushort(result.layers[$-1].data[]);
        }
    }

    return result;
}