module snake_game;

import termbox;

import std::io;
import std::thread;
import std::time;

const uint WIDTH = 50;
const uint HEIGHT = 26;

struct GameState {
   Scene scene; 
   bool is_running;
   bool is_paused;
   termbox::TbEvent event;
}

struct Scene {
    char[WIDTH][HEIGHT] grid;
    Player* player;
} 

struct Player {
   int posX;
   int posY;
   char direction;
}

fn void clear_terminal() {
    // ANSI escape code to clear the terminal
    io::printf("\x1b[2J\x1b[H");
}

fn void init_scene(Scene *scene)
{
    for(int i = 0; i < WIDTH - 1; i++) 
    {
        scene.grid[0][i] = '#';
        scene.grid[HEIGHT - 1][i] = '#';
    }

    for(int i = 0; i < WIDTH - 1; i++)
    {
        for(int h = 1; h < HEIGHT - 1; h++)
        {
            if(i == 0) {
               scene.grid[h][i] = '#';
            } else if(i == WIDTH - 2) {
               scene.grid[h][i] = '#';
            } else {
               scene.grid[h][i] = ' ';
            }
        }
    }
}

fn void update_player(Scene *scene) {
    scene.grid[scene.player.posY][scene.player.posX] = ' ';

    scene.player.posX += 1;
    if(scene.player.posX >= WIDTH - 2) {
        scene.player.posX = 1;
    }

    //scene.player.posY += 1;
    if(scene.player.posY >= HEIGHT - 2) {
        scene.player.posY = 1;
    }

    scene.grid[scene.player.posY][scene.player.posX] = '*';
}

fn void update_state(GameState *game_state)
{
    update_player(game_state.scene);
}

fn void render_scene(Scene scene)
{
    foreach(idx, row : scene.grid)
    {
        foreach(ri, tile : row) {
            io::printf("%c", tile);

            if(ri == WIDTH - 1) {
                if(idx == 0) {
                   io::print(" INSTRUCTIONS:");
                }
                if(idx == 1) {
                    io::print(" (W,A,S,D) Move snake.");
                }
                if(idx == 2) {
                    io::print(" Press 'q' to end game.");
                }
                if(idx == 3) {
                    io::print(" Press 'spacebar' to pause game.");
                }
            }
        }

        io::print("\n");
    }
}


fn void main() 
{
    // -----------------------------------------

    const float TARGET_FPS = 30;
    const float FRAME_DURATION = 1.0 / TARGET_FPS;
    const float MOVE_INTERVAL = 0.2;

    // -----------------------------------------

    Player player = {
        .posX = 24,
        .posY = 12
    };

    GameState game_state = {
        .scene = {
            .grid = char[WIDTH][HEIGHT] {},
            .player = &player
        },
        .is_running = true,
        .is_paused = false
    };

    //termbox::tb_init();
    //termbox::tb_set_input_mode(termbox::TB_INPUT_ESC);

    init_scene(&game_state.scene);
    Time previous_time = time::now();
    float accumulated_time = 0.0; 

    while(true) {
        Time start_time = time::now();
        float delta_time = (float)time::Time.diff_sec(start_time, previous_time);  

        previous_time = start_time;
        accumulated_time += delta_time;

        if (accumulated_time >= MOVE_INTERVAL) {
            accumulated_time -= MOVE_INTERVAL; 
            update_state(&game_state);
        }
        // ------------------------------------------------------

        clear_terminal();      
        render_scene(game_state.scene);

        // ------------------------------------------------------
        // Calculate elapsed time since the frame started
        float elapsed_time = (float)time::Time.diff_sec(time::now(), start_time);
        // Calculate remaining sleep time for consistent FPS
        float sleep_time = FRAME_DURATION - elapsed_time;

        if(sleep_time > 0) {
            ulong sleep_time_ms = (ulong)(sleep_time * 1000); 
            thread::sleep_ms(sleep_time_ms);
        }

        // ------------------------------------------------------
        /*
        termbox::tb_poll_event(&event);

        if (event.type == termbox::TB_EVENT_KEY) {
            if (event.ch == 'a') {
                termbox::tb_print(0, 0, 0, 0, "A pressed");
                termbox::tb_present();
            }

            if (event.ch == 'q') {
                running = 0;  // Quit on 'q'
            }
        }

        termbox::tb_clear();
        */
    }
    //termbox::tb_shutdown();
}
/*
   @TODO
   - termbox2 for input checking during game loop
   - Player or like Entity Structs (Snake and food)
*/