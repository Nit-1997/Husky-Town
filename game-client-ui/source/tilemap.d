module tilemap;

import std.stdio;
import std.algorithm;
import bindbc.sdl;
import constants;

/**
 * Represents a tile set for rendering a tile-based game environment.
 */

class TileSet{
    /// rectangles storing a specific tile at an index
    SDL_Rect[] mRectTiles; 
    /// tile map texture
    SDL_Texture* mTexture; 
    /// tile dimension (mTileSize x mTileSize) assuming sqaure
    int mTileSize; 
    /// no. of tiles in the tilemap in x-dimension
    int mXTiles; 
    /// no. of tiles in the tilemap in y-dimension
    int mYTiles; 
    
    /**
     * Constructor for the TileSet class.
     * Loads a tilemap image from a file and initializes tiles.
     * @param renderer The SDL_Renderer used for rendering.
     * @param filepath Path to the tilemap image file.
     * @param tileSize Size of each tile in the tilemap.
     * @param xTiles Number of tiles along the x-axis.
     * @param yTiles Number of tiles along the y-axis.
     */

    this(SDL_Renderer* renderer , string filepath , int tileSize , int xTiles , int yTiles){
        mTileSize = tileSize;
        mXTiles = xTiles;
        mYTiles = yTiles;

        SDL_Surface* myImg = SDL_LoadBMP(filepath.ptr);
        mTexture = SDL_CreateTextureFromSurface(renderer , myImg);
        SDL_FreeSurface(myImg);

        for(int y = 0 ; y < mYTiles ; y++){
            for(int x = 0 ; x < mXTiles ; x++){
                SDL_Rect rect;
                rect.x = x * mTileSize;
                rect.y = y * mTileSize;
                rect.w = mTileSize;
                rect.h = mTileSize;
                mRectTiles ~= rect;
            }
        }
    }

    /**
     * Renders a specific tile from the tileset.
     * @param renderer The SDL_Renderer used for rendering.
     * @param tile Index of the tile in the tileset.
     * @param x X-coordinate for rendering the tile.
     * @param y Y-coordinate for rendering the tile.
     * @param zoomFactor Factor to scale the tile size.
     */

    void renderTile(SDL_Renderer* renderer, int tile , int x , int y , int zoomFactor  = 1){
        if(mRectTiles.length > 0 && tile + 1 > mRectTiles.length){
            return;
        }

        SDL_Rect selection = mRectTiles[tile];

        SDL_Rect rect;
        rect.x = mTileSize * x * zoomFactor;
        rect.y = mTileSize * y * zoomFactor;
        rect.w = mTileSize * zoomFactor;
        rect.h = mTileSize * zoomFactor;

        SDL_RenderCopy(renderer , mTexture , &selection , &rect);
    }
}


/**
 * Represents a drawable tile map in the game world.
 */

class DrawableTileMap{
    /// true map width
    const int mMapXSize = 20;
    /// true map height
    const int mMapYSize = 20;
    /// rendered map width
    const int rMapXSize = 20;
    /// rendered map height
    const int rMapYSize = 20;
    /// horizontal camera offset
    int offSetX;
    /// vertical camera offset
    int offSetY;

    /// the tile set to draw with
    TileSet mTileSet;

    /// the tiles of the world map
    int [mMapXSize][mMapYSize] mTiles;

    /**
     * Constructor for the DrawableTileMap class.
     * Initializes the tile map and sets default tiles.
     * @param t The TileSet to use for rendering tiles.
     */

    this(TileSet t){
        mTileSet = t;
        offSetX = 0;
        offSetY = 0;

         for(int y=0; y < mMapYSize; y++){
            for(int x=0; x < mMapXSize; x++){
                if(y==0){
                   mTiles[x][y] = 33;
                } 
                else if(y==mMapYSize-1){
                    mTiles[x][y] =107;
                } 
                else if(x==0){
                    mTiles[x][y] =69;
                } 
                else if(x==mMapXSize-1){
                    mTiles[x][y] =71;
                } 
                else{
                    // Deafult tile
                    mTiles[x][y] = 966;
                }
            }
        }

        int midY = mMapYSize / 2;
        int midX = mMapXSize / 2;

        mTiles[0][0] = 32;
        mTiles[mMapXSize-1][0] = 34;
        mTiles[0][mMapYSize-1] = 106;
        mTiles[mMapXSize-1][mMapYSize-1] = 108;
        

        for(int xpos = 0 ; xpos < mMapXSize ; xpos++){
            if(xpos % 2 == 0){
                mTiles[xpos][midY] = 898;
                mTiles[xpos][midY + 1] = 898;
            }else{
                mTiles[xpos][midY] = 831;
                mTiles[xpos][midY + 1] = 832;
            }
        }

        for(int ypos = 0 ; ypos < mMapYSize ; ypos++){
                if(ypos == midY || ypos == midY + 1){
                    mTiles[midX-1][ypos] = 823;
                    mTiles[midX][ypos] = 823;
                    continue;
                }

                mTiles[midX-1][ypos] = 752;
                mTiles[midX][ypos] = 788;
            
        }
        

        // tileset for tilemap.bmp
        //  for(int x = 0; x < mMapXSize; x++){
        //     for(int y = 0; y < mMapYSize ; y++){
        //         if(y==0){
        //            mTiles[x][y] = 13;
        //         } 
        //         else if(y==mMapYSize-1){
        //             mTiles[x][y] =37;
        //         } 
        //         else if(x==0){
        //             mTiles[x][y] =24;
        //         } 
        //         else if(x==mMapXSize-1){
        //             mTiles[x][y] =26;
        //         } 
        //         else{
        //             // Deafult tile
        //             mTiles[x][y] = 1;
        //         }
        //     }
        // }
        // mTiles[0][0] = 12;
        // mTiles[mMapXSize-1][0] = 14;
        // mTiles[0][mMapYSize-1] = 36;
        // mTiles[mMapXSize-1][mMapYSize-1] = 38;
        
        // for(int y = 0; y < 4; y++) {
        //     for(int x = 0; x < 4; x++) {
        //         mTiles[x + 3][y + 12] = 48 + x + y * 12;
        //         //[x + 13][y + 8] = 52 + x + y * 12;
        //         mTiles[x + 8][y + 1] = 52 + x + y * 12;
        //         //mTiles[x + 5][y + 6] = 48 + x + y * 12;
        //         //mTiles[x+ 14][y + 7] = 52 + x + y * 12;
        //         mTiles[x + 9][y + 15] = 48 + x + y * 12;
        //         //mTiles[x + 15][y + 12] = 48 + x + y * 12;
        //         mTiles[x +14][y + 4] = 48 + x + y * 12;
        //     }
        // }

        // mTiles[13][2] = 4;
        // mTiles[13][3] = 16;
    }


    /**
     * Renders the visible portion of the tile map based on the current camera offset.
     * @param renderer The SDL_Renderer used for rendering the tile map.
     * @param zoomFactor Factor to scale the tile size during rendering.
     */

    void render(SDL_Renderer* renderer, int zoomFactor=1){
        //int renderStartX = max(0, offSetX);
        //int renderStartY = max(0, offSetY);
        //int renderEndX = min(mMapXSize, offSetX + rMapXSize);
        //int renderEndY = min(mMapYSize, offSetY + rMapYSize);

        for (int y = 0; y < rMapYSize; y++) {
            for (int x = 0; x < rMapXSize; x++) {
                mTileSet.renderTile(renderer, mTiles[x][y], x, y, zoomFactor);
            }
        }
    }

    /**
     * Ensures the camera offset is within the bounds of the tile map.
     */

    void check_camera() {
        if (offSetX < 0) {
            offSetX = 0;
        }
        if (offSetX > mMapXSize - rMapXSize) {
            offSetX = mMapXSize - rMapXSize;
        }
        if (offSetY < 0) {
            offSetY = 0;
        }
        if (offSetY > mMapYSize - rMapYSize) {
            offSetY = mMapYSize - rMapYSize;
        }
    }

    // Moving the camera in a certain position positive x means right negative x means down
    // Postive Y means up, negative y means down
    void setCamera(int x, int y) {
        offSetX += x;
        offSetY += y;
        check_camera();
    }

}