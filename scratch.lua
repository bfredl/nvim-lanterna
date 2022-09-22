
client = require'lanterna'.connect_latest()

client:iopub_handlers()

msg = client:shell_request('execute_request', {code='30**3', silent=false})

datta = client.shell:recv_all()
reply = client.session:decode(datta)
