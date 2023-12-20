module game_state;

import player;
import std.stdio;
import std.json;
import std.array;
import std.algorithm;
import std.string;

/**
 * Represents the state of the game, including all players currently in the game.
 */

struct GameState{
    /++ Array of Player objects representing all players in the game.+/
    Player[] players;

    /**
     * Converts the GameState object into a JSON string representation.
     * Useful for network communication or saving the game state.
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
     * Useful for loading game state from a JSON representation.
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
     * Updates the position of a specified player based on the given direction.
     * @param playerId The ID of the player to update.
     * @param direction The direction to move the player ("up", "down", "left", "right").
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

    /**
     * Removes a player from the game state based on their ID.
     * @param playerId The ID of the player to remove.
     */

    void removePlayerFromGameState(string playerId){
        players = players.filter!(p => p.id != playerId).array;
    }


    
}

/**
* Unit test for gamaState file in game-server folder
*/
unittest {
    /++ Test 1: test for removePlayerFromGameState() +/
    // Create a GameState instance with several players
    GameState gameState;
    gameState.players ~= Player(100, 100, "Player1", "id1");
    gameState.players ~= Player(300, 300, "Player2", "id2");
    gameState.players ~= Player(500, 500, "Player3", "id3");

    // ID of the player to be removed
    string playerIdToRemove = "id2";

    // Remove the specified player
    gameState.removePlayerFromGameState(playerIdToRemove);

    // Assertions to ensure the player is removed
    assert(gameState.players.length == 2, "There should be 2 players after removal");
    assert(!gameState.players.any!(p => p.id == playerIdToRemove), "Player with ID 'id2' should be removed");
}
