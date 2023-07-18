local term = {}

term.reset = '\x1b[0m'
term.bold = '\x1b[1m'
term.faint = '\x1b[2m'
term.italic = '\x1b[3m'
term.underline = '\x1b[4m'
term.default_foreground_color = '\x1b[39m'
term.default_background_color = '\x1b[49m'

term.fg = {}
term.fg.black = '\x1b[30m'
term.fg.red = '\x1b[31m'
term.fg.green = '\x1b[32m'
term.fg.yellow = '\x1b[33m'
term.fg.blue = '\x1b[34m'
term.fg.magenta = '\x1b[35m'
term.fg.cyan = '\x1b[36m'
term.fg.white = '\x1b[37m'

term.fg.bright_black = '\x1b[90m'
term.fg.bright_red = '\x1b[91m'
term.fg.bright_green = '\x1b[92m'
term.fg.bright_yellow = '\x1b[93m'
term.fg.bright_blue = '\x1b[94m'
term.fg.bright_magenta = '\x1b[95m'
term.fg.bright_cyan = '\x1b[96m'
term.fg.bright_white = '\x1b[97m'

term.bg = {}
term.bg.black = '\x1b[40m'
term.bg.red = '\x1b[41m'
term.bg.green = '\x1b[42m'
term.bg.yellow = '\x1b[43m'
term.bg.blue = '\x1b[44m'
term.bg.magenta = '\x1b[45m'
term.bg.cyan = '\x1b[46m'
term.bg.white = '\x1b[47m'

term.bg.bright_black = '\x1b[100m'
term.bg.bright_red = '\x1b[101m'
term.bg.bright_green = '\x1b[102m'
term.bg.bright_yellow = '\x1b[103m'
term.bg.bright_blue = '\x1b[104m'
term.bg.bright_magenta = '\x1b[105m'
term.bg.bright_cyan = '\x1b[106m'
term.bg.bright_white = '\x1b[107m'

return term
