-- jupyter wire format encoding/decoding
-- taken from util.lua in iTorch with minor refactors.
-- Copyright (c) 2015, Facebook, Inc.
-- All rights reserved.
-- see vendor/itorch/LICENSE for full original license

local zmq = require 'lzmq'
local zassert = zmq.assert
local json = vim.json
local uuid = require 'lanterna.vendor.uuid'

local Session = {}
Session.__index = Session

-- Signature Key and its setter
function Session.new(key)
  local self = setmetatable({}, Session)
  self.session_key = key
  self.session_id = uuid.new()
  return self
end

-- Common decoder function for all messages (except heartbeats which are just looped back)
function Session:decode(m)
  -- print('incoming:')
  -- print(m)
  local o = {}
  o.uuid = {}
  local i = -1
  for k,v in ipairs(m) do
    if v == '<IDS|MSG>' then i = k+1; break; end
    o.uuid[k] = v
  end
  assert(i ~= -1, 'Failed parsing till <IDS|MSG>')
  -- json decode
  for j=i+1,i+4 do if m[j] == '{}' then m[j] = nil; else m[j] = json.decode(m[j]); end; end

  -- populate headers
  o.header        = m[i+1]
  o.parent_header = m[i+2]
  o.metadata      = m[i+3]
  o.content       = m[i+4]
  for j=i+5,#m do o.blob = (o.blob or '') .. m[j] end -- process blobs
  return o
end

-- Common encoder function for all messages (except heartbeats which are just looped back)
-- See http://ipython.org/ipython-doc/stable/development/messaging.html
function Session:encode(m)
  -- Message digest (for HMAC signature)
  local d = crypto.hmac.new('sha256', self.session_key)
  d:update(json.encode(m.header))
  if m.parent_header then d:update(json.encode(m.parent_header)) else d:update('{}') end
  if m.metadata then d:update(json.encode(m.metadata)) else d:update('{}') end
  if m.content then d:update(json.encode(m.content)) else d:update('{}') end

  local o = {}
  for k,v in ipairs(m.uuid) do o[#o+1] = v end
  o[#o+1] = '<IDS|MSG>'
  o[#o+1] = d:final()
  o[#o+1] = json.encode(m.header)
  if m.parent_header then o[#o+1] = json.encode(m.parent_header) else o[#o+1] = '{}' end
  if m.metadata then o[#o+1] = json.encode(m.metadata) else o[#o+1] = '{}' end
  if m.content then o[#o+1] = json.encode(m.content) else o[#o+1] = '{}' end
  if m.blob then o[#o+1] = m.blob end
  -- print('outgoing:')
  -- print(o)
end

-- function for creating a new message object
function Session:msg(msg_type, parent)
   local m = {}
   m.header = {}
   if parent then
      m.uuid = parent.uuid
      m.parent_header = parent.header
   else
      m.parent_header = {}
   end
   m.header.msg_id = uuid.new()
   m.header.msg_type = msg_type
   m.header.session = self.session_id
   m.header.date = os.date("%Y-%m-%dT%H:%M:%S")
   m.header.username = 'lanterna'
   m.content = {}
   return m
end

---------------------------------------------------------------------------

return Session
