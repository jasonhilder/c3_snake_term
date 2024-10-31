module snake_game;

import termbox;

import std::io;
import std::thread;
import std::time;
import std::math::random;
import std::core::mem;

const uint WIDTH = 25;
const uint HEIGHT = 20;

enum LoopState : int (String description)
{
    RUNNING = "Running",
    PAUSED = "Paused",
    GAMEOVER = "Game Over",
    QUIT = "Quit"
}

struct GameState 
{
    Scene scene; 
    LoopState loop_state;
    int score;
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

macro @print_type(value)
{
    var $Type = $typeof(value);

    $if $Type.kindof != STRUCT:
        io::print(value);

    $else

        io::print("{\n");
        $foreach ($i, $member : $Type.membersof)
            $if $i > 0:
                io::print(",\n");
            $endif

            $if $member.nameof != "":
                io::printf("    %s : ", $member.nameof);
                @print_type($member.get(value));
            $endif   
        $endforeach

        io::print("\n}\n");

    $endif
}

fn void Player.free_body(Player player) {
    Chunk* current = player.head.next;

    while (current != null) {
        Chunk* next = current.next;
        (void)free(current);
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

fn void update_player(GameState* game_state) 
{
    Scene* scene = &game_state.scene;
    int* score = &game_state.score;
    LoopState* loop_state = &game_state.loop_state;

    // Now update the positions of all segments based on their direction
    Chunk* snake_head = scene.player.head;

    scene.grid[snake_head.posY][snake_head.posX] = ' ';

    // Variables to track the previous head position
    int prevPosX = snake_head.posX;
    int prevPosY = snake_head.posY;    
    char prevDir = snake_head.direction;    

    // update the head of the snake according to its direction
    switch(snake_head.direction)
    {
        case 0: snake_head.posY -= 1;
        case 1: snake_head.posY += 1;
        case 2: snake_head.posX -= 1;
        case 3: snake_head.posX += 1;
        default: return;
    }

    // Check if the head postion needs to wrap
    if(scene.player.head.posX >= WIDTH - 2) { scene.player.head.posX = 2; } 
    else if(scene.player.head.posX == 0) { scene.player.head.posX = WIDTH - 3; }

    // Check if the head postion needs to wrap
    if(scene.player.head.posY >= HEIGHT - 1) { scene.player.head.posY = 1; } 
    else if(scene.player.head.posY == 0) { scene.player.head.posY = HEIGHT - 2; }

    // draw the head in its place
    scene.grid[snake_head.posY][snake_head.posX] = '*';

    // get the next body part
    Chunk* current = snake_head.next;
    while(current != null)
    {
        if(snake_head.posX == current.posX && snake_head.posY == current.posY)
        {
            *loop_state = LoopState.GAMEOVER;
            return;
        }

        scene.grid[current.posY][current.posX] = ' ';

        // store the body's pos in temp variables
        int tempPosX = current.posX;
        int tempPosY = current.posY;
        char tempDirection = current.direction;

        // update the bodys spot to be the heads original location
        current.posX = prevPosX;
        current.posY = prevPosY;

        // update the previous pos for the next body segment.
        prevPosX = tempPosX;
        prevPosY = tempPosY;
        prevDir = tempDirection;

        scene.grid[current.posY][current.posX] = '*';
        current = current.next;
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
        switch (tail.direction) {
            case 0: new_body.posY += 1; break;
            case 1: new_body.posY -= 1; break; 
            case 2: new_body.posX += 1; break;
            case 3: new_body.posX -= 1; break; 
        }

        new_body.next = null;
        tail.next = new_body;

        scene.food.health = 0; 
        score += 5;
    }
}

fn void update_input(GameState *game_state)
{
    if(termbox::tb_peek_event(&game_state.event, 500) != -6) 
    {
        // Store the current head direction before updating it
        char current_direction = game_state.scene.player.head.direction;

        if (game_state.event.type == termbox::TB_EVENT_KEY) 
        {
            // 0 == up, 1 == down, 2 == left, 3 == right
            switch(game_state.event.ch)
            {
                case 'w':
                    // prevent reversing
                    if(current_direction != 1 && game_state.loop_state == LoopState.RUNNING) {
                        game_state.scene.player.head.direction = 0;
                    }
                case 'a':
                    if(current_direction != 3 && game_state.loop_state == LoopState.RUNNING) {
                        game_state.scene.player.head.direction = 2;
                    }
                case 's':
                    if(current_direction != 0 && game_state.loop_state == LoopState.RUNNING) {
                        game_state.scene.player.head.direction = 1;
                    }
                case 'd':
                    if(current_direction != 2 && game_state.loop_state == LoopState.RUNNING) {
                        game_state.scene.player.head.direction = 3;
                    }
                // spacebar
                case termbox::TB_KEY_SPACE:
                    if(game_state.loop_state == LoopState.RUNNING) {
                        game_state.loop_state = LoopState.PAUSED; 
                    } else if(game_state.loop_state == LoopState.PAUSED) {
                        game_state.loop_state = LoopState.RUNNING; 
                    }
                case 'q':
                    game_state.loop_state = LoopState.QUIT;
                default:
                    game_state.scene.player.head.direction = game_state.scene.player.head.direction;
            }
        }
    }
}

fn void update_state(GameState *game_state)
{
    //update_player(&game_state.scene, &game_state.score);
    update_player(game_state);

    if(game_state.scene.food.health == 0) {
       game_state.scene.create_food();
    }

    // check player health
    // NOTE TODO
}

//fn void render_scene(Scene scene, int score)
fn void render_scene(GameState game_state)
{
    Scene scene = game_state.scene;
    int score = game_state.score;
    LoopState loop_state = game_state.loop_state;

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
                    case(4):
                        termbox::tb_printf((int)col_index + 1, 4, 0, 0, " Score: %d", score);
                    case(5):
                        termbox::tb_printf((int)col_index + 1, 5, 0, 0, " Game Info: %s", loop_state.description);
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
        .posX = 1,
        .posY = 1,
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
        .loop_state = LoopState.RUNNING
    };

    // -----------------------------------------

    game_state.scene.init_scene();
    termbox::tb_init();
    termbox::tb_set_input_mode(termbox::TB_INPUT_ESC);

    // -----------------------------------------
    Time previous_time = time::now();
    float accumulated_time = 0.0; 

    while(game_state.loop_state != LoopState.QUIT) {
        Time start_time = time::now();
        update_input(&game_state);

        if(game_state.loop_state != LoopState.GAMEOVER) {
            termbox::tb_clear();

            if(game_state.loop_state != LoopState.PAUSED) {
                update_state(&game_state);
            }

            render_scene(game_state);

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
    }

    //cleanup memory of player
    termbox::tb_shutdown();

    @print_type(game_state);
    Chunk* segment = player.head;
    while(segment != null) {
        @print_type(*segment);
        segment = segment.next;
    }
    player.free_body();
}

/*
   @TODO
   - store the tail for less looping
   - track if the player dies
*/
