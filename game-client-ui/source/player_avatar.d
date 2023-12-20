module player_avatar;
import bindbc.sdl;
import sprite;
import obstacle;
import std.stdio;
import constants;
import std.socket;

/**
 * Represents a player avatar in the game, inheriting from the Obstacle class.
 * It includes methods for movement and rendering, as well as collision detection.
 */

class PlayerAvatar : Obstacle {

    /// Sprite representing the player's graphical representation.
    Sprite mSprite;
    /// Unique identifier for the player.
    string id;
    /// Socket for communicating with the server.
    Socket* mSocket;

    /**
     * Constructor for the PlayerAvatar class.
     * Initializes the player's sprite, ID, and socket for server communication.
     * @param renderer SDL_Renderer used for rendering the sprite.
     * @param filepath Path to the sprite's image file.
     * @param x Initial x-coordinate of the player.
     * @param y Initial y-coordinate of the player.
     * @param playerId Unique identifier for the player.
     * @param serverSocket Socket used for server communication.
     */

    this(SDL_Renderer* renderer , string filepath , long x , long y , string playerId , Socket* serverSocket){
        mSprite = new Sprite(renderer , filepath , x , y);
        id = playerId;
        mSocket = serverSocket;
    }

    /**
     * Updates the coordinates of the player's sprite.
     * @param x New x-coordinate.
     * @param y New y-coordinate.
     */

    void updateCoordinates(long x , long y){
        mSprite.mYPos = cast(int)y;
        mSprite.mXPos = cast(int)x;
        mSprite.mState = STATE.WALK;
    }

    SDL_Rect getRectangle() {
        return mSprite.mRectangle;
    }

    long get_x_coordinate(){
        return mSprite.mXPos;
    }

    long get_y_coordinate(){
        return mSprite.mYPos;
    }

    string get_id(){
        return id;
    }

    /**
     * Moves the player avatar up, checking for collisions.
     * @param obstacles Array of obstacles to check for collisions.
     */

    void move_up(Obstacle[] obstacles){
        immutable long updated_x = this.get_x_coordinate();
        immutable long updated_y = this.get_y_coordinate() - 16;
        SDL_Rect updatedRect =  this.getRectangle();
        updatedRect.y = cast(int)updated_y;
        
        if(isColliding(updatedRect , updated_x , updated_y , obstacles)){
            return;
        }
        mSprite.mYPos -= 16;
        mSprite.mState = STATE.WALK;
        mSocket.send(id~" moved up");
    }

    /**
     * Moves the player avatar down, checking for collisions.
     * @param obstacles Array of obstacles to check for collisions.
     */
    void move_down(Obstacle[] obstacles){
        immutable long updated_x = this.get_x_coordinate();
        immutable long updated_y = this.get_y_coordinate() + 16;
        SDL_Rect updatedRect =  this.getRectangle();
        updatedRect.y = cast(int)updated_y;

        if(isColliding(updatedRect , updated_x , updated_y , obstacles)){
            return;
        }
        mSprite.mYPos += 16;
        mSprite.mState = STATE.WALK;
        mSocket.send(id~" moved down");  
    }

    /**
     * Moves the player avatar left, checking for collisions.
     * @param obstacles Array of obstacles to check for collisions.
     */
    void move_left(Obstacle[] obstacles){
        immutable long updated_x = this.get_x_coordinate() - 16;
        immutable long updated_y = this.get_y_coordinate();
        SDL_Rect updatedRect =  this.getRectangle();
        updatedRect.x = cast(int)updated_x;

        if(isColliding(updatedRect , updated_x , updated_y , obstacles)){
            return;
        }
        mSprite.mXPos -= 16;
        mSprite.mState = STATE.WALK;
        mSocket.send(id~" moved left");  
    }

    /**
     * Moves the player avatar right, checking for collisions.
     * @param obstacles Array of obstacles to check for collisions.
     */
    void move_right(Obstacle[] obstacles){
        immutable long updated_x = this.get_x_coordinate() + 16;
        immutable long updated_y = this.get_y_coordinate();
        SDL_Rect updatedRect =  this.getRectangle();
        updatedRect.x = cast(int)updated_x;

        if(isColliding(updatedRect , updated_x , updated_y , obstacles)){
            return;
        }
        mSprite.mXPos += 16;
        mSprite.mState = STATE.WALK;
        mSocket.send(id~" moved right");  
    }

    /**
     * Renders the player's sprite on the given renderer.
     * @param renderer The SDL_Renderer to use for rendering.
     */

    void render(SDL_Renderer* renderer){
        mSprite.render(renderer);
        mSprite.mState = STATE.IDLE;
    }

    /**
     * Checks for collision between the player avatar and other obstacles.
     * @param updated Updated SDL_Rect of the player.
     * @param x New x-coordinate.
     * @param y New y-coordinate.
     * @param obstacles Array of obstacles to check for collisions.
     * @return True if a collision is detected, otherwise false.
     */

    bool isColliding(SDL_Rect updated , long x, long y, Obstacle[] obstacles) {
        // Check if the new position is within the window bounds
        if (x < 0 || y < 0 || x + mSprite.mRectangle.w > SCREEN_WIDTH || y + mSprite.mRectangle.h > SCREEN_HEIGHT) {
            return true;
        }

        // Check if the new position collides with any obstacle
        foreach (obstacle; obstacles) {
            if(obstacle.get_id() == id){
                continue; 
            }

            SDL_Rect other = obstacle.getRectangle();
            immutable SDL_bool collides = SDL_HasIntersection(&updated , &other);
            
            if(collides == 1){
                return true;
            }
        }
        return false;
    }
}