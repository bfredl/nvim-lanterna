
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

client:rawsend(client.shell, mess)

client:poll_iopub(vim.schedule_wrap(function() require'luadev'.print'aa' end))
client.shell:poll(100)
datta = client.shell:recv_all()
reply = client.session:decode(datta)

-- fääl
client.iopub:poll(100)
client.session:decode(client.iopub:recv_all())
