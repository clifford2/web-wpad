# WPAD Proxy auto-config

The [Web Proxy Auto-Discovery](https://en.wikipedia.org/wiki/Web_Proxy_Auto-Discovery_Protocol) (WPAD) Protocol is a method used by clients to locate the URL of a [Proxy auto-config](https://en.wikipedia.org/wiki/Proxy_auto-config) (PAC) configuration file using DHCP and/or DNS discovery methods.

While greatly simplifying configuration of one organisation's web browsers, the WPAD protocol can open doors for attackers to change what appears on a user's browser.

The content in this project exists only as a security measure, to prevent WPAD DNS queries for this domain or it's subdomains from leaking to higher level domains.
It serves a [PAC file](dist/wpad.dat) that configure browsers to contact websites directly, without using a (possibly malicious) proxy.

To use this for your own domain (`example.com`), simply serve the contents of the [`dist/`](dist) directory on a HTTP server (not HTTPS) at the `wpad` subdomain of you domain (`http://wpad.example.com/`). Note that the MIME type for the PAC files must be `application/x-ns-proxy-autoconfig` - see [`nginx-default.conf`](nginx-default.conf) for an example of how to do this in Nginx.

Example deployment: <http://wpad.cliffordweinmann.com/>
