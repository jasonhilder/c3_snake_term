module termbox;

/* An incoming event from the tty.
 *
 * Given the event type, the following fields are relevant:
 *
 *    when `TB_EVENT_KEY`: `key` xor `ch` (one will be zero) and `mod`. Note
 *                         there is overlap between `TB_MOD_CTRL` and
 *                         `TB_KEY_CTRL_*`. `TB_MOD_CTRL` and `TB_MOD_SHIFT` are
 *                         only set as modifiers to `TB_KEY_ARROW_*`.
 *
 * when `TB_EVENT_RESIZE`: `w` and `h`
 *
 *  when `TB_EVENT_MOUSE`: `key` (`TB_KEY_MOUSE_*`), `x`, and `y`
 */
struct TbEvent {
    char type; // one of `TB_EVENT_*` constants
    char mod;  // bitwise `TB_MOD_*` constants
    ushort key; // one of `TB_KEY_*` constants
    uint ch;  // a Unicode codepoint
    int w;    // resize width
    int h;    // resize height
    int x;    // mouse x
    int y;    // mouse y
}

/* Input modes (bitwise) (`tb_set_input_mode`) */
const int TB_INPUT_CURRENT = 0;
const int TB_INPUT_ESC = 1;
const int TB_INPUT_ALT = 2;
const int TB_INPUT_MOUSE = 4;

const uint TB_EVENT_KEY = 1;

extern fn int tb_init();
extern fn int tb_clear();
extern fn int tb_shutdown();

extern fn int tb_width();
extern fn int tb_height();
extern fn int tb_peek_event(TbEvent *event, int timeout_ms);
extern fn int tb_poll_event(TbEvent *event);
extern fn int tb_set_input_mode(int mode);

extern fn int tb_print(int x, int y, ulong fg, ulong bg, char* str);
extern fn int tb_printf(int x, int y, ulong fg, ulong bg, char*fmt, ...);
extern fn int tb_present();