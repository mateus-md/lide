local config = require('core.config')
local linter = require('plugins.linter')

config.gccheck_args = {}

linter.add_language({
    file_patterns = {"%.c$", "%.h$", "%.inl$"},
    warning_pattern = function(text, filename)

        local file, mlin
        local line, col, err
        local errpat = "[^\n]+(%d+):\n([%w%p]+):(%d+):(%d+): ([^\n]+)"
        local subpat = "([%w%p]+):(%d+):(%d+): ([^\n]+)"

        assert(text:match(errpat) or text:match(subpat), 'invalid error pattern')

        if text:match(errpat) then
            mlin, file, line, col, err = text:match(errpat)
        else
            file, line, col, err = text:match(subpat)
            mlin = line
        end

        local i = file:find('/?[^/]-/[^/]+$')
        file = file:sub(i + 1)

        if not filename:match(file .. '$') then
            coroutine.yield(mlin, col, string.format('[%s] %s', file, err))
        else
            coroutine.yield(line, col, err)
        end
    end,
    command = "gcc $FILENAME -fsyntax-only $ARGS",
    args = config.gccheck_args,
    expected_exitcodes = {0}
})
