check_wsman-Suite
=================

check_wsman Suite is a Compilation of several Nagios check Scripts based on WSMAN

1. Preface
==========

check_wsman-Suite is designed as a compilation of Nagios check Scripts based on the WSMAN::easy Module.
The Suite should empower Admins to Monitor several Assets of thier Equipment without the need to install
OEM Software such as DELL Open Manage.

2. Content as of 12/2013:
=========================

Hardware Scripts
----------------

check_wsman_dell_hw.pl 
heck Script for pre G12 Servers

check_wsman_dell_hw_g12.pl 
Check Script for G12 and post G12 Servers

Microsoft Windows Scripts
-------------------------

check_wsman_windows_cpu.pl 
Check Script for Windows CPU utilisation.

check_wsman_windows_mem.pl 
Check Script for Windows Memory utilisation based on physical Mem to Pagefile ratio.

check_wsman_windows_partition.pl
Check Script for Windows Partition Space utilisation.

check_wsman_windows_proc_num.pl
Check Script to check the Number of running Processes.

check_wsman_windows_proc_stat.pl
Check Script to check if a Process is running.

check_wsman_windows_network_if.pl 
Check Script to ckeck Network Interface utilisation.


3. Perl Depandancys
===================

Data::UUID

LWP::UserAgent

XML::LibXML

XML::Simple

4. Installation
===============
