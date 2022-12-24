client = require'lanterna'.connect_latest()
term_shell = require'lanterna.term_shell'
term_shell.sendlines('moron\n')

term_shell.register(client)
client:poll_shell()
vim.pretty_print(client.config)

function rq(code)
  client:shell_request('execute_request', {code=code, silent=false}, function()
  end)
end

msg = client:shell_request('execute_request', {code='30**3', silent=false}, function(aaaa) 
  vim.schedule(function() require'luadev'.print("nanana") end)
end)

rq 'errrrrrrorr'
rq '1+2'

datta = client.shell:recv_all()
reply = client.session:decode(datta)
