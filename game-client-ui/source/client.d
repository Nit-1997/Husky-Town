module client;

import std.socket;
import std.stdio;
import core.thread.osthread;
import std.json;
import game_state;
import player;
import std.algorithm;
import std.conv;
import core.sync.mutex;
import core.time;
import gameRenderer;
import std.conv;
import std.string;
import std.regex;
import std.datetime : SysTime, Clock;

/**
	* The Client class represents a single character within the game environment.
	* It handles the creation and management of the client's connection to the server,
	* player creation, and the running of the main game loop.
	*/
class Client{
  /// Socket used for communicating with the game server.
  Socket mSocket;
	/// Represents the current game state from the client's perspective.
	GameState gameState;
	/// Responsible for rendering game elements within the SDL window.
	GameRenderer gameRenderer;
	/// Flag to check if the initial connection to the server is established.
	bool serverInitPing;
	/// Socket used for chat communication with the server.
	Socket chatSocket;
  /// client start time
	SysTime startTime;
	

	/**
     * Initializes a new Client instance and establishes socket connections for game and chat.
     * @param host The host address of the server. Defaults to "localhost".
     * @param port The port number for the game server. Defaults to 8081.
     */

	this(string host = "localhost", ushort port=8081){
		writeln("Starting client...attempt to create socket");
		mSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		mSocket.connect(new InternetAddress(host, port));

		// chatScoket
		chatSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		chatSocket.connect(new InternetAddress(host, 8082));
		writeln("Connect to chat!");
		char[100] msg;
		auto re = chatSocket.receive(msg);
		writeln("Incoming from server: ", msg[0 .. re]);
		
		writeln("Client conncted to server");
		char[80] buffer;
		auto received = mSocket.receive(buffer);
		writeln("(incoming from server) ", buffer[0 .. received]);
		startTime = Clock.currTime;
		gameRenderer = new GameRenderer(&mSocket , &chatSocket , startTime);
		serverInitPing = false;
	}

	/** Destructor for the Client class, closes open sockets. */
	~this(){
		mSocket.close();
		chatSocket.close();
	}


	/**
     * Asks the user to provide information to create a new player.
     * @return The created Player object with user-provided details.
     */

	Player spawnPlayer(){
		    Player myPlayer;

			writeln("Enter a username for your user, make sure it is unique");
			myPlayer.id = chomp(readln());
			writeln("Enter the spawn x coordinates for your user: ");
			string x_str = readln();
			int x = parse!int(x_str);
			
			myPlayer.x = x;

			writeln("Enter the spawn y coordinates for your user: ");
			string y_str = readln();
			int y = parse!int(y_str);
			myPlayer.y = y;
		

			writeln("Enter a name for your avatar ");
			string name = chomp(readln());
			myPlayer.name = name;

			return myPlayer;
	}

	/**
     * Main method to run the client. It starts the game loop and handles communication
     * with the server.
     */

    void run(){
			writeln("Preparing to run client");
			writeln("(me)",mSocket.localAddress(),"<---->",mSocket.remoteAddress(),"(server)");
			
			new Thread({
						receiveDataFromServer();
			}).start();

			// Wait for the initial game state from the server
			while (serverInitPing == false) {
				Thread.sleep(1000.msecs);
			}

			writeln("Spawning new player ... ");
	
	        // spawning new player
			Player myPlayer = spawnPlayer();

			this.gameState.players ~= myPlayer;
			writeln("After adding new player game state of the client");
			writeln(this.gameState);

			auto serialized_data = this.gameState.toJSON();
			// updating server game state
			mSocket.send(cast(const(ubyte)[])serialized_data);
			new Thread({
				runChatSystem(myPlayer.id);
			}).start();

			gameRenderer.runGame(myPlayer , gameState);
	}


	/// Purpose of this function is to receive data from the server as it is broadcast out.
	/**
     * Receives data from the game server and updates the client's game state.
     */

	void receiveDataFromServer(){
		while(true){
			char[512] buffer;
			auto got = mSocket.receive(buffer);
			string responseFromServer = to!string(buffer[0..got]);          
            responseFromServer = responseFromServer.filter!(c => c != '\0').text;
			this.gameState = GameState.fromJSON(responseFromServer);
			gameRenderer.updateGameState(this.gameState);
			serverInitPing = true;
		}
	}


	/**
     * Runs the chat system in a separate thread, handling sending and receiving of chat messages.
     */

	void runChatSystem(string playerId){
		if( gameState.players !is null) {
			auto len = cast(int) gameState.players.length;
			string username = gameState.players[len-1].name;
			writeln("current player: ", username);
		}


		new Thread({
			receiveFromChat();
		}).start();

		while(true) {
			write(">>");
			foreach(line; stdin.byLine) {
				string modifiedLine = line.idup;
				auto transactionRegex = regex(`^send:(\d+):([^\s]+)`);
				if(std.regex.match(modifiedLine , transactionRegex)){
					string processedTransactionMSG = "send:" ~ playerId ~ ":" ~ modifiedLine.split(":")[1..$].join(":");
                    chatSocket.send(processedTransactionMSG);
				}else{
					if(modifiedLine == "getMyPoints"){
						chatSocket.send(playerId~":"~modifiedLine);
					}else{
						chatSocket.send(playerId~" : "~modifiedLine);
					}
				}
			}

		}
		// chatSocket.close();
	}


	// receiveFromChat get the message
	/**
     * Handles incoming chat messages from the chat server.
     */

	void receiveFromChat() {
		while(true) {
			write(">>");
			char[100] msg;
			auto got = chatSocket.receive(msg);
			string fromChat = to!string(msg[0..got]);

			writeln(fromChat);
		}
	}

}
