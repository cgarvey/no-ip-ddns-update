No-ip.com Dynamic DNS Updater Script
====================================
This PERL script will update a no-ip.com dynamic DNS account with a provided IP address, or an automatically detected external IP address.

Features
--------
* Minimal PERL dependencies
* Can automatically determine external/WAN IP address (if none specified). This can be useful for [NATted](https://en.wikipedia.org/wiki/Network_address_translation) networks. An IP address can also be specified.
* External configuration file, allowing for easier updates in the future.
* Ability to force a dummy IP update first (default 127.0.0.1), before updating with the real IP address. This is so that no-ip.com will see a change in IP address, and not expire the account. Useful for long-term IP address leases (or even fixed IP addresses, in the rare occasion you'd want to use a DDNS service!)

Usage
------
*Usage instructions coming soon*

Contributing
------------
Feel free to report any issues (using GitHub issues), and/or pass along any pull requests you may have. You can find me [@cgarvey](http://twitter.com/cgarvey) on Twitter too, if you have specific questions.

License
-------
**Copyright 2013 (c), Cathal Garvey. http://cgarvey.ie/**

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

*Commercial licensing available on request.*

