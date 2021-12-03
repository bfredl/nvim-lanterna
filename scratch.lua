
basepath = os.getenv'HOME' .. '/.local/share/jupyter/runtime/'
latest = io.popen('ls --sort=time '..basepath):read'*l'

connfile = basepath..latest

data = io.open(connfile):read'a*'
config = vim.json.decode(data)


client = require'lanterna'.connect(config)
client.shell

mess = client.session:msg'execute_request'
mess.content.code = '1+2'
mess.content.silent = false


p = require'luadev'.print

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
  p("state: ",c.execution_state)
end

client:poll_iopub(vim.schedule_wrap(function(mess)
  local hnd = iohandler[mess.header.msg_type]
  if hnd then
    hnd(mess.content)
  else
    p(mess.header.msg_type)
    p(vim.inspect(mess.content))
  end
end))

msg = client:shell_request('execute_request', {code='30**3', silent=false})

client.shell:poll(100)
datta = client.shell:recv_all()
reply = client.session:decode(datta)

-- fääl
client.iopub:poll(100)
client.session:decode(client.iopub:recv_all())
