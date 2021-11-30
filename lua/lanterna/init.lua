local h = {}
_G.h = h

-- connection logic based on facebookarchive/iTorch code
-- released under a BSD-style license, see vendor/itorch/LICENSE

local lzmq = require'lzmq'
local z = lzmq

--connfile = ""

local data = io.open(connfile):read'a*'
local config = vim.json.decode(data)
h.config = config

h.context = z.context()

-- bind 0MQ ports: Shell (ROUTER), Control (ROUTER), Stdin (ROUTER), IOPub (PUB)
local prefix = config.transport .. '://' .. config.ip .. ':'
h.shell = z.assert(h.context:socket{z.ROUTER, connect = prefix .. config.shell_port})
h.control = z.assert(h.context:socket{z.ROUTER, connect = prefix .. config.control_port})
h.stdin = z.assert(h.context:socket{z.ROUTER, connect = prefix .. config.stdin_port})
h.iopub = z.assert(h.context:socket{z.PAIR, connect = prefix .. config.iopub_port})

return h
