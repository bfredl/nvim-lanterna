local h = _G._lanterna_state or {}
_G._lanterna_state = h
_G.h = h

-- connection logic based on facebookarchive/iTorch code
-- released under a BSD-style license, see vendor/itorch/LICENSE

local lzmq = require'lzmq'
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

  -- connect to 0MQ ports: Shell (DEALER), Control (DEALER), Stdin (DEALER), IOPub (SUB)
  local prefix = config.transport .. '://' .. config.ip .. ':'
  self.shell = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.shell_port})
  --h.shell = h.context:socket(z.ROUTER)
  --h.shell:connect(prefix .. config.shell_port)
  self.control = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.control_port})
  self.stdin = z.assert(h.context:socket{z.DEALER, connect = prefix .. config.stdin_port})
  self.iopub = z.assert(h.context:socket{z.SUB, connect = prefix .. config.iopub_port})

  for _, dealer in pairs{self.shell, self.control, self.stdin} do
    dealer:set_identity(self.session.session_id)
  end

  self.iopub:set_subscribe''

  return self
end

function Client:rawsend(sock, msg)
  local zmq_msg = self.session:encode(msg)
  return sock:send_all(zmq_msg)
end


if false then

  --connfile = ""

  local data = io.open(connfile):read'a*'
  config = vim.json.decode(data)

  client = h.Client.connect(config)


  mess = client.session:msg'execute_request'
  mess.content.code = '1+2'
  mess.content.silent = false
  client.shell:get_identity()

  client:rawsend(client.shell, mess)

  client.shell:poll(100)
  datta = client.shell:recv_all()
  reply = client.session:decode(datta)

  -- fääl
  client.iopub:poll(100)
end

return h
