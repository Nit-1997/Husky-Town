import std.stdio;
import server;

/**
 * The main entry point for the server application.
 * It creates a new server instance and starts its operation.
 */
void main()
{
	Server server = new Server();
	server.run();
}
