import bindbc.sdl;

/**
 * The Obstacle interface represents any object in the game that acts as an obstacle.
 * It provides the necessary methods for identifying and positioning obstacles in the game world.
 */

interface Obstacle {
    /**
     * Gets the x-coordinate of the obstacle.
     * @return The x-coordinate as a long.
     */
    long get_x_coordinate();

    /**
     * Gets the y-coordinate of the obstacle.
     * @return The y-coordinate as a long.
     */
    long get_y_coordinate();

    /**
     * Gets the unique identifier of the obstacle.
     * @return The identifier as a string.
     */
    string get_id();

    /**
     * Gets the SDL_Rect structure representing the obstacle's position and size.
     * @return An SDL_Rect structure.
     */
    SDL_Rect getRectangle(); 
}