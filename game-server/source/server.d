module server;
import std.socket;
import std.stdio;
import core.thread.osthread;
import std.json;
import std.conv;
import player;
import game_state;
import core.stdc.string;
import std.algorithm;
import std.array;
import core.sync.mutex;
import std.regex;
import points;

/**
 * The Server class manages the server-side operations for a multiplayer game.
 * It handles client connections, communication, and game state updates.
 */

class Server{
    /++ Listening socket for game client connections.+/
    Socket  mListeningSocket;
    /++ Array of sockets for connected game clients.+/
    Socket[] mClientsConnectedToServer;
    /++ Listening socket for chat client connections.+/
    Socket chatListenSocket;
    /++ Array of sockets for connected chat clients.+/
    Socket[] chatClientsCon;
    /++ Buffer to store messages received from clients.+/
    char[80][] mServerData;
    /++ Table representing each player's points.+/
    PointTable pointsTable;

    /++ Flag for quit. 0 if running, 1 if quit. +/
    int quitFlag;

    /// Keeps track of the last message that was broadcast out to each client.
    uint[] 	mCurrentMessageToSend;
    /++ Represents the current game state.+/
    GameState gameState;

    /**
     * Initializes the Server instance, setting up listening sockets for game and chat.
     * @param host The host address to bind the server. Defaults to "localhost".
     * @param port The port number for the game server. Defaults to 8081.
     * @param maxConnectionsBacklog Maximum number of pending connections in the queue.
     */
    this(string host = "localhost", ushort port=8081, ushort maxConnectionsBacklog=4){
        writeln("Starting server...");
        mListeningSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
        mListeningSocket.bind(new InternetAddress(host,port));
        mListeningSocket.listen(maxConnectionsBacklog);

        writeln("Starting chat server....");
        chatListenSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
        //chatListenSocket.bind(new InternetAddress("localhost", 50001));
        chatListenSocket.bind(new InternetAddress(host,8082));
        chatListenSocket.listen(maxConnectionsBacklog);
        pointsTable = new PointTable();
    }

    /** Destructor for the Server class, closes open sockets. */
    ~this(){
        writeln("Closing sockets...");
        foreach (Socket sock; mClientsConnectedToServer) {
            sock.shutdown(SocketShutdown.BOTH);
            sock.close();
        }
        foreach (Socket sock; mClientsConnectedToServer) {
            sock.shutdown(SocketShutdown.BOTH);
            sock.close();
        }
        writeln("Done! Good bye.");
    }

    /**
     * Handles the main loop for each client connection.
     * @param clientSocket The socket representing the connected client.
     */

    void clientLoop(Socket clientSocket){
        writeln("\t Starting clientLoop:(me)",
            clientSocket.localAddress(),"<---->",
            clientSocket.remoteAddress(),"(client)");
        
        // Let's send the current game state to the client connected to our server
        clientSocket.send(cast(const(ubyte)[])this.gameState.toJSON());
        
        bool runThreadLoop = true;

        while(runThreadLoop){
            
            // Check if the socket isAlive or quit flag set
            if(!clientSocket.isAlive && quitFlag > 0){
                runThreadLoop=false;
                break;
            }
            // Define regular expressions
            auto movementRegex = regex(`^(.+) moved (left|right|up|down)`);
            auto quitRegex = regex(`QUIT:(.+):(\d+)`);
            

            char[512] buffer;
            auto got = clientSocket.receive(buffer);
            string responseFromClient = to!string(buffer[0..got]);
            writeln("client sent");
            writeln(responseFromClient);

            auto match = std.regex.match(responseFromClient, movementRegex);
            auto quitMatch = std.regex.match(responseFromClient , quitRegex);
            
            if(quitMatch){
                auto playerId = quitMatch.front[1];
                immutable int updatedPoints = to!int(quitMatch.front[2]); 
                pointsTable.incrementPointsForPlayerId(playerId , updatedPoints);
                this.gameState.removePlayerFromGameState(playerId);
                auto exitMsg = playerId~
                    " Just exited, and guess what he was rewarded "~
                    quitMatch.front[2]~" points. So keep playing.";
                broadcastToAllClients(exitMsg);
            }else if(match){
                // Extract playerID and movement direction
                 auto playerID = match.front[1];
                 auto direction = match.front[2];
                 gameState.updatePlayerPosition(playerID, direction);
            }else{
                responseFromClient = responseFromClient.filter!(c => c != '\0').text;
                //update the server game state
                this.gameState = GameState.fromJSON(responseFromClient);
            }                

            writeln("Current server updated game state is ");
            writeln(this.gameState);

            //brodcast the latest game state to all clients 
            foreach(idx,serverToClient; mClientsConnectedToServer){
                auto serialized_data = this.gameState.toJSON();
                serverToClient.send(cast(const(ubyte)[])serialized_data);     
            } 
        }
                        
    }

    /**
     * Handles the main loop for each chat client connection.
     * @param clientSocket The socket representing the connected chat client.
     */

    void chatClientsLoop(Socket clientSocket) {
        writeln("\t Starting Chat clientLoop:(me)",
            clientSocket.localAddress(),"<---->",
            clientSocket.remoteAddress(),"(client)");

        bool runThreadLoop = true;

        while(runThreadLoop){
            // Check if the socket isAlive or quit flag set
            if(!clientSocket.isAlive && quitFlag > 0){
                // Then remove the socket
                runThreadLoop=false;
                break;
            }

            // Message buffer will be 80 bytes
            char[80] buffer;
            // Server is now waiting to handle data from specific client
            // We'll block the server awaiting to receive a message.
            auto got = clientSocket.receive(buffer);
            string fromChat = to!string(buffer[0..got]);
            auto transactionRegex = regex(`^send:([^:]+):(\d+):([^\s]+)`);
            auto transactionMatch = std.regex.match(fromChat , transactionRegex);

            auto getMyPointsRegex = regex(`([^:]+):getMyPoints`);
            auto getMyPointsMatch = std.regex.match(fromChat , getMyPointsRegex);

            if(transactionMatch){
                string response = pointsTable.processTransactionMsg(transactionMatch.front[0]);
                if(response != "success"){
                    clientSocket.send(response);
                }else{
                    string announcement = transactionMatch.front[1]~" sent "~
                        transactionMatch.front[2]~" points to "~
                        transactionMatch.front[3];
                    broadcastToAllClients(announcement);
                }
            }else if(getMyPointsMatch){
                 auto playerIdToFind = getMyPointsMatch.front[1];
                 immutable auto points = to!string(pointsTable.fetchPointsForPlayerId(playerIdToFind));
                 auto res = "Hey "~playerIdToFind~" , you have "~points~" points in your account";
                 clientSocket.send(res);
            }else{
                if (fromChat.length > 0) broadcastToAllClients(fromChat);
            }
        }
    }


    /**
     * Broadcasts messages to all connected chat clients.
     */

    void broadcastToAllClients(string newChat){
        writeln("Broadcasting to :", chatClientsCon.length);
        foreach(idx,serverToClient; chatClientsCon){
            serverToClient.send(newChat);
        }
    }

    /**
     * Runs the main server loop, accepting new connections and spawning threads for them.
     */

    void run(){
        bool serverIsRunning=true;
        new Thread({ listenForQuit(); }).start();
        while(serverIsRunning){
            writeln("Waiting to accept more connections");
            try {
                auto newClientSocket = mListeningSocket.accept();
                //accept chat
                auto newChatClient = chatListenSocket.accept();
                chatClientsCon ~= newChatClient;
                mCurrentMessageToSend ~= 0;
                writeln("Friends on server = ",chatClientsCon.length);
                // Let's send our new client friend a welcome message
                newChatClient.send("Hello friend\0");

                // After a new connection is accepted, let's confirm.
                writeln("Hey, a new client joined!");
                writeln("(me)",newClientSocket.localAddress(),"<---->",newClientSocket.remoteAddress(),"(client)");
                mClientsConnectedToServer ~= newClientSocket;
                writeln("Friends on server = ",mClientsConnectedToServer.length);
                
                newClientSocket.send("Hello thanks for joining our game");

                new Thread({
                    clientLoop(newClientSocket);
                }).start();

                new Thread({
                    chatClientsLoop(newChatClient);
                }).start();
            }
            catch (std.socket.SocketAcceptException) {
                writeln("Socket accept interrupted.");
            }

            if (quitFlag == 1) {
                broadcastToAllClients("Server is shutting down...");
                writeln("Quitting session.");
                serverIsRunning = false;

                writeln("Saving scores...");
                pointsTable.writeTableToFile();
            }
        }
    }

    /**
     * Waits for "quit" from stdin, and flags if received.
     */
    void listenForQuit() {
        bool listening = true;
        while (listening) {
            foreach(line; stdin.byLine) {
                if(line == "quit"){
                    quitFlag = 1;
                    listening = false;
                    // close sockets here: can't do it in run() if listening sockets are blocking
                    mListeningSocket.shutdown(SocketShutdown.BOTH);
                    mListeningSocket.close();
                    chatListenSocket.shutdown(SocketShutdown.BOTH);
                    chatListenSocket.close();
                    
                    break;
                }
            }
        }
    }
}
