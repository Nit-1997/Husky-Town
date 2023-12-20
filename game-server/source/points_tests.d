//module test_points;

import points;
import std.stdio;
import std.file;
import std.exception;
import constants;


unittest {
    // Test the populateTable function
    PointTable testTable = new PointTable(POINTS_DS_TEST);
    assert(testTable.table["nitinb"] == 1000);
    assert(testTable.table["han"] == 10_000);
    assert(testTable.table["fan"] == 200);
    assert(testTable.table["jon"] == 1100);
}

unittest {
    // Test fetchPointsForPlayerId function
    PointTable testTable = new PointTable(POINTS_DS_TEST);
    assert(testTable.fetchPointsForPlayerId("nitinb") == 1000);
    assert(testTable.fetchPointsForPlayerId("han") == 10_000);
    try{
        testTable.fetchPointsForPlayerId("nonexistent");
    }catch(Exception e){
        writeln("passed");
    }
}

unittest {
    // Test updatePointsForPlayerId function
    PointTable testTable = new PointTable(POINTS_DS_TEST);
    testTable.updatePointsForPlayerId("nitinb", 1500);
    assert(testTable.fetchPointsForPlayerId("nitinb") == 1500);

    try{
        testTable.updatePointsForPlayerId("nonexistent", 500);
    }catch(Exception e){
        writeln("passed");
    }
}

unittest {
    // Test makeTransaction function
    PointTable testTable = new PointTable(POINTS_DS_TEST);
    testTable.makeTransaction("nitinb", "han", 500);
    assert(testTable.fetchPointsForPlayerId("nitinb") == 500);
    assert(testTable.fetchPointsForPlayerId("han") == 10_500);

    // Test invalid transaction (not enough points)
    assert(testTable.makeTransaction("jon", "fan", 1200) == "Invalid transaction: Not enough points for player jon");

    // Test invalid transaction (player not found)
    assert(testTable.makeTransaction("nonexistent", "fan", 100) == "Invalid transaction: Player not found");

    // Restore original state for subsequent tests
    testTable.updatePointsForPlayerId("nitinb", 1000);
    testTable.updatePointsForPlayerId("han", 10_000);
}

unittest {
    // Test processTransactionMsg function
    PointTable testTable = new PointTable(POINTS_DS_TEST);
    assert(testTable.processTransactionMsg("send:nitinb:200:han") == "success");

    // Test invalid transaction message format
    assert(testTable.processTransactionMsg("invalid:format") == "Invalid transaction message format");

    // Test invalid action in transaction message
    assert(testTable.processTransactionMsg("unknownaction:nitinb:200:han") == "Invalid action: unknownaction");
}

unittest {
    // Test processTransactionMsg function
    PointTable testTable = new PointTable(POINTS_DS_TEST);
    testTable.updatePointsForPlayerId("nitinb", 0);
    testTable.updatePointsForPlayerId("han", 0);
    testTable.writeTableToFile();

    PointTable testTable2 = new PointTable(POINTS_DS_TEST);
    assert(testTable.fetchPointsForPlayerId("nitinb") == 0);
    assert(testTable.fetchPointsForPlayerId("han") == 0);

    //bringing file to original state
    testTable2.updatePointsForPlayerId("nitinb", 1000);
    testTable2.updatePointsForPlayerId("han", 10_000);
    testTable2.writeTableToFile();
}

