# WPAD Proxy auto-config

The [Web Proxy Auto-Discovery](https://en.wikipedia.org/wiki/Web_Proxy_Auto-Discovery_Protocol) (WPAD) Protocol is a method used by clients to locate the URL of a [Proxy auto-config](https://en.wikipedia.org/wiki/Proxy_auto-config) (PAC) configuration file.

The content in this project serves such PAC files.
It is intended to be deployed to the `wpad` subdomain of you domains (`http://wpad.example.com/`)
*as a security measure, to prevent WPAD DNS queries for this domain or it's subdomains from leaking to higher level domains*.

Example deployment: <https://wpad.offline.co.za/>
