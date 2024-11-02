module snake_boiler::input;

import termbox2::tb;
import snake_boiler::game;

fn void handle_inputs(game::App* app)
{
    if(tb::tb_peek_event(&app.input_event, 500) != -6) 
    {
        // input_event is a keypress here.
        if (app.input_event.type == tb::TB_EVENT_KEY) 
        {
            // Store the current head direction before updating it
            char current_direction = app.scene.snake.head.direction;

            // keypress events use the ch field
            switch(app.input_event.ch)
            {
                case 'w':
                    // prevent reversing
                    if(current_direction != 'D' && app.game_state == GameState.RUNNING) {
                        app.scene.snake.head.direction = 'U';
                    }
                case 'a':
                    if(current_direction != 'R' && app.game_state == GameState.RUNNING) {
                        app.scene.snake.head.direction = 'L';
                    }
                case 's':
                    if(current_direction != 'U' && app.game_state == GameState.RUNNING) {
                        app.scene.snake.head.direction = 'D';
                    }
                case 'd':
                    if(current_direction != 'L' && app.game_state == GameState.RUNNING) {
                        app.scene.snake.head.direction = 'R';
                    }
                case 'q':
                    app.game_state = game::GameState.QUIT;
                default:
                    return;
            }
        }
    }
}
