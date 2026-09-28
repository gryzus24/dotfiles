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
    __slots__ = ('cy', 'cx', 'cy_max', 'cx_max', 'sel')
    def __init__(self, cy: int, cx: int, cy_max: int, cx_max: int) -> None:
        self.cy = max(min(cy, cy_max), 0)
        self.cx = max(min(cx, cx_max), 0)
        self.cy_max = cy_max
        self.cx_max = cx_max
        self.sel: set[YX] = set()

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
        self.i, self.text = 0, ''

    def left(self)  -> None: self.i = max(self.i - 1, 0)
    def right(self) -> None: self.i = min(self.i + 1, len(self.text))
    def home(self)  -> None: self.i = 0
    def end(self)   -> None: self.i = len(self.text)
    def insert(self, s: str) -> None:
        self.text = self.text[:self.i] + s + self.text[self.i:]
        self.i += len(s)
    def delete(self) -> None:
        self.text = self.text[:self.i] + self.text[self.i + 1:]
    def backspace(self) -> bool:  # canceled?
        far = self.i > 0
        if far:
            self.i -= 1
            self.delete()
        return not far and not self.text
    def backword(self) -> bool:  # canceled?
        i, t = self.i, self.text
        far = i > 0
        while (i := i - 1) > 0:
            if t[i] != ' ' and t[i - 1] == ' ':
                break
        i = max(i, 0)
        self.i, self.text = i, t[:i]
        return not far and not self.text

    ACTIONS = {
        b'KEY_LEFT'     : left,        b'^B': left,
        b'KEY_RIGHT'    : right,       b'^F': right,
        b'KEY_HOME'     : home,        b'^A': home,
        b'KEY_END'      : end,         b'^E': end,
        b'KEY_DC'       : delete,
        b'KEY_BACKSPACE': backspace,   b'^H': backspace,
        b'^W'           : backword,
    }

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

    lines_initial = lines

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

    MODE_NORMAL = 0
    MODE_PROMPT = 1
    MODE_FILTER = 2
    mode = MODE_NORMAL

    cur = Cursor(*st.cursor, len(lines) - 1, len(align) - 1)
    sel_tmp = False

    prompt = Prompt()
    errors: dict[YX, str] = {}

    filtr = Prompt()
    filtr_real_cy = list(range(len(lines)))

    help = 'F1/? Help  (d/D)s/S (De)select/Column  Enter/Esc Prompt  r Refresh  / Filter'
    help_attr_xn = [
        (help.index('F'), 4),
        (help.index('('), 8),
        (help.index('E'), 9),
        (help.index('R') - 2, 1),
        (help.index('i') - 3, 1),
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
        x, n = x_map[cx], xn_map[cx]
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

    def draw_line(y: int, line: str, attr: int) -> None:
        cut      = max(x_map[x_keep_nr_fields] - st.hscroll, x_keep)
        view_x   = st.hscroll + cut
        view_end = st.hscroll + WIDTH
        if x_keep:
            cut_sepless = max(cut - len(opts.sep), 0)
            mvaddstr(win, y, X_OFF, line[:cut_sepless], attr)
        mvaddstr(win, y, X_OFF + cut, line[view_x:view_end], attr)

    def draw_hl(cy: int, cx: int, attr: int, *, top: bool = False) -> None:
        if HEADER <= (y := real_y(cy)) <= HEIGHT:
            mvchgat(win, y, *real_xn(cx, top=top), attr)

    def draw_ul(cy: int, cxattr: XAttr) -> None:
        cx, attr = cxattr
        if cx != -1:
            draw_hl(cy, cx, attr, top=True)

    def sel_attr(cx: int) -> int:
        return (GREEN if cx in opts.active_cb else RED) | curses.A_STANDOUT

    def prompt_or_filtr(mode: int) -> Prompt:
        if mode == MODE_PROMPT: return prompt
        if mode == MODE_FILTER: return filtr
        raise AssertionError

    up           = lambda: cur.up() or check_scroll()
    down         = lambda: cur.down() or check_scroll()
    left         = lambda: cur.left() or check_scroll()
    right        = lambda: cur.right() or check_scroll()
    top          = lambda: cur.top() or check_scroll()
    bot          = lambda: cur.bot() or check_scroll()
    beg          = lambda: cur.beg() or check_scroll()
    end          = lambda: cur.end() or check_scroll()
    select       = lambda: cur.sel.add(cur.cyx)
    deselect     = lambda: cur.sel.discard(cur.cyx)
    select_down  = lambda: select() or cur.down()
    select_all   = lambda: [cur.sel.add((y, cur.cx)) for y, _ in enumerate(lines)]
    deselect_all = lambda: [cur.sel.discard((y, cur.cx)) for y, _ in enumerate(lines)]
    resize       = lambda: (curses.update_lines_cols() or
                            update_height_width() or
                            check_scroll())
    actions = {
        b'k'         : up,    b'K': up,    b'KEY_UP'   : up,
        b'j'         : down,  b'J': down,  b'KEY_DOWN' : down,
        b'h'         : left,  b'H': left,  b'KEY_LEFT' : left,
        b'l'         : right, b'L': right, b'KEY_RIGHT': right,
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
    ESC     = frozenset({b'^['})  #]
    ENTER   = frozenset({b'^M'})
    HELP    = frozenset({b'KEY_F(1)', b'?'})
    QUIT    = frozenset({b'q', b'Q'})
    REFRESH = frozenset({b'r', b'^L'})
    FILTER  = frozenset({b'/', b'KEY_F(4)'})
    while True:
        update_height_width()

        win.erase()
        # Draw HEADER
        draw_line(0, header, curses.A_BOLD)
        for cx in opts.active_cb:
            mvchgat(win, 0, *real_xn(cx), GREEN | curses.A_BOLD)
        # Draw LINES.
        for y, line in enumerate(lines[st.vscroll:st.vscroll + HEIGHT]):
            draw_line(HEADER + y, line, 0)

        if st.help:
            # Draw HELP.
            y = HEIGHT + 1
            mvaddstr(win, y, X_OFF, help)
            for x, n in help_attr_xn:
                mvchgat(win, y, X_OFF + x, n, GREEN | curses.A_BOLD)

        if mode == MODE_PROMPT:
            # Draw PROMPTS.
            for cy, cx in cur.sel:
                y = real_y(cy); x, _ = real_xn(cx)
                mvaddstr(win, y, x, prompt.text, curses.A_BOLD)
                mvchgat(win, y, x + prompt.i, 1, sel_attr(cx))
        else:
            # Draw SELECTIONS.
            for cyx in cur.sel:
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

            if mode == MODE_FILTER:
                # Draw FILTER.
                y, t = HEIGHT + 1, 'Filter: '
                mvaddstr(win, y, 0, t + filtr.text, curses.A_BOLD); win.clrtoeol()
                mvchgat(win, y, len(t) + filtr.i, 1, curses.A_STANDOUT)

        c = win.getch()
        key = curses.keyname(c)

        if mode in {MODE_PROMPT, MODE_FILTER}:
            canceled = False
            p = prompt_or_filtr(mode)
            if key in Prompt.ACTIONS:
                canceled = Prompt.ACTIONS[key](p)
            elif 32 <= c <= 126:
                p.insert(chr(c))
            elif key in ENTER:
                errors.clear()
                if mode == MODE_PROMPT:
                    for cy, cx in cur.sel:
                        err = ops.update_cell(filtr_real_cy[cy], cx, prompt.text)
                        if err is not None:
                            errors[cy, cx] = err
                    if not errors:
                        return State(cur.cyx, st.vscroll, st.hscroll, st.help)
                else:
                    import re
                    t = filtr.text; filtr_real_cy = [
                        i for i, line in enumerate(lines_initial)
                        if not t or re.search(t, line) is not None
                    ]
                    if filtr_real_cy:
                        lines = [lines_initial[y] for y in filtr_real_cy]
                        cur = Cursor(*cur.cyx, len(lines) - 1, len(align) - 1)
                        check_scroll()

            if (key in ENTER | ESC) or canceled:
                if sel_tmp:
                    deselect()
                    sel_tmp = False
                mode = MODE_NORMAL
        else:
            if key in REFRESH:
                return State(cur.cyx, st.vscroll, st.hscroll, st.help)
            elif key in actions:
                actions[key]()
            elif key in ESC:
                if errors:
                    return State(cur.cyx, st.vscroll, st.hscroll, st.help)
                cur.sel.clear()
            elif key in HELP:
                st.help = not st.help
            elif key in QUIT:
                return None

            if key in ENTER:
                if not cur.sel:
                    select()
                    sel_tmp = True
                mode = MODE_PROMPT
            elif key in FILTER:
                mode = MODE_FILTER

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
