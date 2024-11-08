module snake_boiler::game;

import std::math::random;
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
    // Playes current score
    int score;
}

struct Scene 
{
    char[WIDTH][HEIGHT] grid;
    Snake* snake;
    Food* food;
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

struct Food {
    int pos_x;
    int pos_y;
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

    scene.create_food();
}

// @TODO Create food
fn void Scene.create_food(Scene *scene)
{
    int x = random::rand_in_range(2, WIDTH - 3);
    int y = random::rand_in_range(2, HEIGHT - 3);

    scene.food.pos_x = x;
    scene.food.pos_y = y;

    scene.grid[scene.food.pos_y][scene.food.pos_x] = '$';
}

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
    int* score = &app.score;
    GameState* game_state = &app.game_state;
    BodySegment* snake_head = &scene.snake.head;

    // ----------
    // Variables to track the previous head position
    int prev_pos_x = snake_head.pos_x;
    int prev_pos_y = snake_head.pos_y; 
    char prev_dir = snake_head.direction;    

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
    if(snake_head.pos_x >= WIDTH - 2) { snake_head.pos_x = 2; } 
    else if(snake_head.pos_x == 0) { snake_head.pos_x = WIDTH - 3; }

    // Check if the head postion needs to wrap
    if(snake_head.pos_y >= HEIGHT - 1) { snake_head.pos_y = 1; } 
    else if(snake_head.pos_y == 0) { snake_head.pos_y = HEIGHT - 2; }

    // ----------
    // Update snake body according to the snake heads update.
    usz count = scene.snake.body.len();

    for (int i = 0; i < count; i++) {
        if(i == 0) {
            // handle snake head draw the head in its place
            scene.grid[prev_pos_y][prev_pos_x] = ' ';
            scene.grid[snake_head.pos_y][snake_head.pos_x] = '*';
            continue;
        }

        BodySegment current = scene.snake.body.get(i);

        if(snake_head.pos_x == current.pos_x && snake_head.pos_y == current.pos_y)
        {
            *game_state = GameState.GAMEOVER;
            return;
        }

        scene.grid[current.pos_y][current.pos_x] = ' ';

        // store the current body's pos in temp variables
        int temp_pos_x = current.pos_x;
        int temp_pos_y = current.pos_y;
        char temp_direction = current.direction;

        // update the bodys spot to be the heads original location
        current.pos_x = prev_pos_x;
        current.pos_y = prev_pos_y;
        current.direction = prev_dir;

        // update the previous pos for the next body segment.
        prev_pos_x = temp_pos_x;
        prev_pos_y = temp_pos_y;
        prev_dir = temp_direction;

        scene.grid[current.pos_y][current.pos_x] = '*';
        scene.snake.body.set(i, current);
    }

    // ----------
    // Handle food eaten
    if( snake_head.pos_y == scene.food.pos_y && 
        snake_head.pos_x == scene.food.pos_x )
    {
        // Find the last chunk (tail) of the snake
        BodySegment tail = scene.snake.body.last()!!;
        BodySegment new_body;
        new_body.pos_y = tail.pos_x;
        new_body.pos_x = tail.pos_y;
        new_body.direction = tail.direction;
        switch (tail.direction) {
            case 0: new_body.pos_y += 1; break;
            case 1: new_body.pos_y -= 1; break; 
            case 2: new_body.pos_x += 1; break;
            case 3: new_body.pos_x -= 1; break; 
        }

        scene.snake.body.push(tail);

        *score += 5;
        scene.create_food();
    }
}

fn void render(App app)
{
    int score = app.score;
    Scene scene = app.scene;
    GameState game_state = app.game_state;

    tb::tb_clear();

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
                    case(4):
                        tb::tb_printf((int)col_index + 1, 4, 0, 0, " Score: %d", score);
                    case(5):
                        tb::tb_printf((int)col_index + 1, 5, 0, 0, " Game Info: %s", app.game_state.description);
                }
            }
        }
    }

    tb::tb_present();
}

