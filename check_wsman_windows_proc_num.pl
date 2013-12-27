#!/usr/bin/perl -w

=pod

check_wsman_windows_proc_num.pl Check Number of running Proc´s on Windows Host.

## Version:          1.00  ##

Copyright 2013 Sascha Schaal

Author: Sascha Schaal (sascha.schaal@web.de)

This file is part of check_wsman-Suite

check_wsman-Suite is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published
by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

check_wsman-Suite is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with check_wsman-Suite.
If not, see http://www.gnu.org/licenses/.

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

use strict;
use warnings;

use lib "module";
use WSMAN;
use Getopt::Long;
use XML::Simple;
use Data::Dumper;

my $host ||= "o";
my $user ||= "0";
my $pass ||= "0";
my $warn ||= "0";
my $crit ||= "0";
my $verbose ||= "0";
my $perf ||= "0";

my $exit_ok   = "0";
my $exit_warn = "1";
my $exit_crit = "2";
my $exit_unkn = "3";

BEGIN {
$SIG{__WARN__} =  sub{ print $_[0]; exit( $exit_warn ); };
$SIG{__DIE__} =  sub{ print $_[0]; exit( $exit_crit ); };
}

my $xml = new XML::Simple;


my $ARG = GetOptions(
  "H=s" => \$host,
  "U=s" => \$user,
  "P=s" => \$pass,
  "c=s" => \$crit,
  "w=s" => \$warn,
  "perf" => \$perf,
  "verbose" => \$verbose
  ) or die "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass> -w <warn> -c <critical> --verbose\n";

if ( $host eq '0' | $user eq '0' | $pass eq '0' ) {
  print "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass> -w <warn> -c <critical> -- verbose\n";
  exit $exit_unkn;
}


  my $WSMAN = WSMAN->session(

   "host"               =>    "$host",
   "port"               =>    "5985",
   "user"               =>    "$user",
   "passwd"        =>   "$pass",
   "urlpath"         =>   "wsman",
   "proto"            =>   "http",
   "verbose"      =>   "$verbose"
);

my $get1 = $WSMAN->get(

  "class"		        =>	"WIN32_OperatingSystem",
  "optimized" => "true",
);

my $hashed_get1 = $xml->XMLin($get1);


my $proc_num = $hashed_get1->{'s:Body'}->{'p:Win32_OperatingSystem'}->{'p:NumberOfProcesses'};

my $perf_string = "";

if ($perf == 1){
  $perf_string = "| Processes=$proc_num;$warn;$crit;;";
}


if ($proc_num <= $warn){
  print "OK - Number of Processes: $proc_num $perf_string\n";
  exit $exit_ok;
}
elsif ($proc_num >= $warn && $proc_num <= $crit){
  print "WARNING - Number of Processes: $proc_num $perf_string\n";
  exit $exit_warn;
}
elsif ($proc_num >= $crit){
  print "CRITICAl - Number of Processes: $proc_num $perf_string\n";
  exit $exit_crit;
}

