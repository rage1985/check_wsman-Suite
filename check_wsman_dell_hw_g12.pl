#!/usr/bin/perl -w

=pod

check_hardware_g12.pl Check Dell Generation 12 Hardware Status

## Version:          1.02  ##

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

my $host ||= "o";
my $user ||= "0";
my $pass ||= "0";
my $verbose ||= "0";
my $timeout ||= "300";
my $extinfo ||= "0";

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
  "h=s" => \$host,
  "u=s" => \$user,
  "p=s" => \$pass,
  "t=s" => \$timeout,
  "v" => \$verbose,
  "verbose" => \$verbose,
  "extinfo" => \$extinfo
  ) or die "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass> -verbose\n";

if ( $host eq '0' | $user eq '0' | $pass eq '0' ) {
  print "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass> -verbose\n";
  exit $exit_unkn;
}


  my $WSMAN = WSMAN->session(

   "host" => "$host",
   "port" => "443",
   "user" => "$user",
   "passwd" => "$pass",
   "urlpath" => "wsman",
   "proto" => "https",
   "timeout" => "$timeout",
   "verbose" => "$verbose"
);

my $get1 = $WSMAN->get(

  "class" => "DCIM_SystemView",
  "ns" => "root/dcim",
  "SelectorSet"	=> {"InstanceID" => "System.Embedded.1"}
);

my $get2 = $WSMAN->get(

  "class" => "DCIM_SystemString",
  "ns" => "root/dcim",
  "SelectorSet"	=> {"InstanceID" => "System.Embedded.1#LCD.1#CurrentDisplay"}
);

my $hashed_get1 = $xml->XMLin($get1);
my $hashed_get2 = $xml->XMLin($get2);

my $class_sysview = $hashed_get1->{"s:Body"}->{"n1:DCIM_SystemView"};
my $LCD = $hashed_get2->{"s:Body"}->{"n1:DCIM_SystemString"}->{"n1:CurrentValue"};
my $tag = $class_sysview->{"n1:ServiceTag"};
my $list_get1 = $WSMAN->to_list($get1, "n1:DCIM_SystemView");

if ($verbose == 1){
  print "\n";
  print $list_get1;
  print "\n";
}

my $extinfo_string = "";

if ($extinfo == 1){
  $extinfo_string = $list_get1;
}

if ($class_sysview->{"n1:RollupStatus"} == 1 ){
  print "OK: $tag\n";
  print $extinfo_string;
  exit $exit_ok;
} elsif($class_sysview->{"n1:RollupStatus"} == 2 && $class_sysview->{'n1:StorageRollupStatus'} == 1){
    print "WARNING: $LCD\n";
    print $extinfo_string;
    exit $exit_warn;
} elsif($class_sysview->{"n1:RollupStatus"} == 3 && $class_sysview->{'n1:StorageRollupStatus'} == 1){
    print "CRITICAL: $LCD\n";
    print $extinfo_string;
    exit $exit_crit;
} elsif($class_sysview->{"n1:RollupStatus"} == 2 && $class_sysview->{'n1:StorageRollupStatus'} != 1){
    print "WARNING: STORAGE ERROR (LCD MAY NOT SHOW SOURCE) $LCD\n";
    print $extinfo_string;
    exit $exit_warn;
} elsif($class_sysview->{"n1:RollupStatus"} == 3 && $class_sysview->{'n1:StorageRollupStatus'} != 1){
    print "CRITICAL: STORAGE ERROR (LCD MAY NOT SHOW SOURCE) $LCD\n";
    print $extinfo_string;
    exit $exit_crit;
} elsif($class_sysview->{"n1:RollupStatus"} == 0 && $class_sysview->{"n1:PowerState"} != 2){
    print "CRITICAL: POWER OFF\n";
    print $extinfo_string;
    exit $exit_crit;
} elsif($class_sysview->{"n1:RollupStatus"} == 0 && $class_sysview->{"n1:PowerState"} == 2){
    print "CRITICAL: No Data \n";
    exit $exit_crit;
} else {
    print "CRITICAL: Script internal Error\n";
    exit $exit_crit;
}

