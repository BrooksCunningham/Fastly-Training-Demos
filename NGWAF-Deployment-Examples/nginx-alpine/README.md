
This is just a simple lua module lab. It uses the install.sh script in the image to install nginx and the lua module
during the initial docker image build.

What it does:
- Grabs the latest lua module.
- Installs nginx (if not already installed).
- Installs the OpenResty Lua module.
- Extracts the ngwaf lua module to /opt/sigsci/nginx
- Symlinks the needed config to nginx's http includes. 
- Checks whether or not the config works.

agent.conf: Add your params to this file for the agent.
Entrypoint: runs the agent and nginx to print to stderr so your docker run can show output.
Run-Me: Just finds the available port in range and maps port. It runs the container for you.
default.conf: default http config for nginx, just uses httpbin.

To run:
```
chmod +x ./runme.sh
./runme.sh
```

Access via: http://localhost:$port_itfinds/get