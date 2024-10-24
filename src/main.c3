import std::io;
import std::thread;
import std::time;

const uint WIDTH = 50;
const uint HEIGHT = 25;

fn void clear_terminal() {
    // ANSI escape code to clear the terminal
    io::printf("\x1b[2J\x1b[H");
}

fn void draw_square()
{
   for(int i = 0; i <= WIDTH; i++) {
      io::printf("#");
   }
   io::printf("\n");

   for(int i = 0; i < HEIGHT; i++) {
      io::printf("#");
      io::printf("%*s#\n", WIDTH-1, "");
   }

   for(int i = 0; i <= WIDTH; i++) {
      io::printf("#");
   }
   io::printf("\n");
}

fn void main() 
{

   while(true) {
      clear_terminal();      
      draw_square();

      thread::sleep_ms(16);
   }
}

/*
   Could set the original square in a buffer as the original one
*/
