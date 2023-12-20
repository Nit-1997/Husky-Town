import std.stdio;
import client;

/**
 * The main entry point of the client application.
 * It creates a new client instance and starts the game loop.
 */
void main()
{
	// Create a new instance of the Client class.
	Client client = new Client();
	// Start the client's main loop, which handles game logic and server communication.
	client.run();
}
