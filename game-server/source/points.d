module points;

import std.file;
import constants;
import std.stdio;
import std.conv;
import std.array;
import std.string;

/**
 * A table that keeps track of players' points.
 */
final class PointTable {
    /// The internal hash table representation of points.
    int[string] table;
    /// The path to the file where points are loaded and stored.
    string file_path;
   
    // used in practice
    /// Populates the table with info from the points save file.
    this(){
        file_path = POINTS_DS;
        populateTable();
    }

    // used for testing
    /// Reads from the given file and populates the table.
    this(string filePath) {
        // read the file to populate the table
        file_path = filePath;
        populateTable();
    }

    /// Loads the contents of the save file into the hash table.
    void populateTable() {
        // populate table logic
        string fileContent;
        try {
            fileContent = cast(string) readText(file_path);
        } catch (Exception e) {
            writeln("Error reading file: ", e.msg);
            return;
        }

        foreach (line; fileContent.splitLines()) {
            auto tokens = line.split(':');
            if (tokens.length == 2) {
                string playerId = tokens[0].strip;
                immutable int points = to!int(tokens[1].strip);
                table[playerId] = points;
            }
        }
    }

    /**
     * Fetch points for a player from the table given a playerID.
     * Params:
     *      playerId =   The player to query points.
     * Returns: The points the current player has.
     */
    int fetchPointsForPlayerId(string playerId) {
        if (playerId in table) {
            return table[playerId];
        } else {
            throw new Exception("playerId: " ~ playerId ~ " does not exist");
        }
    }

    /**
     * Update points for a player from the table given a playerID.
     * Params:
     *      playerId =   The player to update.
     */
    void updatePointsForPlayerId(string playerId, int newPoints) {
        if (playerId in table) {
            table[playerId] = newPoints;
        } else {
            throw new Exception("Failed, playerId: " ~ playerId ~ " does not exist");
        }
    }
    
    /**
     * Update points for a player from the table given a playerID.
     * Params:
     *      playerId =   The player to update.
     *      newPoints =  The number of points to add to their score.
     */
    void incrementPointsForPlayerId(string playerId, int newPoints) {
        if (playerId in table) {
            table[playerId] += newPoints;
        } else {
            table[playerId] = newPoints;
        }
    }

    /**
     * Transfer points from one player to another.
     * Params:
     *      playerId1 =  The player giving points.
     *      playerId2 =  The player receiving points.
     *      newPoints =  The number of points to transfer.
     * Returns: A success or failure string.
     */
    string makeTransaction(string playerId1, string playerId2, int points) {
        // make transaction between player 1 and player 2 (check for invalid transaction)
        if (!(playerId1 in table) || !(playerId2 in table)) {
            return "Invalid transaction: Player not found";
        }

        int points1 = 0;
        int points2 = 0;

        try {
            points1 = fetchPointsForPlayerId(playerId1);
            points2 = fetchPointsForPlayerId(playerId2);
        } catch (Exception e) {
            return "Failed transaction because: \n " ~ e.msg;
        }

        if (points1 >= points) {
            try {
                updatePointsForPlayerId(playerId1, points1 - points);
                updatePointsForPlayerId(playerId2, points2 + points);
                return "success";
            } catch (Exception e) {
                return "Failed transaction because: \n " ~ e.msg;
            }
        } else {
            return "Invalid transaction: Not enough points for player " ~ playerId1;
        }
    }

    /**
     * Process a transaction given as a raw string (e.g. `send:playerId1:100:playerID2`)
     * Params:
     *      transactionMsg =  The chat representing the transaction.
     * Returns: A success or failure string.
     */
    string processTransactionMsg(string transactionMsg) {
        // take the raw client message and process it into a transaction.
        //send:playerId1:100:playerID2
        auto tokens = transactionMsg.split(':');

        if (tokens.length != 4) {
            writeln("Invalid transaction message format");
            return "Invalid transaction message format";
        }

        string action = tokens[0].strip;
        string playerId1 = tokens[1].strip;
        int points = to!int(tokens[2].strip);
        string playerId2 = tokens[3].strip;

        if (action == "send") {
            string response = makeTransaction(playerId1, playerId2, points);
            return response;
        } else {
            return "Invalid action: " ~ action;
        }
    }
    
    /**
     * Writes the contents of the hash map back to the file.
     */
    void writeTableToFile() {
       // write back the contents of the hash map back to the file.
        string fileContent = "";
        foreach (playerId, points; table) {
            try{
                auto castedPoints = to!string(points);
                fileContent ~= playerId~":"~castedPoints~"\n";
            }catch(Exception e){
                writeln("parsing error");
            }
        }
        try {
            std.file.write(file_path, fileContent);
            writeln("sucessfull file update!!!");
        } catch (Exception e) {
            writeln("Error writing to file: ", e.msg);
        }
   }
}


