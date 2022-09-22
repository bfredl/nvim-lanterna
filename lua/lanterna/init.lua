local h = _G._lanterna_state or {}
_G._lanterna_state = h
_G.h = h

-- connection logic based on facebookarchive/iTorch code
-- released under a BSD-style license, see vendor/itorch/LICENSE
local lzmq
if pcall(require, 'ffi') then
  -- TODO: vendor lzmq.ffi version of lzmq to avoid luarocks deps
  lzmq = require'lzmq.ffi'
else
  lzmq = require'lzmq'
end

local z = lzmq
local Session = require'lanterna.Session'

h.context = h.context or z.context()

local Client = h.Client or {}
h.Client = Client
Client.__index = Client

function Client.connect(config)
  local self = setmetatable({}, Client)
  self.config = config
  self.session = Session.new(config.key)
  self.shell_handlers = {}

  -- connect to 0MQ ports: Shell (DEALER), Control (DEALER), Stdin (DEALER), IOPub (SUB)
  local prefix = config.transport .. '://' .. config.ip .. ':'
  self.shell = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.shell_port})
  self.control = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.control_port})
  self.stdin = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.stdin_port})
  self.iopub = z.assert(h.context:socket{z.SUB, connect = prefix .. config.iopub_port})

  for _, dealer in pairs{self.shell, self.control, self.stdin} do
    dealer:set_identity(self.session.session_id)
  end
  self.iopub:set_subscribe''

  return self
end

function Client:poll_iopub(cb)
  local fd = self.iopub:get_fd()
  local poll = vim.loop.new_poll(fd)
  poll:start('r', function()
    while self.iopub:poll(0) do
      local status = cb(self.session:decode(self.iopub:recv_all()))
      if status == false then
        poll:stop()
        return
      end
    end
  end)
end

-- TODO: mess it up
function Client:iopub_handlers()
  local p = require'luadev'.print
  iohandler = {}
  function iohandler.execute_input(c)
    p("In  ["..c.execution_count.."]: "..c.code)
  end
  function iohandler.execute_result(c)
    local datas = c.data["text/plain"]
    if datas then
      p("Out ["..c.execution_count.."]: "..datas)
    end
  end
  function iohandler.status(c)
    self.state = c.execution_state
    -- p("state: ",c.execution_state)
  end
  self.iohandler = iohandler

  client:poll_iopub(vim.schedule_wrap(function(mess)
    local hnd = self.iohandler[mess.header.msg_type]
    if hnd then
      hnd(mess.content)
    else
      p(mess.header.msg_type)
      p(vim.inspect(mess.content))
    end
  end))
end

function Client:poll_shell()
  local fd = self.shell:get_fd()
  local poll = vim.loop.new_poll(fd)
  poll:start('r', require'luadev'.schedule_wrap(function()
    while self.shell:poll(0) do
      local mess = self.session:decode(self.shell:recv_all())
      local parent = mess.parent_header
      if parent then
        local parent_id = parent.msg_id
        local cb = self.shell_handlers[parent_id]
        self.shell_handlers[parent_id] = nil
        if cb then
          status, err = pcall(cb, mess)
          if not status then
            require'luadev'.append_buf(err, "ErrorMsg")
          end
        else
            require'luadev'.print("WAAAAA", vim.inspect(mess))
        end
      else
          require'luadev'.print("KAAAA")
      end
      -- if status == false then
      --   poll:stop()
      --   return
      -- end
    end
  end))
end


function Client:rawsend(sock, msg)
  local zmq_msg = self.session:encode(msg)
  return sock:send_all(zmq_msg)
end

function Client:shell_request(kind, content, cb)
  local mess = self.session:msg(kind)
  mess.content = content
  self.shell_handlers[mess.header.msg_id] = cb
  self:rawsend(self.shell, mess)
  return mess
end

function h.connect(config)
  return Client.connect(config)
end

function h.connect_connfile(fn)
  local data = io.open(fn):read'a*'
  local config = vim.json.decode(data)
  return h.connect(config)
end

function h.connect_latest()
  local basepath = os.getenv'HOME' .. '/.local/share/jupyter/runtime/'
  local latest = io.popen('ls --sort=time '..basepath):read'*l'
  local connfile = basepath..latest
  return h.connect_connfile(connfile)
end

return h
