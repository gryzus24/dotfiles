## # # #
# -* Cute curses menu module *-
#
# Any use, in the broadest sense of 'any' and 'use', of the following code,
# under threat of affliction with dispassion, prohibited by its own author:
#
#  Copyright (C) 2026 Gryzus
##

import curses
import os

# This is meant to be marked as typing.Protocol, but to make the module
# import faster don't import typing just to mark it as such, the caller
# is a serious man and can deal with it himself.
class Operations:
    # refresh() -> (header, lines, align)
    def refresh(self) -> tuple[str, list[str], list[int]]: ...
    # update_cell(cy of lines, cx of align, text) -> error | None
    def update_cell(self, cy: int, cx: int, text: str) -> str | None: ...

YX    = tuple[int, int]
XAttr = tuple[int, int]

def mvaddstr(win: curses.window, y: int, x: int, s: str, attr: int = 0) -> None:
    try: win.addstr(y, x, s, attr) if attr else win.addstr(y, x, s)
    except curses.error: pass

def mvchgat(win: curses.window, y: int, x: int, n: int, attr: int) -> None:
    try: win.chgat(y, x, n, attr)
    except curses.error: pass

class Cursor:
    __slots__ = ('cy', 'cx', 'cy_max', 'cx_max')
    def __init__(self, cy: int, cx: int, cy_max: int, cx_max: int) -> None:
        self.cy = max(min(cy, cy_max), 0)
        self.cx = max(min(cx, cx_max), 0)
        self.cy_max = cy_max
        self.cx_max = cx_max

    @property
    def cyx(self)   -> YX: return self.cy, self.cx
    def up(self)    -> None: self.cy = max(self.cy - 1, 0)
    def down(self)  -> None: self.cy = min(self.cy + 1, self.cy_max)
    def left(self)  -> None: self.cx = max(self.cx - 1, 0)
    def right(self) -> None: self.cx = min(self.cx + 1, self.cx_max)
    def top(self)   -> None: self.cy = 0
    def bot(self)   -> None: self.cy = self.cy_max
    def beg(self)   -> None: self.cx = 0
    def end(self)   -> None: self.cx = self.cx_max

class Prompt:
    __slots__ = ('i', 'text')
    def __init__(self) -> None:
        self.i = 0
        self.text = ''

    def left(self)  -> None: self.i = max(self.i - 1, 0)
    def right(self) -> None: self.i = min(self.i + 1, len(self.text))
    def home(self)  -> None: self.i = 0
    def end(self)   -> None: self.i = len(self.text)
    def insert(self, s: str) -> None:
        self.text = self.text[:self.i] + s + self.text[self.i:]
        self.i += len(s)
    def delete(self) -> None:
        self.text = self.text[:self.i] + self.text[self.i + 1:]
    def backspace(self) -> None:
        j = max(self.i - 1, 0)
        self.text = self.text[:j] + self.text[self.i:]
        self.i = j
    def delete_word(self) -> None:
        i = self.i; t = self.text
        while (i := i - 1) > 0:
            if t[i] != ' ' and t[i - 1] == ' ':
                break
        i = max(i, 0)
        self.i = i; self.text = t[:i]

HELP_DEFAULT = True

class Options:
    __slots__ = ('sep', 'help_default', 'active_cb', 'cursor_ul', 'select_ul',
                 'x_keep')
    def __init__(self) -> None:
        self.sep = '  '
        self.help_default = HELP_DEFAULT
        self.active_cb: tuple[int, ...] = ()
        self.cursor_ul: XAttr = (-1, 0)
        self.select_ul: XAttr = (-1, 0)
        self.x_keep = 0

class State:
    __slots__ = ('cursor', 'vscroll', 'hscroll', 'help')
    def __init__(self,
                 cursor: YX = (0, 0),
                 vscroll: int = 0,
                 hscroll: int = 0,
                 help: bool = HELP_DEFAULT) -> None:
        self.cursor = cursor
        self.vscroll = vscroll
        self.hscroll = hscroll
        self.help = help

def _curses_menu(win: curses.window, header: str, lines: list[str],
                 align: list[int], opts: Options, ops: Operations,
                 st: State) -> State | None:
    HEADER = 1
    X_OFF  = 0
    RED    = curses.color_pair(1)
    GREEN  = curses.color_pair(2)

    HEIGHT = WIDTH = 0
    def update_height_width() -> None:
        nonlocal HEIGHT, WIDTH
        HEIGHT = curses.LINES - HEADER - st.help
        WIDTH  = curses.COLS - X_OFF

    update_height_width()

    xn_map = align
    x_map = [0]
    for a in align:
        x_map.append(x_map[-1] + len(opts.sep) + a)

    x_keep = opts.x_keep
    assert 0 <= x_keep <= x_map[-1] + xn_map[-1]

    x_keep_nr_fields = 0
    if x_keep:
        i = 0
        while x_map[i] < x_keep:
            i += 1
        x_keep_nr_fields = i

    cur = Cursor(*st.cursor, len(lines) - 1, len(align) - 1)
    sel: set[YX] = set()
    sel_tmp = False

    prompt = Prompt()
    prompt_on = False
    errors: dict[YX, str] = {}

    help = 'F1/? help  (d/D)s/S (de)select/column  Enter/Esc prompt  ^L refresh'
    help_attr_xn = [
        (help.index('F'), 4),
        (help.index('('), 8),
        (help.index('E'), 9),
        (help.index('^'), 2)
    ]

    def check_scroll() -> None:
        if cur.cy <= st.vscroll:
            st.vscroll = cur.cy
        elif cur.cy > (z := st.vscroll + HEIGHT - 1):
            st.vscroll += cur.cy - z
        view_x = st.hscroll + x_keep
        view_end = st.hscroll + WIDTH
        if (x := x_map[cur.cx]) <= view_x:
            st.hscroll = max(st.hscroll - (view_x - x), 0)
        elif (x_end := x + xn_map[cur.cx]) > view_end:
            st.hscroll += x_end - view_end

    check_scroll()

    def real_xn(cx: int, *, top: bool = False) -> tuple[int, int]:
        x = x_map[cx]; n = xn_map[cx]
        if cx < x_keep_nr_fields:
            if x_keep:
                n = max(n - st.hscroll, x_keep - len(opts.sep), 0)
            return X_OFF + x, n
        x -= st.hscroll
        if x < 0:
            n += x; x = 0
        if not top and (d := x_keep - x) > 0:
            x += d; n -= d
        return X_OFF + x, max(n, 0)

    def real_y(cy: int) -> int:
        return HEADER + cy - st.vscroll

    def draw_line(y: int, item: str, attr: int) -> None:
        cut      = max(x_map[x_keep_nr_fields] - st.hscroll, x_keep)
        view_x   = st.hscroll + cut
        view_end = st.hscroll + WIDTH
        if x_keep:
            cut_sepless = max(cut - len(opts.sep), 0)
            mvaddstr(win, y, X_OFF, item[:cut_sepless], attr)
        mvaddstr(win, y, X_OFF + cut, item[view_x:view_end], attr)

    def draw_hl(cy: int, cx: int, attr: int, *, top: bool = False) -> None:
        if HEADER <= (y := real_y(cy)) <= HEIGHT:
            mvchgat(win, y, *real_xn(cx, top=top), attr)

    def draw_ul(cy: int, cxattr: XAttr) -> None:
        cx, attr = cxattr
        if cx != -1:
            draw_hl(cy, cx, attr, top=True)

    def sel_attr(cx: int) -> int:
        return (GREEN if cx in opts.active_cb else RED) | curses.A_STANDOUT

    up           = lambda: cur.up() or check_scroll()
    down         = lambda: cur.down() or check_scroll()
    left         = lambda: cur.left() or check_scroll()
    right        = lambda: cur.right() or check_scroll()
    top          = lambda: cur.top() or check_scroll()
    bot          = lambda: cur.bot() or check_scroll()
    beg          = lambda: cur.beg() or check_scroll()
    end          = lambda: cur.end() or check_scroll()
    select       = lambda: sel.add(cur.cyx)
    deselect     = lambda: sel.discard(cur.cyx)
    select_down  = lambda: select() or cur.down()
    select_all   = lambda: [sel.add((y, cur.cx)) for y, _ in enumerate(lines)]
    deselect_all = lambda: [sel.discard((y, cur.cx)) for y, _ in enumerate(lines)]
    resize       = lambda: (curses.update_lines_cols() or
                            update_height_width() or
                            check_scroll())
    actions = {
        b'k'         : up,    b'KEY_UP'   : up,
        b'j'         : down,  b'KEY_DOWN' : down,
        b'h'         : left,  b'KEY_LEFT' : left,
        b'l'         : right, b'KEY_RIGHT': right,
        b'g'         : top,
        b'G'         : bot,
        b'^'         : beg,   b'0': beg,
        b'$'         : end,
        b's'         : select,
        b'S'         : select_all,
        b' '         : select_down,
        b'd'         : deselect,
        b'D'         : deselect_all,
        b'KEY_RESIZE': resize,
    }
    prompt_actions = {
        b'KEY_LEFT'     : prompt.left,      b'^B': prompt.left,
        b'KEY_RIGHT'    : prompt.right,     b'^F': prompt.right,
        b'KEY_HOME'     : prompt.home,      b'^A': prompt.home,
        b'KEY_END'      : prompt.end,       b'^E': prompt.end,
        b'KEY_DC'       : prompt.delete,
        b'KEY_BACKSPACE': prompt.backspace, b'^H': prompt.backspace,
        b'^W'           : prompt.delete_word,
    }
    ESC     = frozenset({b'^['})  #]
    ENTER   = frozenset({b'^M'})
    HELP    = frozenset({b'KEY_F(1)', b'?'})
    QUIT    = frozenset({b'q', b'Q'})
    REFRESH = frozenset({b'^L'})
    while True:
        update_height_width()

        win.erase()
        # Draw HEADER
        draw_line(0, header, curses.A_BOLD)
        for cx in opts.active_cb:
            mvchgat(win, 0, *real_xn(cx), GREEN | curses.A_BOLD)
        # Draw LINES.
        for y, item in enumerate(lines[st.vscroll:st.vscroll + HEIGHT]):
            draw_line(HEADER + y, item, 0)

        if st.help:
            # Draw HELP.
            y = HEIGHT + 1
            mvaddstr(win, y, X_OFF, help)
            for x, n in help_attr_xn:
                mvchgat(win, y, X_OFF + x, n, GREEN | curses.A_BOLD)

        if prompt_on:
            # Draw PROMPTS.
            for cy, cx in sel:
                y = real_y(cy); x, _ = real_xn(cx)
                mvaddstr(win, y, x, prompt.text, curses.A_BOLD)
                mvchgat(win, y, x + prompt.i, 1, sel_attr(cx))
        else:
            # Draw SELECTIONS.
            for cyx in sel:
                if cyx not in errors:
                    cy, cx = cyx
                    draw_ul(cy, opts.select_ul)
                    draw_hl(cy, cx, sel_attr(cx))
            # Draw CURSOR.
            draw_ul(cur.cy, opts.cursor_ul)
            draw_hl(cur.cy, cur.cx, curses.A_STANDOUT, top=True)
            # Draw ERRORS.
            for (cy, cx), err in errors.items():
                y = real_y(cy); x, _ = real_xn(cx)
                mvaddstr(win, y, x, err, RED)

        c = win.getch()
        key = curses.keyname(c)
        if key in REFRESH:
            return State(cur.cyx, st.vscroll, st.hscroll, st.help)

        if prompt_on:
            if key in prompt_actions:
                prompt_actions[key]()
            elif 32 <= c <= 126:
                prompt.insert(chr(c))
            elif key in ENTER:
                errors.clear()
                for cy, cx in sel:
                    err = ops.update_cell(cy, cx, prompt.text)
                    if err is not None:
                        errors[cy, cx] = err
                if not errors:
                    return State(cur.cyx, st.vscroll, st.hscroll, st.help)

            if key in ENTER | ESC:
                if sel_tmp:
                    deselect()
                    sel_tmp = False
                prompt_on = False
        else:
            if key in actions:
                actions[key]()
            elif key in ESC:
                if errors:
                    return State(cur.cyx, st.vscroll, st.hscroll, st.help)
                sel.clear()
            elif key in HELP:
                st.help = not st.help
            elif key in QUIT:
                return None

            if key in ENTER:
                if not sel:
                    select()
                    sel_tmp = True
                prompt_on = True

def ignore(exception, func, *args, **kwargs):
    try: return func(*args, **kwargs)
    except exception: pass

def curses_menu(header: str, lines: list[str], align: list[int],
                opts: Options, ops: Operations) -> int:
    os.environ.setdefault('ESCDELAY', '0')
    win = curses.initscr()
    try:
        ignore(curses.error, curses.curs_set, 0)
        ignore(curses.error, curses.start_color)
        ignore(curses.error, curses.use_default_colors)

        for i in range(1, min(16, curses.COLORS)):
            curses.init_pair(i, i, -1)

        win.keypad(True)
        curses.cbreak()
        curses.noecho()
        curses.nonl()

        state = State(help=opts.help_default)
        while (state := _curses_menu(win, header, lines, align, opts, ops,
                                     state)) is not None:
            header, lines, align = ops.refresh()

        return 0
    finally:
        curses.endwin()
