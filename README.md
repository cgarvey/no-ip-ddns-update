No-ip.com Dynamic DNS Updater Script
====================================
This PERL script will update a no-ip.com dynamic DNS account with a provided IP address, or an automatically detected external IP address.

- - -

Features
--------
* Minimal PERL dependencies
* Can automatically determine external/WAN IP address (if none specified). This can be useful for [NATted](https://en.wikipedia.org/wiki/Network_address_translation) networks. An IP address can also be specified.
* External configuration file, allowing for easier updates in the future.
* Ability to force a dummy IP update first, before updating with the real IP address. This is so that no-ip.com will see a change in IP address, and not expire the account. Useful for long-term IP address leases (or even fixed IP addresses, in the rare occasion you'd want to use a DDNS service!). See usage notes below.

- - -

Usage
-----
### Basic instructions
Calling the script with no arguments will give the following usage instructions:

	No-ip.com DDNS update script. See https://github.com/cgarvey/no-ip-ddns-update
	
	Usage: no-ip-ddns-update.pl <command> (<ip address>)
	
	  <command> is required, and one of:
	    createconfig - Creates an initial sample configuration file with supporting
	                   comments.
	    update       - Updates the No-IP account with IP address from command line
	                   or configuration file (cmd line takes precedence).
	    updateforce  - Issues two updates to No-IP (to force it to recognise a
	                   change. First with dummy IP in config file. Second with
	                   real IP from command line, or config file.
	
	  <ip address> is optional, and is the IP address to update the No-IP domain
	               with. If not specified, the config file must have IP_ADDRESS

### Configuration file
The No-IP.com account details, and hostname to use, are stored in a simple configuration file `no-ip-ddns-update.conf` in the current folder.

If using for the first time, it's best to create a sample configuration file, and follow the instructions in that. To do so, run the script as follows:

	`no-ip-ddns-update.pl createconfig`

**Note**, this will refuse to overwrite your existing configuration file.


### Aboute Forced Update mode
This mode will update No-IP twice in quick succession. The idea is that it would update first with a dummy/private IP address, and then quickly update No-IP a second time, with the proper IP address you want your dynamic host to point to.

This is useful to get around the 30-day limit No-IP impose on free accounts. That is, if your free No-IP account host hasn't been updated with a new IP address in 30 days, it'll be removed (you do get warning emails). Unfortunately updating with the same IP address is not sufficient to get around this 30-day limit; it must be a new IP address.

To use this forced update mode, you need to configure `FORCE_DUMMY_IP_ADDRESS` in the configuration file. It is recommended that you use an internal/private IP address for this (e.g. *127.0.0.1* or *192.168.1.1*), so as not to inadvertently point your dynamic host at a different IP address.

For example, if you configured your `FORCE_DUMMY_IP_ADDRESS` to be *127.0.0.1* and your `IP_ADDRESS` to be *8.8.8.8*, the script will update your No-IP host to *127.0.0.1*, wait ten seconds, and then update the same host to *8.8.8.8*.

This mode is useful for when your ISP gives you a long-term IP address lease, or when your internet connection stays online for weeks at a time. It's even useful if you have a fixed IP address from your ISP, but still use DDNS to point to it (in case you switch ISP, etc.).

However, this mode is **not** suitable if you need 100% reliable resolution of your dynamic hostname (e.g. if you're running an important service off your internet connection). Why? Because when the first dummy update is issued, there's a ten-second gap before the second update is issued. If someone was to request the IP address for your dynamic No-IP host during that time, they'd get the dummy/internal IP address. Compounded by the fact that their ISP would probably cache that dummy IP address for at least the No-IP configured [TTL](https://en.wikipedia.org/wiki/Time_to_live). For at least a minute (the default No-IP TTL), other users of that ISP's DNS will see the dummy IP. Even worse for the few ISPs who ignore/abuse that TTL and cache the dummy IP address for longer than a minute. If your IP address/dynamic DNS host is important, don't use this mode!

- - -

Contributing
------------
Feel free to report any issues (using GitHub issues), and/or pass along any pull requests you may have. You can find me [@cgarvey](http://twitter.com/cgarvey) on Twitter too, if you have specific questions.

- - -

License
-------
**Copyright 2013 (c), Cathal Garvey. http://cgarvey.ie/**

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

*Commercial licensing available on request.*

