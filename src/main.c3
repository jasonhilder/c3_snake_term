module snake_boiler;

import std::io;
import snake_boiler::game;
import snake_boiler::input;
import snake_boiler::utils;

App app;
Snake snake;

fn void main()
{
	// setup scene
	app.scene.snake = &snake;
	// todo pass args to start_scene
	app.start_scene();

	// gameloop
    while(app.game_state != GameState.QUIT) {
    	input::handle_inputs(&app);

        if(app.game_state != GameState.GAMEOVER) {

            if(app.game_state != GameState.PAUSED) {
        		game::update(&app);
            }

        	game::render(app);
        }
    }

	// close scene, handle memory, termbox etc
	// pass true/false to enable debugging.
	app.destroy_scene(true);
}