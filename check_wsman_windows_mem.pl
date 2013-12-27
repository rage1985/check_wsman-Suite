#!/usr/bin/perl -w

=pod

check_wsman_windows_mem.pl Check Memory usage.

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

my $host ||= "o";
my $user ||= "0";
my $pass ||= "0";
my $warn ||= "75";
my $crit ||= "100";
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
  "w=s" => \$warn,
  "c=s" => \$crit,
  "perf" => \$perf,
  "verbose" => \$verbose
  ) or die "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass> -w <warn> -c <critical> --verbose\n";

if ( $host eq '0' | $user eq '0' | $pass eq '0' ) {
  print "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass> -w <warn> -c <critical> --verbose\n";
  exit $exit_unkn;
}

if ($warn > $crit){
  print "UNKNOWN : Warnwert ($warn%) groeßer als kritischer Wert ($crit%)!\n";
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

  "class"		        =>	"WIN32_PerfFormattedData_PerfOS_Memory",
  "optimized" => "true",
);

my $get2 = $WSMAN->get(

  "class"		        =>	"WIN32_OperatingSystem",
  "optimized" => "true",
);


my $hashed_get1 = $xml->XMLin($get1);
my $OS = $hashed_get1->{'s:Body'}->{'p:Win32_PerfFormattedData_PerfOS_Memory'};
my $list_get1 = $WSMAN->to_list($get1, "p:Win32_PerfFormattedData_PerfOS_Memory");

my $hashed_get2 = $xml->XMLin($get2);
my $OS2 = $hashed_get2->{'s:Body'}->{'p:Win32_OperatingSystem'};
my $list_get2 = $WSMAN->to_list($get2, "p:Win32_OperatingSystem");

if ($verbose == 1){
print "\n";
print $list_get1;
print "\n";
print $list_get2;
print "\n";
}

my $free_mem = $OS2->{'p:FreePhysicalMemory'}; # b
my $total_mem = $OS2->{'p:TotalVisibleMemorySize'}; # a
my $free_swap = $OS2->{'p:FreeSpaceInPagingFiles'}; # d
my $total_virt = $OS2->{'p:TotalVirtualMemorySize'}; # helper to build total_swap
my $total_swap = $total_virt - $total_mem; # c

my $percent_used = sprintf("%.2f", ($total_mem - $free_swap + $total_swap - $free_mem)/$total_mem *100); # MEM-SWAP % formula: (a-d+c-b)/a*100
my $totalusedmb = sprintf("%.2f", ($total_mem - $free_swap + $total_swap - $free_mem)/1024);
my $freetotalmb = sprintf("%.2f", ($free_swap - $total_swap + $free_mem) /1024); # MEM-SWAP MB formula: (d-c+b)/1024

my $total_virt_mb = sprintf("%.2f",($total_virt) /1024);
my $total_mem_mb = sprintf("%.2f",($total_mem) /1024);

my $perf_string = "";

my $warn_mb = sprintf("%.2f",($total_mem_mb * $warn)/100);
my $crit_mb = sprintf("%.2f",($total_mem_mb * $crit)/100);

my $hardfaults = $OS->{'p:PagesPersec'};
my $softfaults = $OS->{'p:PageFaultsPersec'} - $hardfaults;
my $swapreads = $OS->{'p:PageReadsPersec'};
my $swapwrites = $OS->{'p:PageWritesPersec'};

my $swap_IO_byte = $hardfaults * 4096;
my $mem_IO_byte = $softfaults * 4069;

my $swap_IO_mb = sprintf("%.2f",$swap_IO_byte / 1024**2);
my $mem_IO_mb = sprintf("%.2f",$mem_IO_byte / 1024**2);

if ($mem_IO_mb < 0){
$mem_IO_mb = -($mem_IO_mb);
}

if ($perf == 1){
  $perf_string = "| Used_MB=".$totalusedmb."MB;$warn_mb;$crit_mb;0;$total_virt_mb PHY_MEM_IO=".$mem_IO_mb."MB;;;; SWAP_IO=".$swap_IO_mb."MB;;;;";
}

if ($percent_used <= 100 ) {
  if ( $percent_used > 0 && $percent_used < $warn ) {
    print "OK - There are ".$freetotalmb." MB of physical Memory left! ".$percent_used." % of physical Memory are used $perf_string\n";
    exit $exit_ok;
  } elsif ($percent_used >= $warn && $percent_used < $crit ) {
    print "WARNING - There are ".$freetotalmb." MB of physical Memory left! ".$percent_used." % of physical Memory are used $perf_string\n";
    exit $exit_warn;
  } elsif ($percent_used < 0) {
    print "CRITICAL - Internal calculation Error!\n";
    exit $exit_crit;
  } elsif ($percent_used > $crit) {
    print "CRITICAL - There are only ".$freetotalmb." MB of physical Memory left! ".$percent_used." % of physical Memory are used $perf_string\n";
    exit $exit_crit;
  } else {
    print "Fehler!";
    exit $exit_unkn;
  }
} else {
  my $freetotalmb2 = ($freetotalmb * (-1));
  if ( $percent_used > 0 && $percent_used < $warn ) {
    print "OK - System uses ".$freetotalmb2." MB more Swap as physical Memory is available! ".$percent_used." % of physical Memory are used $perf_string\n";
    exit $exit_ok;
  } elsif ($percent_used >= $warn && $percent_used < $crit ) {
    print "WARNING - System uses ".$freetotalmb2." MB more Swap as physical Memory is available! Es werden ".$percent_used." % of physical Memory are used $perf_string\n";
    exit $exit_warn;
  } elsif ($percent_used > $crit) {
    print "CRITICAL - System uses ".$freetotalmb2." MB more Swap as physical Memory is available! Es werden ".$percent_used." % of physical Memory are used $perf_string\n";
    exit $exit_crit;
  } else {
    print "UNKNOWN - Internal Error!";
    exit $exit_unkn;
  }
}






