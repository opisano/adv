module game.map;

import bindbc.sdl;
import core.exception;
import dxml.dom;
import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.file;
import std.format;
import std.mmfile;
import std.path;
import std.range.primitives;
import std.stdio;
import std.string;


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
    const(char)[] name;
    ushort[] data;
}


/** 
 * Load a Map from a .xml file on the disk.
 * 
 * Params:
 *     pRenderer: Renderer that will hold the textures in memory.
 *     filename: Path to the file on the disk to load.
 * 
 * Returns:
 *     A Map structure containing data loaded from file. 
 */
Map loadXmlMap(scope SDL_Renderer* pRenderer, string filename)
{
    Map result;

    scope f = new MmFile(filename);
    const(char)[] content = cast(const(char)[]) f[];
    auto dom = parseDOM(content);

    enforce(!dom.children.empty, "Missing map root node");

    auto root = dom.children[0];
    enforce(root.name == "map", "Root node is not map");
    
    // read map dimensions 
    foreach (attr; root.attributes)
    {
        if (attr.name == "width")
            result.width = attr.value.to!ushort;
        else if (attr.name == "height")
            result.height = attr.value.to!ushort;
        else if (attr.name == "tilewidth") 
            result.tileWidth = attr.value.to!ushort;
        else if (attr.name == "tileheight")
            result.tileHeight = attr.value.to!ushort;
    }

    enforce(result.width > 0 &&
            result.height > 0 && 
            result.tileWidth > 0 && 
            result.tileHeight > 0, "Map dimensions not set");

    // read tilesets 
    foreach (tileSetElem; root.children.filter!(elem => elem.name == "tileset"))
    {
        auto pts = new TileSet;

        foreach (attr; tileSetElem.attributes)
        {
            if (attr.name == "firstgid")
                pts.firstGid = attr.value.to!ushort;
            else if (attr.name == "tilewidth")
                pts.tileWidth = attr.value.to!ushort;
            else if (attr.name == "tileheight")
                pts.tileHeight = attr.value.to!ushort;
            else if (attr.name == "tilecount")
                pts.tileCount = attr.value.to!ushort;
            else if (attr.name == "columns")
                pts.columns = attr.value.to!ushort;
        }

        // load tile set image 
        auto images = tileSetElem.children.filter!(child => child.name == "image");
        enforce(!images.empty, "Tileset is missing image child");

        auto image = images.front;
        auto source = image.attributes.filter!(attr => attr.name == "source");
        enforce(!source.empty, "Missing image source attribute");

        auto path = buildPath("tiles", baseName(source.front.value)).toStringz;

        pts.pTexture = IMG_LoadTexture(pRenderer, path);

        if (pts.pTexture == null)
        {
            auto reason = IMG_GetError().fromStringz;
            string message = "Could not load file %s: %s".format(path, reason);

            throw new Exception(message);
        }

        enforce(pts.pTexture != null, );


        result.tileSets ~= pts;
    }

    foreach (layerElem; root.children.filter!(elem => elem.name == "layer"))
    {
        Layer lay;

        foreach (attr; layerElem.attributes)
        {
            if (attr.name == "id")
                lay.id = attr.value.to!ushort;
            else if (attr.name == "name")
                lay.name = attr.value.dup;
        }

        // load layer data 
        auto data = layerElem.children.filter!(c => c.name == "data");
        enforce (!data.empty, "Missing layer data");
        
        lay.data = data.front
                       .children
                       .front
                       .text
                       .splitter(',')
                       .map!(num => num.strip('\n').to!ushort)
                       .array;
        result.layers ~= lay;
    }

    return result;
}
