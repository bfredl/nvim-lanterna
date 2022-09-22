
client = require'lanterna'.connect_latest()

client:iopub_handlers()
client:poll_shell()

msg = client:shell_request('execute_request', {code='30**3', silent=false}, function(aaaa) 
  vim.schedule(function() require'luadev'.print("nanana") end)
end)

datta = client.shell:recv_all()
reply = client.session:decode(datta)
