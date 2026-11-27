# WPAD Proxy auto-config

## TL;DR

This code contains a Proxy auto-config (PAC) file ([`wpad.dat`](dist/wpad.dat)) that configures browsers to contact websites directly, without using a (possibly malicious) proxy.

Serving this file for your domain stops WPAD DNS lookups from falling through to a higher level domain, which could otherwise serve a file that directs your traffic to its proxy.

## About Proxy Configuration Protocols

The [Web Proxy Auto-Discovery](https://en.wikipedia.org/wiki/Web_Proxy_Auto-Discovery_Protocol) (WPAD) Protocol is a method used by clients to locate the URL of a Proxy auto-config (PAC) configuration file using Dynamic Host Configuration Protocol (DHCP) and/or Domain Name System (DNS) discovery methods.

A [Proxy auto-config](https://en.wikipedia.org/wiki/Proxy_auto-config) (PAC) configuration file defines how web browsers and other user agents can automatically choose the appropriate proxy server (access method) for fetching a given URL.

## Why - Security Risk

While greatly simplifying configuration of one organisation's web browsers, the WPAD protocol can open doors for attackers to change what appears on a user's browser.

When WPAD is enabled, operating systems and browsers automatically attempt to discover a PAC file:

- via DHCP (option 252), and
- by looking up a host named `wpad` in DNS - first in the client's own domain, then (on some clients) in each parent domain in turn ("domain devolution"), e.g. `wpad.sales.example.com`, then `wpad.example.com`.
- If DNS returns no answer, Windows clients may also fall back to local broadcast name resolution (LLMNR / NetBIOS).

If your domain does not answer the `wpad` lookup, whoever controls a parent domain, or an attacker answering broadcast queries on your local network, can supply their own PAC file and force your network's web traffic through a malicious proxy.

One way to reduce this risk is to serve a valid PAC file, and make it discoverable via WPAD, for your domain. Note that this does not protect against an attacker who can run a rogue DHCP server on your network.

## Files Served

- [`wpad.dat`](dist/wpad.dat) for WPAD DNS lookups
- Copy in `wpad.da` for broken Internet Explorer version `6.0.2900.2180.xpsp_sp2_rtm`
- Copy in `proxy.pac` - conventional file name for DHCP configurations

## Example Deployment

For an example of this, see <http://wpad.cliffordweinmann.com/>.

## Deploy Your Own

### Serve The PAC Files

To use this for your own domain (`example.com`), simply serve the contents of the [`dist/`](dist) directory on an HTTP server (*not HTTPS*) at the `wpad` subdomain of your domain (`http://wpad.example.com/`).

The PAC files should be served with the MIME type `application/x-ns-proxy-autoconfig`. Many clients don't check this, but some do, so it is best to set it.

To set this in [Nginx](https://nginx.org/), add this to your `server` block:

```nginx
location ~ ^/wpad\.dat?$ {
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

You can also set this in a [`.htaccess`](dist/.htaccess) file if allowed.

On [Netlify](https://www.netlify.com/), you can set the headers in a `netlify.toml` file in your site's base directory. An example is available in [`src/netlify.toml`](src/netlify.toml).

### WPAD DNS Entries

For browsers to discover your PAC file, your domain needs a DNS `A` (or `CNAME`) record for a host named `wpad`. This is the DNS method that clients actually use.

> **Windows DNS Server / Active Directory:** by default, Windows DNS Server refuses to answer queries for `wpad` (and `isatap`), because both names are on its *global query block list*. Your `wpad` record will not resolve until you remove `wpad` from that list, e.g. with PowerShell:
>
> ```powershell
> Set-DnsServerGlobalQueryBlockList -List isatap
> ```
>
> or `dnscmd /config /globalqueryblocklist isatap`.

The WPAD [internet draft](https://datatracker.ietf.org/doc/html/draft-ietf-wrec-wpad-01) (an expired 1999 draft, never an RFC) also recommends (*SHOULD*, not *MUST*) that clients support DNS `SRV` and `TXT` records, at `wpad.tcp.<domain>` and `wpad.<domain>` respectively. As far as we know, no major browser or operating system uses them, but they do no harm.

Example DNS entries (*substitute your domain name and server IP address*):

```bind
$ORIGIN example.com.
; Required
wpad       IN A   192.168.42.10
; Optional - per the WPAD draft, rarely (if ever) used by clients
wpad.tcp   IN SRV 10 10 80 wpad.example.com.
wpad       IN TXT "service: wpad:http://wpad.example.com/wpad.dat"
```

Note that a `TXT` record can't be added to a name that is a `CNAME`, so use an `A` record for `wpad` if you want the `TXT` record.

### Multiple Domains

You don't need a separate website for each domain. Clients fetch `http://wpad.<their-domain>/wpad.dat` from whatever server that name resolves to, so one server can serve every domain. Point each domain's `wpad` record at it:

```bind
wpad.example.com.        IN CNAME wpad.common.example.net.
wpad.example.org.        IN CNAME wpad.common.example.net.
wpad.sales.example.com.  IN CNAME wpad.common.example.net.
```

The [example Nginx configuration](examples/nginx-default.conf) answers for any `wpad.*` host name, so it needs no changes.

Add a record for each subdomain that clients belong to as well (e.g. `wpad.sales.example.com` for `pc1.sales.example.com`). Don't rely on clients devolving to the parent domain's `wpad` record: modern Windows limits how far it does this.

Use DNS records rather than HTTP redirects. A redirect still needs a web server answering for each `wpad` host name, and clients don't handle redirects consistently.

### WPAD DHCP

In order to use DHCP, the server must be configured to serve up the site-specific option 252 (`auto-proxy-config`) with a string value of e.g. `http://wpad.example.com/wpad.dat`.

Some older Windows clients are reported to drop the last character of the option 252 string. If your clients fail to fetch the file, try adding a trailing newline or null character to the value (e.g. `"http://wpad.example.com/wpad.dat\n"` in dnsmasq).

For the [ISC Kea DHCP](https://www.isc.org/kea/) Server (DHCPv4 only), here is an example of the key code snippets you require:

```
{
"Dhcp4": {
    // ---- Define WPAD option 252 ---- //
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
            ]
        }
    ]
}
}
```

A full example is available in [`examples/kea-dhcp4.conf`](examples/kea-dhcp4.conf).

In [dnsmasq](https://dnsmasq.org/doc.html), you can add something like this to the configuration file:

```
dhcp-option=252,"http://wpad.example.com/wpad.dat"
```
