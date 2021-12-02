local h = {}
_G.h = h

-- connection logic based on facebookarchive/iTorch code
-- released under a BSD-style license, see vendor/itorch/LICENSE

local lzmq = require'lzmq'
local z = lzmq
local Session = require'lanterna.Session'

--connfile = ""

local data = io.open(connfile):read'a*'
local config = vim.json.decode(data)
h.config = config
_G.config = h.config

local Session = require'lanterna.Session'

h.session = Session.new(config.key)

h.context = z.context()

-- connect to 0MQ ports: Shell (DEALER), Control (DEALER), Stdin (DEALER), IOPub (SUB)
local prefix = config.transport .. '://' .. config.ip .. ':'
h.shell = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.shell_port})
--h.shell = h.context:socket(z.ROUTER)
--h.shell:connect(prefix .. config.shell_port)
h.control = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.control_port})
h.stdin = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.stdin_port})
h.iopub = z.assert(h.context:socket{z.SUB, connect = prefix .. config.iopub_port})

for _, dealer in pairs{h.shell, h.control, h.stdin} do
  dealer:set_identity(h.session.session_id)
end

h.iopub:set_subscribe''



mess = h.session:msg'execute_request'
mess.content.code = '1+2'
mess.content.silent = false
q = h.session:encode(mess)

if false then
  h.shell:send_all(q)

  h.shell:poll(100)
  datta = h.shell:recv_all()
  reply = h.session:decode(datta)

  -- fääl
  h.iopub:poll(100)

end
--h.shell:poll()

return h
