#!/usr/bin/perl -w

=pod

check_wsman_windows_proc_stat.pl Check Windows Process Status.

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
my $proc_name ||= "0";
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
  "n=s" => \$proc_name,
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

  "class"		        =>	"WIN32_PerfFormattedData_PerfProc_Process",
  "optimized" => "true",
  "maxelements" => "512",
  "SelectorSet" => {"Name" => "$proc_name"}

);



my $hashed_get1 = $xml->XMLin($get1);
my $list_get1 = $WSMAN->to_list($get1, "p:Win32_PerfFormattedData_PerfProc_Process");
my $proc_perf_hash = $hashed_get1->{'s:Body'}->{'p:Win32_PerfFormattedData_PerfProc_Process'};
my $proc_id = $proc_perf_hash->{'p:IDProcess'};
my $elapsed_time = $proc_perf_hash->{'p:ElapsedTime'};
my $parent_id = $proc_perf_hash->{'p:CreatingProcessID'};

my $get2 = $WSMAN->get(

  "class"		        =>	"WIN32_Process",
  "optimized" => "true",
  "maxelements" => "512",
  "SelectorSet" => {"Handle" => "$proc_id"}

);

my $hashed_get2 = $xml->XMLin($get2);
my $list_get2 = $WSMAN->to_list($get2, "p:Win32_Process");

if ($proc_id == 0 && $elapsed_time == 0 && $parent_id == 0){
  print "CRITICAL: Process not found!\n";
  exit $exit_crit;
}
else{
  my $mem_size = sprintf("%.2f",$proc_perf_hash->{'p:WorkingSetPrivate'}/1024**2);
  my $swap_size = sprintf("%.2f",$proc_perf_hash->{'p:PageFileBytes'}/1024**2);
  my $handles = $proc_perf_hash->{'p:HandleCount'};
  my $threads = $proc_perf_hash->{'p:ThreadCount'};
  my $cpu_time = $proc_perf_hash->{'p:PercentProcessorTime'};
  my $mem_size_peak = sprintf("%.2f",$proc_perf_hash->{'p:WorkingSetPeak'}/1024**2);
  my $swap_size_peak = sprintf("%.2f",$proc_perf_hash->{'p:PageFileBytesPeak'}/1024**2);

  if ( $verbose == 1){
    print "\n";
    print $list_get1;
    print "\n";
    print $list_get2;
    print "\n";
  }

  my $perf_string = "";

  if ($perf == 1){
    $perf_string = "| MEM_Usage=".$mem_size."MB;0;0;0;0 SWAP_Usage=".$swap_size."MB;0;0;0;0 CPU_Usage=$cpu_time%;0;0;0;0 Threads=".$threads.";0;0;0;0 Handles=".$handles.";0;0;0;0";
  }

  print "OK - Process $proc_name found $perf_string\n--RAM: $mem_size MB \n--SWP: $swap_size MB \n--CPU: $cpu_time% \n--Threads: $threads \n--Handles: $handles\n--RAM_peak: $mem_size_peak MB \n--SWP_peak: $swap_size_peak MB \n";
  exit $exit_ok;
}
