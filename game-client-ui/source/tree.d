module tree;
import bindbc.sdl;
import obstacle;
import std.stdio;
import constants;

/**
 * Represents a tree in the world map.
 */
class Tree : Obstacle {
    /// the SDL texture representing the tree
    SDL_Texture* mTexture;
    /// the SDL rectangle representing the tree's collision boundary
    SDL_Rect mRectangle;
    /// position of the tree on the world
    long mXPos, mYPos;
    /// Frame index texture selection
    int mFrame;
    /// ID of the tree object
    string id;
    
    /**
     * Makes a new tree on the map
     * Params:
     *      renderer     =   The SDL renderer of the game
     *      filepath     =   The path to the bitmap file containing the tree.
     *      x            =   The x position of the tree.
     *      y            =   The y position of the tree.
     *      objectId     =   The ID of the tree object.
     */
    this(SDL_Renderer* renderer , string filepath , long x , long y , string objectId){
        SDL_Surface* myTestImage   = SDL_LoadBMP(filepath.ptr);

        mTexture = SDL_CreateTextureFromSurface(renderer,myTestImage);
        SDL_FreeSurface(myTestImage);

        mXPos = x;
        mYPos = y;
        mRectangle.x = cast(int)mXPos;
		mRectangle.y = cast(int)mYPos;
		mRectangle.w = 48;
		mRectangle.h = 96;
        id = objectId;
    }

    SDL_Rect getRectangle() {
        return mRectangle;
    }

    long get_x_coordinate(){
        return mXPos;
    }

    long get_y_coordinate(){
        return mYPos;
    }

    string get_id(){
        return id;
    }

    /**
     * Render the tree onto the SDL map.
     * Params:
     *      renderer     =   The SDL renderer of the game
     */
    void render(SDL_Renderer* renderer){
        SDL_Rect selection;
		selection.x = 64;
		selection.y = 0;
		selection.w = 16;
		selection.h = 32;

		mRectangle.x = cast(int)mXPos;
		mRectangle.y = cast(int)mYPos;

        SDL_RenderCopy(renderer,mTexture,&selection,&mRectangle);
    }

}