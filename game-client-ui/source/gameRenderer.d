import std.stdio;
import std.string;
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
import player_avatar;
import obstacle;
import constants;
import tilemap;
import house;
import tree;
import game_state;
import player;
import std.socket;
import std.algorithm;
import std.array;
import core.stdc.stdlib;
import std.datetime;
import std.conv;

/**
 * Manages a running SDL game.
 */
class GameRenderer {
    /// game state of running game
    GameState gameState;
    /// client's avatar
    PlayerAvatar yourPlayer;
    /// list of all obstacles in the world
    Obstacle[] obstacles;
    /// the SDL renderer to render the game
    SDL_Renderer* renderer;
    /// the tiles of the game
    DrawableTileMap dt;
    /// how much we are zoomed in
    int zoomFactor;
    /// the current SDL window
    SDL_Window* window;
    /// the socket for the game to communicate with the server
    Socket* mSocket;
    /// the socket for the chat to communicate with the server
    Socket* chatSocket;
    /// the username of the active player
    string playerId;
    /// the avatars of the other active players
    PlayerAvatar[] otherPlayers;
    /// houses in the world
    House house1, house2, house3;
    /// trees in the world
    Tree tree1, tree2, tree3, tree4, tree5, tree6, tree7, tree8;

    /// the time the game is started, for points calculation
    SysTime startTime;
    
    /**
     * Makes a new renderer, loading imports
     * Params:
     *      serverSocket     =   The socket to communicate with the server.
     *      serverChatSocket =   The socket for chat to communicate with the server.
     *      start            =   The start time of the game.
     */
    this(Socket* serverSocket , Socket* serverChatSocket , SysTime start){

            obstacles = [];
            otherPlayers = [];

            SDLSupport ret;
            // Load the SDL libraries from bindbc-sdl
            // NOTE: Windows users may need this
            version(Windows) ret = loadSDL("SDL2.dll");
            // NOTE: Mac users may need this
            version(OSX){
                writeln("Searching for SDL on Mac");
                ret = loadSDL();
            }
            // NOTE: Linux users probably need this
            version(linux) ret = loadSDL();
            
            if(ret != sdlSupport){
                writeln("error loading SDL library");
                
                foreach( info; loader.errors){
                    writeln(info.error,':', info.message);
                }
            }
            if(ret == SDLSupport.noLibrary){
                writeln("error no library");    
            }
            if(ret == SDLSupport.badLibrary){
                writeln("Eror badLibrary, missing symbols");
            }

            // Initialize SDL
            if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
                writeln("SDL_Init: ", fromStringz(SDL_GetError()));
            }

            
            // Create an SDL window
            window= SDL_CreateWindow("Rectangle motion window",
                                                SDL_WINDOWPOS_UNDEFINED,
                                                SDL_WINDOWPOS_UNDEFINED,
                                                SCREEN_WIDTH,
                                                SCREEN_HEIGHT, 
                                                SDL_WINDOW_SHOWN);


            // On Mac's, it's possible that creating the window will also create
            // the renderer, so we should check first.
            if(SDL_GetRenderer(window)==null){
            renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
            }else{
                renderer = SDL_GetRenderer(window);
            }
            // If there's still an error, then convert the const char* and write
            // out the string
            if(renderer==null){
                import std.conv;
                writeln("renderer ERROR: ", to!string(SDL_GetError()));
            }

            mSocket = serverSocket;
            chatSocket = serverChatSocket;

            startTime = start;
    }

    /**
     * Updates the game state based on the received game state information.
     * This involves updating existing players' positions and adding or removing players.
     * @param gameStateReceived The game state received from the server .
     */

    void updateGameState(GameState gameStateReceived) {
        // adding obstacle to the map
        house1 =  new House(renderer, "./assets/tilemap.bmp", 600, 270, "house1");
        obstacles ~= house1;
        house2 =  new House(renderer, "./assets/tilemap.bmp", 680, 690, "house2");
        obstacles ~= house2;
        house3 = new House(renderer, "./assets/tilemap.bmp", 100, 680, "house3");
        obstacles ~= house3;
        tree1 = new Tree(renderer, "./assets/tilemap.bmp", 640, 600, "tree1");
        obstacles ~= tree1;
        tree2 = new Tree(renderer, "./assets/tilemap.bmp", 830, 55, "tree2");
        obstacles ~= tree2;
        tree3 = new Tree(renderer, "./assets/tilemap.bmp", 100, 800, "tree3");
        obstacles ~= tree3;
        tree4 = new Tree(renderer, "./assets/tilemap.bmp", 840, 600, "tree4");
        obstacles ~= tree4;
        tree5 = new Tree(renderer, "./assets/tilemap.bmp", 400, 60, "tree5");
        obstacles ~= tree5;
        tree6 = new Tree(renderer, "./assets/tilemap.bmp", 640, 80, "tree6");
        obstacles ~= tree6;
        tree7 = new Tree(renderer, "./assets/tilemap.bmp", 40, 550, "tree7");
        obstacles ~= tree7;
        tree8 = new Tree(renderer, "./assets/tilemap.bmp", 320, 700, "tree8");
        obstacles ~= tree8;


           // Update existing players
            foreach (receivedPlayer; gameStateReceived.players) {
                bool playerExists = false;
                foreach (otherPlayer; otherPlayers) {
                    if (otherPlayer.id == receivedPlayer.id) {
                        // Update existing player's coordinates
                        otherPlayer.updateCoordinates(receivedPlayer.x, receivedPlayer.y);
                        playerExists = true;
                        //break;
                    }
                }

                // If the player is not found in the existing players list, create a new PlayerAvatar
                if (!playerExists && receivedPlayer.id != playerId) {
                    auto newPlayerAvatar = new PlayerAvatar(renderer, "./assets/test.bmp", 
                        receivedPlayer.x, receivedPlayer.y, receivedPlayer.id , mSocket);
                    otherPlayers ~= newPlayerAvatar;
                    obstacles ~= newPlayerAvatar;
                    gameState.players ~= receivedPlayer;
                }
            }

            // Remove players that are not present in the received gameState
            foreach (otherPlayer; otherPlayers) {
                bool playerFound = false;
                foreach (receivedPlayer; gameStateReceived.players) {
                    if (otherPlayer.id == receivedPlayer.id) {
                        playerFound = true;
                        break;
                    }
                }

                // If the player is not found in the received players list, remove the PlayerAvatar
                if (!playerFound) {
                    obstacles = obstacles.filter!(o => o.get_id() != otherPlayer.id).array;
                    otherPlayers = otherPlayers.filter!(p => p.id != otherPlayer.id).array;
                }
            }        

    }

    /**
     * Compute the number of seconds from start to end of the client.
     * 
     * Returns: A string representing the number of seconds elapsed.
     */
    string playerRewardCreator(){
        immutable SysTime endTime = Clock.currTime;
        immutable auto elapsedTime = endTime - startTime;
        auto secondsElapsed = cast(int) elapsedTime.total!"seconds";
        string secondsString = secondsElapsed.to!string;
        return secondsString;
    } 

   
    /**
     * The main game loop that handles events, player movement, and rendering.
     * It processes SDL events, updates player movement, and renders the game state.
     * @param yourPlayer The player avatar that represents the user in the game.
     */

    void gameLoop(PlayerAvatar yourPlayer){
      bool runApplication = true;
        
        while(runApplication){
                SDL_Event event;
                SDL_PollEvent(&event);
            
                switch(event.type){
                        case SDL_QUIT : 
                            string newPoints = playerRewardCreator();
                            writeln("Yay!! You got awarded ",newPoints," points for this session");
                            runApplication = false;
                            mSocket.send("QUIT:"~yourPlayer.id~":"~newPoints);
                            mSocket.close();
                            chatSocket.close();
                            exit(0);
                        case SDL_KEYDOWN :
                            switch( event.key.keysym.sym)
                                {
                                    case SDLK_UP:
                                    yourPlayer.move_up(obstacles);
                                    // dt.setCamera(0, -1);
                                    break;

                                    case SDLK_DOWN:
                                    yourPlayer.move_down(obstacles);
                                    // dt.setCamera(0, 1); 
                                    break;

                                    case SDLK_LEFT:
                                    yourPlayer.move_left(obstacles);
                                    // dt.setCamera(-1, 0);
                                    break;

                                    case SDLK_RIGHT:
                                    yourPlayer.move_right(obstacles);
                                    // dt.setCamera(1, 0);
                                    break;

                                    default:
                                    writeln("Any other key");
                                    break;
                                }
                            break;
                        default : 
                            break;
                }

                // Clear the screen 
                SDL_SetRenderDrawColor(renderer, 100,190,255,SDL_ALPHA_OPAQUE);
                SDL_RenderClear(renderer);
                dt.render(renderer , zoomFactor);

                yourPlayer.render(renderer);
                foreach (otherPlayer ; otherPlayers) {
                    if(otherPlayer.get_id() == playerId){
                        continue;
                    }
                    otherPlayer.render(renderer);
                }
                
                house1.render(renderer);
                house2.render(renderer);
                house3.render(renderer);
                tree1.render(renderer);
                tree2.render(renderer);
                tree3.render(renderer);
                tree4.render(renderer);
                tree5.render(renderer);
                tree6.render(renderer);
                tree7.render(renderer);
                tree8.render(renderer);

                SDL_RenderPresent(renderer);
                // Artificially slow things down
                SDL_Delay(80);
        }
   }


    /**
     * Initializes and runs the game.
     * It sets up the initial game state, creates player avatars, initializes the tile set,
     * and enters the main game loop.
     * @param newlyCreatedPlayer The player object for the user.
     * @param gameState The initial game state received upon starting the game.
     */

    void runGame(Player newlyCreatedPlayer , GameState gameState){
        
        gameState = gameState;
        yourPlayer = new PlayerAvatar(renderer , "./assets/test.bmp" , 
            newlyCreatedPlayer.x , newlyCreatedPlayer.y , newlyCreatedPlayer.id , mSocket);
        
        playerId = newlyCreatedPlayer.id;
        

        foreach (currPlayer ; gameState.players) {
             if(currPlayer.id == playerId){
                continue;
             }
             auto currAvatar = new PlayerAvatar(renderer , "./assets/test.bmp" , 
                currPlayer.x , currPlayer.y , currPlayer.id , mSocket);
             otherPlayers ~= currAvatar;
             obstacles ~= currAvatar;
        }   

        //obstacles ~= yourPlayer;
       

        //TileSet ts = new TileSet(renderer, "./assets/tilemap.bmp", 16,12,11);
        TileSet ts2 = new TileSet(renderer, "./assets/tilemap_packed.bmp", 16,37,28);
        dt = new DrawableTileMap(ts2);
        zoomFactor = 3;
        
        // run the SDL_render part of the GUI
        gameLoop(yourPlayer);

        // Destroy our Renderer
        SDL_DestroyRenderer(renderer);
        // Destroy our window
        SDL_DestroyWindow(window);
        // Quit the SDL Application 
        SDL_Quit();

        writeln("Ending application--good bye!");
    }    

}


/**
* Unittest for updateGameState() function
*/
unittest {
    /++ Create a mock socket and game renderer.+/
    auto mockSocket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    auto mockChatSocket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
    GameRenderer gameRenderer = new GameRenderer(
        &mockSocket, &mockChatSocket, 
        SysTime(DateTime(2023, 1, 1, 0, 0, 0), UTC()));

    /++ Test 1: Adding and Updating Players.+/
    {
        // Create an initial game state with one player
        GameState initialState;
        initialState.players = [Player( 100, 100, "fan", "fan")];

        // Update the game state with new player information
        GameState newState;
        newState.players = [Player( 100, 100,"fan", "fan"), Player( 400, 400,"nitin","nitin")];

        gameRenderer.updateGameState(newState);

        // Assertions
        assert(gameRenderer.otherPlayers.length == 2, "Two players should be present");
        assert(gameRenderer.otherPlayers[0].id == "fan" , "fan should be updated");
        assert(gameRenderer.otherPlayers[1].id == "nitin", "nitin should be added");
    }

    /++ Test 2: Removing Players.+/
    {
        // Create a game state with two players
        GameState initialState;
        initialState.players = [Player(100, 100,"fan","fan"), Player(400, 400,"nitin", "nitin")];

        // Update the game state to remove one player
        GameState newState;
        newState.players = [Player(100, 100,"fan","fan")];

        gameRenderer.updateGameState(newState);

        // Assertions
        assert(gameRenderer.otherPlayers.length == 1, "Only one player should be present");
        assert(gameRenderer.otherPlayers[0].id == "fan", "fan should remain");
    }

    /++ Test 3: Player Position Update. +/
    {
        // Create a game state with two players
        GameState initialState;
        initialState.players = [Player(100, 100, "fan", "fan"), Player(400, 400, "nitin", "nitin")];
        gameRenderer.gameState = initialState;

        // Update the game state with new positions for the same players
        GameState newState;
        newState.players = [Player(200, 200, "fan", "fan"), Player(500, 500, "nitin", "nitin")];
        gameRenderer.updateGameState(newState);

        // Assertions
        assert(gameRenderer.otherPlayers[0].id == "fan" && 
                gameRenderer.otherPlayers[0].get_x_coordinate() == 200 && 
                gameRenderer.otherPlayers[0].get_y_coordinate() == 200, 
            "fan's position should be updated");
        assert(gameRenderer.otherPlayers[1].id == "nitin" && 
                gameRenderer.otherPlayers[1].get_x_coordinate() == 500 && 
                gameRenderer.otherPlayers[1].get_y_coordinate() == 500, 
            "nitin's position should be updated");
    }

    /++ Test 4: Clearing All Players。 +/
    {
        // Create a game state with two players
        GameState initialState;
        initialState.players = [Player(100, 100, "fan", "fan"), Player(400, 400, "nitin", "nitin")];
        gameRenderer.gameState = initialState;

        // Update the game state with no players
        GameState newState;
        newState.players = [];
        gameRenderer.updateGameState(newState);

        // Assertions
        assert(gameRenderer.otherPlayers.length == 0, "All players should be removed");
    }
}