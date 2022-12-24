local h = _G._lanterna_term_state or {}
_G._lanterna_term_state = h
_G.h = h

local a = vim.api

h.handlers = h.handlers or {}
local handlers = h.handlers

function h.ensure_term()
  if h.buf == nil then
    h.buf = a.nvim_create_buf(false, true)

    local w0 = a.nvim_get_current_win()
    a.nvim_command("split")
    local w = a.nvim_get_current_win()
    a.nvim_win_set_buf(w,h.buf)
    a.nvim_set_current_win(w0)

    h.term = a.nvim_open_term(h.buf, {})
    a.nvim_buf_set_name(h.buf, "[lanterna-iopub]")
  end
end

function h.send(data)
  a.nvim_chan_send(h.term, data)
end

function h.sendlines(data)
  a.nvim_chan_send(h.term, (string.gsub(data, '\n', '\r\n')))
end

function handlers.execute_input(c)
  h.sendlines("In  ["..c.execution_count.."]: "..c.code..'\n')
end

function handlers.execute_result(c)
  local datas = c.data["text/plain"]
  if datas then
    h.sendlines("Out ["..c.execution_count.."]: "..datas..'\n')
  end
end

function handlers.error(c)
  local tb = table.concat(c.traceback, '\n')
  _long = tb
  h.sendlines("ERROR:\n"..tb..'\n')
end

function handlers.status(c)
  h.state = c.execution_state
  -- p("state: ",c.execution_state)
end


function h.register(client)
  h.ensure_term()
  local luadev = require'luadev'

  client:poll_iopub(luadev.schedule_wrap(function(mess)
    local hnd = handlers[mess.header.msg_type]
    if hnd then
      hnd(mess.content)
    else
      local p = luadev.print
      p('FEL:', mess.header.msg_type)
      p(vim.inspect(mess.content))
    end
  end))
end
return h
