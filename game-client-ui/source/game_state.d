module game_state;

import player;
import std.stdio;
import std.json;
import std.array;
import std.algorithm;

/**
 * Represents the game state, holding the current state of all players in the game.
 */

struct GameState{
    /// All active players
    Player[] players;

    /**
     * Converts the GameState object into a JSON string representation.
     * This is useful for sending GameState data over the network or saving it.
     * @return A string containing the JSON representation of the GameState.
     */

    string toJSON() const {
        auto playerObjects = array(
            map!(p => p.toJSON())(players) 
        );

        auto jsonObject = JSONValue([
            "players": JSONValue(playerObjects)
        ]);
        
        return jsonObject.toString();
    }

    /**
     * Creates a GameState object from a JSON string.
     *  for loading game state data from a JSON string.
     * @param jsonStr The JSON string representing the GameState.
     * @return A GameState object created from the JSON string.
     */

    static GameState fromJSON(string jsonStr) {
        auto json = parseJSON(jsonStr);
    
        Player[] players_to_load = [];

        foreach (playerJson; json["players"].array) {
            Player player;
            player.x = playerJson["x"].integer;
            player.y = playerJson["y"].integer;
            player.name = playerJson["name"].str.dup;
            player.id = playerJson["id"].str.dup;
            players_to_load ~= player;
        }

        return GameState(players_to_load);
    }


    /**
     * Updates the position of a player based on the given direction.
     * The direction can be "up", "down", "left", or "right".
     * @param playerId The ID of the player whose position is to be updated.
     * @param direction The direction in which to move the player.
     */

    void updatePlayerPosition(string playerId, string direction) {
        foreach (ref player; players) {
            if (player.id == playerId) {
                // Update player position based on direction
                if (direction == "up") {
                    player.y -= 16;
                } else if (direction == "down") {
                    player.y += 16;
                } else if (direction == "left") {
                    player.x -= 16;
                } else if (direction == "right") {
                    player.x += 16;
                }
                break; // Exit the loop once the player is found and updated
            }
        }
    }


    
}

/**
* unit test for gameState file
*/
unittest {
    /++ Test 1: create two players. test for toJSON() .+/
    {
        // Create a GameState instance with a couple of players
        GameState gameState;
        gameState.players ~= Player(100, 100, "fan", "fan");
        gameState.players ~= Player(200, 200, "jack", "jack");

        // Convert the GameState to a JSON string
        string jsonStr = gameState.toJSON();

        // Check if the JSON string is correctly formatted
        auto json = parseJSON(jsonStr);
        assert(json["players"].array.length == 2, "JSON should contain two players");
        assert(json["players"].array[0]["id"].str == "fan", "First player ID should be 'fan'");
        assert(json["players"].array[1]["id"].str == "jack", "Second player ID should be 'jack'");
    }

    /++ Test2: Test for fromJSON(). +/
     {
        // A JSON string representing the game state with two players
        string jsonStr = `{"players": [{"x": 100, "y": 100, "name": "fan", "id": "fan"},`~
            ` {"x": 200, "y": 200, "name": "nitin", "id": "nitin"}]}`;

        // Create a GameState object from the JSON string
        GameState gameState = GameState.fromJSON(jsonStr);

        // Assertions to ensure the GameState object is correctly created
        assert(gameState.players.length == 2, "GameState should have two players");
        assert(gameState.players[0].id == "fan", "First player's ID should be 'fan'");
        assert(gameState.players[1].id == "nitin", "Second player's ID should be 'nitin'");
    }

    /++ Test3:  for updatePlayerPosition() +/
     {
        // Create a GameState with one player
        GameState gameState;
        gameState.players ~= Player(100, 100, "fan", "fan");

        // Update the player's position
        gameState.updatePlayerPosition("fan", "up");

        // Check if the player's position is updated correctly
        assert(gameState.players[0].x == 100, "fan's X position should remain unchanged");
        assert(gameState.players[0].y == 84, "fan's Y position should be updated (decreased by 16)");
    }

     {
        // Create a GameState with one player
        GameState gameState;
        gameState.players ~= Player(100, 100, "nitin", "nitin");

        // Update the player's position to the right
        gameState.updatePlayerPosition("nitin", "right");

        // Check if the player's position is updated correctly
        assert(gameState.players[0].x == 116, "nitin's X position should be increased by 16");
        assert(gameState.players[0].y == 100, "nitin's Y position should remain unchanged");
    }

     {
        // Create a GameState with one player
        GameState gameState;
        gameState.players ~= Player(150, 150, "Han", "Han");

        // Update the player's position to the left
        gameState.updatePlayerPosition("Han", "left");

        // Check if the player's position is updated correctly
        assert(gameState.players[0].x == 134, "Han's X position should be decreased by 16");
        assert(gameState.players[0].y == 150, "Han's Y position should remain unchanged");
    }


}
