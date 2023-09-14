#include "engine.h"
#include "maze.h"
#include "rat.h"

int main(int, char* [])
{
    // Start up the engine
    if (not engine::init(640, 480))
    {
        engine::close();
        return -1;
    }

    // Start the game
    game::Maze maze;
    try
    {
        maze = game::Maze::fromFile("./assets/maps/maze1.txt");
    }
    catch(const std::exception& e)
    {
        std::cerr << e.what() << '\n';
        return -1;
    }
    
    // Main loop
    bool quit = false;
    int loops = 1;
    while (!quit)
    {
        engine::screen::clear();
        maze.update(SDL_GetTicks());
        maze.draw(117, 37);


        if (loops == 400)
            quit = true;
        loops++;

        engine::screen::show();
    }

    engine::close();

    return 0;
}