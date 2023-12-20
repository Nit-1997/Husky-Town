module house;
import bindbc.sdl;
import obstacle;
import std.stdio;
import constants;

/**
 * Represents a house as an obstacle in the game.
 * Inherits from the Obstacle class.
 */

class House : Obstacle {
    /// Texture for the house.
    SDL_Texture* mTexture;
    /// Rectangle defining the house's position and size.
    SDL_Rect mRectangle;
    /// X and Y coordinates of the house.
    long mXPos, mYPos;
    /// Frame index for animation or texture selection.
    int mFrame;
    /// Unique identifier for the house.
    string id;


    /**
     * Constructor for the House class.
     * Loads the image from the given file path and sets the house's position and size.
     * @param renderer SDL_Renderer used for rendering.
     * @param filepath Path to the image file used for the house's texture.
     * @param x Initial x-coordinate of the house.
     * @param y Initial y-coordinate of the house.
     * @param objectId Unique identifier for the house.
     */

    this(SDL_Renderer* renderer , string filepath , long x , long y , string objectId){
        SDL_Surface* myTestImage   = SDL_LoadBMP(filepath.ptr);

        mTexture = SDL_CreateTextureFromSurface(renderer,myTestImage);
        SDL_FreeSurface(myTestImage);

        mXPos = x;
        mYPos = y;
        mRectangle.x = cast(int)mXPos;
		mRectangle.y = cast(int)mYPos;
		mRectangle.w = 192;
		mRectangle.h = 192;
        mFrame = 10;
        id = objectId;
    }

    /**
     * Gets the SDL_Rect representing the house's position and size.
     * @return SDL_Rect structure.
     */

    SDL_Rect getRectangle() {
        return mRectangle;
    }

    /**
     * Gets the x-coordinate of the house.
     * @return The x-coordinate.
     */

    long get_x_coordinate(){
        return mXPos;
    }

    /**
     * Gets the y-coordinate of the house.
     * @return The y-coordinate.
     */

    long get_y_coordinate(){
        return mYPos;
    }


    /**
     * Gets the unique identifier of the house.
     * @return The identifier as a string.
     */

    string get_id(){
        return id;
    }

    /**
     * Renders the house on the given renderer.
     * @param renderer The SDL_Renderer to use for rendering.
     */

    void render(SDL_Renderer* renderer){
        SDL_Rect selection;
		selection.x = 0;
		selection.y = 64;
		selection.w = 64;
		selection.h = 64;

		mRectangle.x = cast(int)mXPos;
		mRectangle.y = cast(int)mYPos;

        SDL_RenderCopy(renderer,mTexture,&selection,&mRectangle);
    }

}