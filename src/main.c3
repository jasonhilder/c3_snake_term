module snake_game;

import termbox;

import std::io;
import std::thread;
import std::time;
import std::math::random;
import std::core::mem;

const uint WIDTH = 25;
const uint HEIGHT = 20;

struct GameState 
{
   Scene scene; 
   bool is_running;
   bool is_paused;
   bool is_updating;
   termbox::TbEvent event;
}

struct Chunk {
   int posX;
   int posY;
   char direction;
   Chunk* next;
}

struct Player 
{
   int posX;
   int posY;
   ushort health;
   Chunk* head;
   // tail maybe?? on new allocation set tail accordingly
}

struct Food {
   int posX;
   int posY;
   char health;
}

struct Scene 
{
    char[WIDTH][HEIGHT] grid;
    Player* player;
    Food* food;
} 

fn void Player.free_body(Player player) {
    Chunk* current = player.head;

    while (current != null) {
        Chunk* next = current.next;
        mem::free(current);
        current = next;
    }

}

fn void Scene.create_food(Scene *scene) 
{
    int x = random::rand_in_range(2, WIDTH - 3);
    int y = random::rand_in_range(2, HEIGHT - 3);

    scene.food.posX = x;
    scene.food.posY = y;
    scene.food.health = 1;

    scene.grid[scene.food.posY][scene.food.posX] = '$';
}

fn void Scene.init_scene(Scene *scene)
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

fn void update_player(Scene *scene) 
{
    // Variables to track the old tail's position
    int old_tail_x;
    int old_tail_y;    

    // loop over body if it exists
    if(scene.player.head.next == null) {
        // Clear the trail
        scene.grid[scene.player.head.posY][scene.player.head.posX] = ' ';
    } else {
        Chunk* current = scene.player.head;
        Chunk* next = scene.player.head.next;


        while(next != null) {

            if(next.next == null) {
                old_tail_x = next.posX;
                old_tail_y = next.posY; 
            };

            // store previous co ords
            int next_x = next.posX;
            int next_y = next.posY;

            // Update next
            int next_new_x = current.posX;
            int next_new_y = current.posY;
            char next_new_dir = current.direction;

            next.posX = next_new_x;
            next.posY = next_new_y;
            next.direction = next_new_dir;

            current = next;
            next = next.next;
        }

        // Clear the old tail position on the grid
        scene.grid[old_tail_y][old_tail_x] = ' ';
    } 

    switch(scene.player.head.direction)
    {
        case 0: scene.player.head.posY -= 1;
        case 1: scene.player.head.posY += 1;
        case 2: scene.player.head.posX -= 1;
        case 3: scene.player.head.posX += 1;
        default: return;
    }

    if(scene.player.head.posX >= WIDTH - 2) {
        scene.player.head.posX = 2;
    } else if(scene.player.head.posX == 0) {
        scene.player.head.posX = WIDTH - 3;
    }

    if(scene.player.head.posY >= HEIGHT - 1) {
        scene.player.head.posY = 1;
    } else if(scene.player.head.posY == 0) {
        scene.player.head.posY = HEIGHT - 2;
    }

    if( scene.player.head.posY == scene.food.posY && 
        scene.player.head.posX == scene.food.posX )
    {
        // Find the last chunk (tail) of the snake
        Chunk* tail = scene.player.head;
        while (tail.next != null) {
            tail = tail.next;
        }

        Chunk* new_body = mem::malloc(Chunk.sizeof);
        new_body.posX = tail.posX;
        new_body.posY = tail.posY;
        new_body.direction = tail.direction;
        new_body.next = null;
        tail.next = new_body;

        scene.food.health = 0; 
    }

    scene.grid[scene.player.head.posY][scene.player.head.posX] = '*';
}

fn void update_state(GameState *game_state)
{
    if(termbox::tb_peek_event(&game_state.event, 500) != -6) 
    {
        if (game_state.event.type == termbox::TB_EVENT_KEY) 
        {
            // 0 == up, 1 == down, 2 == left, 3 == right
            switch(game_state.event.ch)
            {
                case 'w':
                    game_state.scene.player.head.direction = 0;
                case 'a':
                    game_state.scene.player.head.direction = 2;
                case 's':
                    game_state.scene.player.head.direction = 1;
                case 'd':
                    game_state.scene.player.head.direction = 3;
                case 'q':
                    game_state.is_running = false;
                default:
                    game_state.scene.player.head.direction = game_state.scene.player.head.direction;
            }
        }
    }

    update_player(&game_state.scene);

    if(game_state.scene.food.health == 0) {
       game_state.scene.create_food();
    }

    // check player health
}

fn void render_scene(Scene scene)
{
    foreach(row_index, row : scene.grid)
    {
        //io::printn(row_index);
        foreach(col_index, col_val : row) {
            termbox::tb_printf((int)col_index, (int)row_index, 0, 0, "%c", col_val);

            if(col_index == WIDTH - 1) {
                switch(row_index)
                {
                    case(0):
                        termbox::tb_print((int)col_index + 1, 0, 0, 0, " INSTRUCTIONS:");
                    case(1):
                        termbox::tb_print((int)col_index + 1, 1, 0, 0, " (W,A,S,D) Move snake.");
                    case(2):
                        termbox::tb_print((int)col_index + 1, 2, 0, 0, " Press 'q' to end game.");
                    case(3):
                        termbox::tb_print((int)col_index + 1, 3, 0, 0, " Press 'spacebar' to pause game.");
                }
            }
        }
    }
    termbox::tb_present();
}



fn void main() 
{
    // -----------------------------------------
    const float TARGET_FPS = 100;
    const float FRAME_DURATION = 1.0 / TARGET_FPS;
    const float MOVE_INTERVAL = 0.1;

    // -----------------------------------------

    Chunk head = {
        .direction = 1,
        .posX = 24,
        .posY = 12,
        .next = null
    };

    Player player = {
        .health = 1,
        .head = &head
    };

    Food food = {
        .posX = 0, 
        .posY = 0, 
        .health = 1
    };

    GameState game_state = {
        .scene = {
            .grid = char[WIDTH][HEIGHT] {},
            .player = &player,
            .food = &food
        },
        .is_running = true,
        .is_paused = false,
        .is_updating = false
    };

    // -----------------------------------------

    game_state.scene.init_scene();
    termbox::tb_init();
    termbox::tb_set_input_mode(termbox::TB_INPUT_ESC);

    // -----------------------------------------
    Time previous_time = time::now();
    float accumulated_time = 0.0; 

    while(game_state.is_running) {
        Time start_time = time::now();

        termbox::tb_clear();
        update_state(&game_state);
        render_scene(game_state.scene);

        // ------------------------------------------------------

        // Calculate elapsed time since the frame started
        float elapsed_time = (float)time::Time.diff_sec(time::now(), start_time);
        // Calculate remaining sleep time for consistent FPS
        float sleep_time = FRAME_DURATION - elapsed_time;

        if(sleep_time > 0) 
        {
            ulong sleep_time_ms = (ulong)(sleep_time * 1000); 
            thread::sleep_ms(sleep_time_ms);
        }
    }

    //cleanup memory of player
    player.free_body();
    termbox::tb_shutdown();
}

/*
   @TODO
    - Print each piece of body
    - sort out memory freeing/cleanup
*/