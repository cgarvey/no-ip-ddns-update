#!/usr/bin/perl

# Copyright (c) 2013, Cathal Garvey. http://cgarvey.ie/
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
######


# This script will update a no-ip.com dynamic DNS account
# using the credentials specified in the config file
#
# An optional IP address can be specified, without which
# the script will attempt to determine the WAN IP address
# automatically.
#
# Call script with no arguments to see usage help, and
# supported arguments.

# NOTHING TO CHANGE HERE!

use strict;

$| = 1;

use LWP::UserAgent;
use HTTP::Request::Common;
use POSIX 'strftime';
use URI::Escape;
use File::Spec;

my( $VERSION ) = "1.04";
my( $req, $resp ); # HTTP Request/Response

my( $agent ) = new LWP::UserAgent;
$agent->agent( "No-ip.com Dynamic DNS Updater; https://github.com/cgarvey/no-ip-ddns-update; Ver " . $VERSION );

my( $path_vol, $path_dir, $path_script ) = File::Spec->splitpath(__FILE__);
my( $path_conf ) = $path_dir . "no-ip-ddns-update.conf";
		
our( $username, $password, $hostname );
our( $v ) = 2; # standard verbosity to print all response status, and errors

# Check for command args
if( $#ARGV >= 0 ) {
	if( $ARGV[0] eq "createconfig" ) {
		if( -r( $path_conf ) ) {
			&log( 0, 1, "WARNING: Config file already exists ($path_conf).rm \nI refuse to overwrite it! Remove the file if you want to re-create it.\n\n" );
		}
	 	open( CONF, ">" . $path_conf ) or &log( 0, 1, "ERROR: Failed to write conf file ($path_conf). Are folder permissions OK?\n\n" );
		print CONF "# Sample configuration file for no-ip-ddns-update. Created " . strftime( '%y%m%d-%H%M%S', localtime ) . ".\n";
		print CONF "# Update the parameters below to match your No-IP.com account credentials.\n\n";
		print CONF "# Lines starting with # are comments, and are ignored.\n\n";
		print CONF "# HOSTNAME is required, and is the hostname you chose in your No-ip.com\n";
		print CONF "# control panel. E.g. mydomain.no-ip.org.\n";
		print CONF "HOSTNAME=myddns.test.noip.com\n\n";
		print CONF "# USERNAME is required, and is your email address that you used to register\n";
		print CONF "# on No-ip.com (and the one you login with).\n";
		print CONF "USERNAME=myemailaddress\@some.domain\n\n";
		print CONF "# PASSWORD is required, and is the one you use to login to No-ip.com.\n";
		print CONF "PASSWORD=my_secret_password\n\n";
		print CONF "# IP_ADDRESS is optional. If it's specified, it's the one that will be used\n";
		print CONF "# in the No-ip.com update. If an IP address is also specified on the command\n";
		print CONF "# line, this configuration will be ingored. The format must be standard IPv4\n";
		print CONF "# dotted notation. E.g. 192.168.1.1\n";
		print CONF "#IP_ADDRESS=192.168.1.100\n\n";
		print CONF "# FORCE_DUMMY_IP_ADDRESS is optional. If it's specified, and the corresponding\n";
		print CONF "# 'updateforce' command line argument is used, this address will be used to\n";
		print CONF "# update the No-ip.com account, before the real IP address is used in a\n";
		print CONF "# subsequent update. This is to force No-ip.com to see a change in IP address\n";
		print CONF "# (for ISPs who provide a long-term IP address lease). Some non-routable IP\n";
		print CONF "# address is recommended, like 127.0.0.1. Use standard IPv4 dotted notation.\n";
		print CONF "#FORCE_DUMMY_IP_ADDRESS=127.0.0.1\n\n";
		print CONF "# VERBOSITY is optional, and controls what is output by the script. This only\n";
		print CONF "# applies to 'purge' and 'purgerforce' commands. Supported values are:\n";
		print CONF "#  0 - Output nothing at all\n";
		print CONF "#  1 - Output only fatal errors; (configuration errors, but not services errors\n";
		print CONF "#      such as No-IP reporting failure to update IP. Recommended for Cron jobs.\n";
		print CONF "#  2 - Output all errors, and indication of success/failure in updating IP. This\n";
		print CONF "#      is the assumed default (if not configured here).\n";
		print CONF "#VERBOSITY=2\n\n";
		close( CONF );

		&log( 0, 0, "Configuration file created ($path_conf). Please update it\nto suit your needs.\n\n" );
		exit( 0 );
	}
	else {
		my( $ip, $dummy_ip );

		# Read config file
		open( CONF, $path_conf ) or &log( 1, 1, "ERROR: Could not open the configuration file ($path_conf in the\ncurrent directory). Run `no-ip-ddns-update.pl createconfig` to create a sample\nconf file for you to change.\n\n" );
		while( my $line = <CONF> ) {
			$line =~ s/[\r\n]//;
			if( $line =~ /^USERNAME=(.*)/ ) {
				$username = $1;
				if( $username eq "" ) { &log( 1, 1, "ERROR: 'USERNAME' can not be empty, in the configuration file.\n\n" ); }
				elsif( $username !~ /.*\@.*/ ) { &log( 1, 1, "ERROR: 'USERNAME' does not appear to be a valid email address.\n\n" ); }
			}
			elsif( $line =~ /^PASSWORD=(.*)/ ) {
				$password = $1;
				if( $password eq "" ) { &log( 1, 1, "ERROR: 'PASSWORD' can not be empty, in the configuration file.\n\n" ); }
			}
			elsif( $line =~ /^HOSTNAME=(.*)/ ) {
				$hostname = $1;
				if( $hostname eq "" ) { &log( 1, 1, "ERROR: 'HOSTNAME' can not be empty, in the configuration file.\n\n" ); }
			}
			elsif( $line =~ /^IP_ADDRESS=(.*)/ ) {
				$ip = $1;
				if( $ip eq "" ) { &log( 1, 1, "ERROR: 'IP_ADDRESS' can not be empty, in the configuration file.\nEither use a valid IP address, or comment out to disable,\nwhich will then use the IP specified on the command line, or guess the IP if not.\n" ); }
				elsif( ! &is_valid_ip( $ip ) ) { &log( 1, 1, "ERROR: 'IP_ADDRESS' does not appear to be a valid format (e.g. 192.168.1.1)\n\n" ); }
			}
			elsif( $line =~ /^FORCE_DUMMY_IP_ADDRESS=(.*)/ ) {
				$dummy_ip = $1;
				if( $dummy_ip eq "" ) { &log( 1, 1, "ERROR: 'FORCE_DUMMY_IP_ADDRESS' can not be empty, in the configuration file.\nEither use a valid IP address, or comment out to disable.\n" ); }
				elsif( ! &is_valid_ip( $dummy_ip ) ) { &log( 1, 1, "ERROR: 'FORCE_DUMMY_IP_ADDRESS' does not appear to be a valid format (e.g. 192.168.1.1)\n\n" ); }
			}
			elsif( $line =~ /^VERBOSITY=(.*)/ ) {
				$v = $1;
				if( $v eq "" ) {
					$v = 2;
					&log( 1, 1, "ERROR: 'VERBOSITY' can not be empty, in the configuration file.\nEither use a valid value, or comment out to disable.\n" );
				}

				$v = ( 0 + $v );
				if( $v < 0 || $v > 2 ) {
					$v = 2;
					&log( 1, 1, "ERROR: Unsupported 'VERBOSITY' config. It needs to be 0, 1, or 2.\n" );
				}
			}
		}
		close( CONF );

		# Check we have rquired config params
		if( $username eq "" ) { &log( 1, 1, "ERROR: 'USERNAME' was not configured in the configuration file.\n" ); }
		if( $password eq "" ) { &log( 1, 1, "ERROR: 'PASSWORD' was not configured in the configuration file.\n" ); }
		if( $hostname eq "" ) { &log( 1, 1, "ERROR: 'HOSTNAME' was not configured in the configuration file.\n" ); }

		# Check for IP on command line (2nd arg).
		# If present, this overrides any IP in config file.
		if( $#ARGV == 1 ) {
			if( &is_valid_ip( $ARGV[1] ) ) {
				$ip = $ARGV[1];
			}
			else { &log( 1, 1, "ERROR: Invalid format in IP address speciifed in command line args.\nUse xxx.xxx.xxx.xxx notation (e.g. 192.168.1.1)\n\n" ); }
		}

		# If we don't have a valid IP here (config file or cmd line arg), get it from web service.
		if( $ip eq "" ) {
			$req = new HTTP::Request( "GET",  "http://ip1.dynupdate.no-ip.com/" );
			$resp = $agent->request( $req );

			if( $resp->code == 200 && &is_valid_ip( $resp->content ) ) {
				$ip = $resp->content;
			}
		}
		if( $ip eq "" ) { &log( 2, 1, "ERROR: Failed to get IP address from the internet (and none was provided in\nconfig file or command line args).\n\n" ); }

		if( $ARGV[0] eq "update" ) {
			&log( 2, 0, "Update: " );
			my( $ret ) = &sendUpdate( $ip );

			if( $ret =~ /^OK/ ) {
				&log( 2, 0, $ret . "\n" );
				exit( 0 );
			}
			else { &log( 2, 1, $ret . "\n" ); }
		}
		elsif( $ARGV[0] eq "updateforce" ) {
			if( $dummy_ip eq "" ) { &log( 1, 1, "ERROR: Using forced update mode, but no valid dummy IP address found in config file.\n\n" ); }
			&log( 2, 0, "Dummy Update: " );
			my( $ret ) = &sendUpdate( $dummy_ip );
			&log( 2, 0, $ret . "\n" );
			if( $ret =~ /^OK/ ) {
				&log( 2, 0, "Waiting..." );
				sleep( 10 );
				&log( 2, 0, " done.\n" );

				&log( 2, 0, "Real Update: " );
				$ret = &sendUpdate( $ip );
				&log( 2, 0, $ret . "\n" );

				if( $ret =~ /^OK/ ) { exit( 0 ); }
				else { &log( 2, 1 ); }
			}
			else { &log( 2, 1 ); }
		}
		else { &log( 1, 1, "ERROR: Unsupported argument.\n\n" . &usageInstructions() ); }
	}
}
else {
	print &usageInstructions(); # print in all verbsoities
}

exit( 0 );

sub usageInstructions() {
	my( $s ) = "No-ip.com DDNS update script. See https://github.com/cgarvey/no-ip-ddns-update\n\n";
	$s .= "Usage: no-ip-ddns-update.pl <command> (<ip address>)\n";
	$s .= "\n";
	$s .= "  <command> is required, and one of:\n";
	$s .= "    createconfig - Creates an initial sample configuration file with supporting\n";
	$s .= "                   comments.\n";
	$s .= "    update       - Updates the No-IP account with IP address from command line\n";
	$s .= "                   or configuration file (cmd line takes precedence).\n";
	$s .= "    updateforce  - Issues two updates to No-IP (to force it to recognise a\n";
	$s .= "                   change. First with dummy IP in config file. Second with\n";
	$s .= "                   real IP from command line, or config file.\n";
	$s .= "\n";
	$s .= "  <ip address> is optional, and is the IP address to update the No-IP domain\n";
	$s .= "               with. If not specified, the config file must have IP_ADDRESS\n";
	$s .= "\n\n";
	return $s;
}

sub sendUpdate() {
	my( $update_ip ) = $_[0];

	# Build up HTTP request args
	my( $url ) = "http://dynupdate.no-ip.com/nic/update?";
	$url .= "myip=" . uri_escape( $update_ip );
	$url .= "&hostname=" . uri_escape( $hostname );

	$req = new HTTP::Request( "GET", $url );
	$req->authorization_basic( $username, $password );
	$resp = $agent->request( $req );

	if( $resp->code == 200 ) {
		if( $resp->content =~ /^(good|nochg) $update_ip/ ) {
			return "OK: $1 $update_ip";
		}
		elsif( $resp->content =~ /^nochg$/ ) {
			return "FAIL: (nochg) Probaly throttled for too many updates.";
		}
		else {
			return "FAIL: (" . $resp->content . ") Unsupported response.";
		}
	}
	else {
		return "FAIL: (" . $resp->code . ") Bad HTTP response from No-IP.com";
	}
}

sub log() {
	# Depending on the verbosity configured, print the specified message, and optionally die
	# Arg 1: The minimum versbosity required (i.e. if 2, then only verbsoities of 2 or 3 will cause message to be printed)
	# Arg 2: Whether or not to die. If 1, the script will die (with provided message if verbsoity is appropriate), if 0, the msg will be printed, without dying.
	# Arg 3: The message, if any, to print

	my( $level ) = $_[0];
	my( $do_die ) = $_[1];
	my( $msg ) = $_[2];

	if( $_[0] <= $v && $msg ne "" ) {
		if( $do_die > 0 ) { die( $msg ); }
		else { print $msg; }
	}
	else {
		if( $do_die > 0 ) { exit( 2555 ); }
	}
}

sub is_valid_ip() {
	my( $test_ip ) = $_[0];
	
	return unless defined( $test_ip );
	return unless $test_ip ne "";

	my( @matches ) = $test_ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
	return unless $#matches == 3;

	foreach( @matches ) {
		return unless ($_ >= 0 && $_ <= 255);
		#return unless ($_ >= 0 && $_ <= 255 && $_ !~ /^0\d{1,2}$/);
	}

	return 1;
}

