module snake_game;

import std::io;
import std::thread;
import std::time;

const uint WIDTH = 50;
const uint HEIGHT = 25;

struct Scene {
   char[WIDTH][HEIGHT] grid;
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

fn void update_scene(Scene *scene)
{
   // testing updating the scene 
   scene.grid[12][25] = '*';
   scene.grid[5][14] = '$';
}

fn void render_scene(Scene scene)
{
   foreach(idx, row : scene.grid)
   {
      foreach(ri, tile : row) {
         io::printf("%c", tile);
         if(ri == WIDTH - 1) {
            if(idx == 0) {
               io::print(" SNAkE GAME");
            }
            if(idx == 1) {
               io::print(" INSTRUCTIONS");
            }
         }
      }
      io::print("\n");
   }
}


fn void main() 
{
   Scene scene; 

   init_scene(&scene);

   while(true) {

      clear_terminal();      

      update_scene(&scene);

      render_scene(scene);

      // @todo need a better way of handling fps
      thread::sleep_ms(16);

   }
}

/*

*/