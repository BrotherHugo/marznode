Marznode
---------
Just a fork of Marzban-node.

Image with pinned sing-box **1.14.x** built with `with_v2ray_api` (panel traffic stats). Official GitHub musl tarball does not include that tag. Line `v0.2.*` on Hub; `v0.1.*` is sing-box 1.13.

- [X] xray-core
- [X] hysteria
- [X] sing-box

## Setup Guide for Development
Python versions older than 3.12 are not supported.

Setup python virtual environment
```sh
python -m venv .venv/
source .venv/bin/activate
```

Install the requirements

```sh
pip install -r requirements.txt
```

Configure the node. you should provide the correct path to your xray binary and your xray config file.

```sh
cp .env.example .env
```


Set your certificate for the node by saving the certificate in a file and providing address of the certificate
file using `CLIENT_SSL_CERT`. And then execute and start the node:

```sh
python marznode.py
```
