client = require'lanterna'.connect_latest()
term_shell = require'lanterna.term_shell'

term_shell.register(client)
client:poll_shell()
vim.pretty_print(client.config)

function rq(code)
  client:shell_request('execute_request', {code=code, silent=false}, function()
  end)
end

rq 'errrrrrrorr'

client:send_shell(client:complete_msg("enume"), function(resp)
  require'luadev'.print("COMPLRA", resp)
end)


datta = client.shell:recv_all()
reply = client.session:decode(datta)
