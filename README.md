# WPAD Proxy auto-config

## TL;DR

This code contains a Proxy auto-config (PAC) file ([`wpad.dat`](dist/wpad.dat)) that configures browsers to contact websites directly, without using a (possibly malicious) proxy.

Serving this file for your domain eliminates the risk of a higher level domain serving a file that directs your traffic to their proxy.

## About Proxy Configuration Protocols

The [Web Proxy Auto-Discovery](https://en.wikipedia.org/wiki/Web_Proxy_Auto-Discovery_Protocol) (WPAD) Protocol is a method used by clients to locate the URL of a Proxy auto-config (PAC) configuration file using Dynamic Host Configuration Protocol (DHCP) and/or Domain Name System (DNS) discovery methods.

A [Proxy auto-config](https://en.wikipedia.org/wiki/Proxy_auto-config) (PAC) configuration file defines how web browsers and other user agents can automatically choose the appropriate proxy server (access method) for fetching a given URL.

## Why - Security Risk

While greatly simplifying configuration of one organisation's web browsers, the WPAD protocol can open doors for attackers to change what appears on a user's browser.

When WPAD is enabled, operating systems and browsers automatically attempt to discover proxy settings by querying local and domain DNS servers, broadcast protocol mechanisms, and DHCP options. If your internal or public domain does not host a PAC file, an attacker can spoof one and force your network's web traffic through a malicious proxy.

One way to prevent this is to serve a valid PAC file, and make it discoverable via WPAD, for your domain.

## Files Served

- [`wpad.dat`](dist/wpad.dat) for WPAD DNS lookups
- Copy in `wpad.da` for broken Internet Explorer version `6.0.2900.2180.xpsp_sp2_rtm`
- Copy in `proxy.pac` - conventional file name for DHCP configurations

## Example Deployment

For an example of this, see <http://wpad.cliffordweinmann.com/>.

## Deploy Your Own

### Serve The PAC Files

To use this for your own domain (`example.com`), simply serve the contents of the [`dist/`](dist) directory on a HTTP server (*not HTTPS*) at the `wpad` subdomain of you domain (`http://wpad.example.com/`).

Note that the MIME type for the PAC files must be `application/x-ns-proxy-autoconfig`.

To set this in [Nginx](https://nginx.org/), add this to your `server` block:

```nginx
location ~ ^/wpad\.da {
	types { }
	default_type application/x-ns-proxy-autoconfig;
}
location = /proxy.pac {
	types { }
	default_type application/x-ns-proxy-autoconfig;
}
```

A full example is available in [`examples/nginx-default.conf`](examples/nginx-default.conf).

In [Apache](https://httpd.apache.org/), you can add this to the appropriate configuration file (ideally for the WPAD `VirtualHost` only):

```apache
AddType application/x-ns-proxy-autoconfig .dat
AddType application/x-ns-proxy-autoconfig .pac
```

### WPAD DNS Entries

For browsers to discover your PAC file, DNS `A` / `CNAME` records are needed in your domain, for a host named `wpad`.

The WPAD [internet draft](https://datatracker.ietf.org/doc/html/draft-ietf-wrec-wpad-01) also recommends that clients support DNS `SRV` and `TXT service` records.

Example DNS entries (*substitite your domain name and server IP address*):

```bind
$ORIGIN example.com.
wpad       IN A   192.168.42.1
_wpad._tcp IN SRV 10 10 80 wpad.example.com.
@          IN TXT service: wpad:http://wpad.example.com/wpad.dat
```

### WPAD DHCP

In order to use DHCP, the server must be configured to serve up the site-specific option 252 (`auto-proxy-config`) with a string value of e.g. `http://wpad.example.com/wpad.dat`.

For the [ISC Kea DHCP](https://www.isc.org/kea/) Server (DHCPv4 only), here is an example of the key code snippets you require:

```
{
"Dhcp4": {
    // ---- Define WPAD option 255 ---- //
    "option-def": [
      {
        "name": "wpad-url",
        "code": 252,
        "type": "string",
        "space": "dhcp4"
      }
    ],
    "subnet4": [
        {
            "id": 1,
            "subnet": "192.168.42.0/24",
            "pools": [ { "pool": "192.168.42.200 - 192.168.42.254" } ],
            "option-data": [
                // ---- Set WPAD option value ---- //
                {
                    "name": "wpad-url",
                    "data": "http://wpad.example.com/wpad.dat"
                }
            ],
        }
    ],
}
}
```

A full example is available in [`examples/kea-dhcp4.conf`](examples/kea-dhcp4.conf).

In [dnsmasq](https://dnsmasq.org/doc.html), you can add something like this to the configuration file:

```
dhcp-option=252,"http://wpad.example.com/wpad.dat"
```
