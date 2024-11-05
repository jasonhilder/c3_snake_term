module snake_boiler::game;

import std::collections::linkedlist;
import snake_boiler::common;
import snake_boiler::utils;
import termbox2::tb;

def Body = LinkedList(<BodySegment>);

const WIDTH = common::WIDTH;
const HEIGHT = common::HEIGHT;

enum GameState : int (String description)
{
    UNINIT = "Uninitialized",
    RUNNING = "Running",
    PAUSED = "Paused",
    GAMEOVER = "Game Over",
    QUIT = "Quit",
    CLOSED = "Closed"
}

// -----------------------
// STRUCT SETUPS:

struct App
{
    // Info of the games current state
    GameState game_state;
    // Games captured input, handled by termbox
    Tb_event input_event;
    // Scene is what is displayed, map, world etc
    Scene scene; 
}

struct Scene 
{
    char[WIDTH][HEIGHT] grid;
    Snake* snake;
}

struct Snake
{
    char health;
    // Body is defined to be using c3 LinkedList
    // @Note this needs to be free'd
    Body body;
    BodySegment head;
}

struct BodySegment
{
    int pos_x;
    int pos_y;
    char direction;
}

// -----------------------
// APP METHODS:

fn void App.start_scene(App* app)
{
    // termbox stuff
    tb::tb_init();
    tb::tb_set_input_mode(tb::TB_INPUT_ESC);

    // build the initial scene state
    app.scene.build_scene();

    // init Snake
    app.scene.snake.init();

    app.game_state = GameState.RUNNING;
}

fn void App.destroy_scene(App* app, bool debug)
{
    // termbox stuff
    tb::tb_shutdown();

    app.game_state = GameState.CLOSED;

    if(debug == true)
    {
        utils::@print_type(*app);
        utils::@print_type(*app.scene.snake);
    }

    // @todo, free memory
    app.scene.snake.body.free();
}

// -----------------------
// SCENE METHODS:

fn void Scene.build_scene(Scene *scene)
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

    //scene.create_food();
}

// @TODO Create food

// -----------------------
// SNAKE METHODS:
fn void Snake.init(Snake* snake)
{
    // Initialize the body linked list
    // Create the head segment
    BodySegment head;
    head.pos_x = 1;
    head.pos_y = 1;
    head.direction = 'D';

    // Add the head to the body list
    snake.body.push(head);
    snake.head = snake.body.get(0);
}

// -----------------------
// GAME GENERAL FUNCTIONS:

fn void update(App* app)
{
    Scene* scene = &app.scene;
    GameState* game_state = &app.game_state;
    BodySegment* snake_head = &scene.snake.head;
    //int* score = &game_state.score;

    // ----------
    // Variables to track the previous head position
    int prev_pos_x = snake_head.pos_x;
    int prev_pos_y = snake_head.pos_y; 
    char prev_dir = snake_head.direction;    

    // Handle snake head first
    scene.grid[prev_pos_y][prev_pos_x] = ' ';

    // update the head of the snake according to its direction
    switch(snake_head.direction)
    {
        case 'U': snake_head.pos_y -= 1;
        case 'D': snake_head.pos_y += 1;
        case 'L': snake_head.pos_x -= 1;
        case 'R': snake_head.pos_x += 1;
        default: return;
    }

    // Check if the head postion needs to wrap
    if(scene.snake.head.pos_x >= WIDTH - 2) { scene.snake.head.pos_x = 2; } 
    else if(scene.snake.head.pos_x == 0) { scene.snake.head.pos_x = WIDTH - 3; }

    // Check if the head postion needs to wrap
    if(scene.snake.head.pos_y >= HEIGHT - 1) { scene.snake.head.pos_y = 1; } 
    else if(scene.snake.head.pos_y == 0) { scene.snake.head.pos_y = HEIGHT - 2; }

    // draw the head in its place
    scene.grid[snake_head.pos_y][snake_head.pos_x] = '*';

    // ----------
    // Update snake body according to the snake heads update.
    // @TODO
}

fn void render(App app)
{
    //int score = app.score;
    Scene scene = app.scene;
    GameState game_state = app.game_state;


    foreach(row_index, row : scene.grid)
    {
        foreach(col_index, col_val : row) {
            tb::tb_printf((int)col_index, (int)row_index, 0, 0, "%c", col_val);

            // print some ui
            if(col_index == WIDTH - 1) {
                switch(row_index)
                {
                    case(0):
                        tb::tb_print((int)col_index + 1, 0, 0, 0, " INSTRUCTIONS:");
                    case(1):
                        tb::tb_print((int)col_index + 1, 1, 0, 0, " (W,A,S,D) Move snake.");
                    case(2):
                        tb::tb_print((int)col_index + 1, 2, 0, 0, " Press 'q' to end game.");
                    case(3):
                        tb::tb_print((int)col_index + 1, 3, 0, 0, " Press 'spacebar' to pause game.");
                    //case(4):
                        //tb::tb_printf((int)col_index + 1, 4, 0, 0, " Score: %d", score);
                    case(5):
                        tb::tb_printf((int)col_index + 1, 5, 0, 0, " Game Info: %s", app.game_state.description);
                }
            }
        }
    }

    tb::tb_present();
}

