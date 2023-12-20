module player;
import std.json;

/**
 * Represents a player in the game, holding the player's position and identification information.
 */

struct Player{
    /++ X-coordinate of the player.+/
    long x;
    /++ Y-coordinate of the player.+/
    long y;
    /++ Name of the player.+/
    string name;
    /++ Unique identifier for the player.+/
    string id;

    /**
     * Converts the Player object into a JSONValue representation.
     * This is useful for serializing player data for network communication or saving state.
     * @return A JSONValue containing the player's data.
     */

    JSONValue toJSON() const {
        return JSONValue([
            "x": JSONValue(x),
            "y": JSONValue(y),
            "name": JSONValue(name.idup),
            "id": JSONValue(id.idup)
        ]);
    }
}

unittest {
    /++ Test 1: create a new player +/
    {
        // Create a Player instance
        Player player = Player(100, 200, "TestPlayer", "player123");

        // Convert the Player object to JSON
        auto json = player.toJSON();

        // Assertions to ensure the JSON data is correct
        assert(json["x"].integer == 100, "X coordinate in JSON should be 100");
        assert(json["y"].integer == 200, "Y coordinate in JSON should be 200");
        assert(json["name"].str == "TestPlayer", "Name in JSON should be 'TestPlayer'");
        assert(json["id"].str == "player123", "ID in JSON should be 'player123'");
    }

     /++ Test 2: create another player +/
     {
        // Create a Player instance
        const Player player = Player(150, 250, "AnotherPlayer", "player456");

        // Assertions to ensure member variables are correctly assigned
        assert(player.x == 150, "X coordinate of the Player should be 150");
        assert(player.y == 250, "Y coordinate of the Player should be 250");
        assert(player.name == "AnotherPlayer", "Name of the Player should be 'AnotherPlayer'");
        assert(player.id == "player456", "ID of the Player should be 'player456'");
    }

}

