module sprite;

import bindbc.sdl;
import std.string;

/// Represents whether the sprite is idle or walking
enum STATE{IDLE, WALK}

/**
 * Represents a graphical sprite in the game, used for rendering images on the screen.
 */
class Sprite {
    /++ Texture for the sprite.+/
    SDL_Texture* mTexture;
    /++ Rectangle defining the sprite's position and size.+/
    SDL_Rect mRectangle;
    /++ X and Y coordinates of the sprite.+/
    int mXPos, mYPos;
    /++ Frame index for animation or texture selection.+/
    int mFrame;
    /++ Current state of the sprite, e.g., walking, idle.+/
    STATE mState;

    /**
     * Constructor for the Sprite class.
     * Loads an image from a file and sets the sprite's initial position and size.
     * @param renderer SDL_Renderer used for rendering the sprite.
     * @param filepath Path to the image file for the sprite's texture.
     * @param x Initial x-coordinate of the sprite.
     * @param y Initial y-coordinate of the sprite.
     */

    this(SDL_Renderer* renderer , string filepath , long x , long y){
        SDL_Surface* myTestImage   = SDL_LoadBMP(filepath.ptr);

        mTexture = SDL_CreateTextureFromSurface(renderer,myTestImage);
        SDL_FreeSurface(myTestImage);

        mXPos = cast(int)x;
        mYPos = cast(int)y;
        mRectangle.x = cast(int)mXPos;
		mRectangle.y = cast(int)mYPos;
		mRectangle.w = 64;
		mRectangle.h = 64;
    }

    /**
     * Renders the sprite on the given renderer.
     * This method handles sprite animation and positioning.
     * @param renderer The SDL_Renderer to use for rendering.
     */

    void render(SDL_Renderer* renderer){
       
		SDL_Rect selection;
		selection.x = 64*mFrame;
		selection.y = 0;
		selection.w = 64;
		selection.h = 64;

		mRectangle.x = mXPos;
		mRectangle.y = mYPos;

        SDL_RenderCopy(renderer,mTexture,&selection,&mRectangle);

        if(mState == STATE.WALK){
            mFrame++;
            if(mFrame > 3){
                mFrame =0;
            }
        }
    }
}