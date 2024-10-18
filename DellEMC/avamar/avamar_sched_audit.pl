#!/usr/bin/perl

use strict;

my $mccli = "/usr/local/avamar/bin/mccli";

my %groups = get_groups();

for my $group (sort keys %groups)
{
   get_sched($group);
}


for my $group (sort keys %groups)
{
   get_clients($group, $groups{"$group"}{"type"},$groups{"$group"}{"sched"});
}

sub get_clients {
   my ($l_group, $l_type, $l_sched) = @_;
   my $option = "--name=$l_group";
   my $test = "";
   my $cmd = "$mccli group show-members $option $test";
   
   my $client;
   my $junk;
   my $morejunk;
   my $evenmorejunk;
   
   my @returns;

   open(CMD, "$cmd |") || die "cant open $cmd: $!\n\n";
   while (<CMD>)
   {
      chomp;
      if ($_ =~ /$l_group/)
      {
         s/\s+/%/g;
         ($junk,$evenmorejunk,$client,$morejunk) = split("%", $_);
         my @data = split("/", $client);
         if ($data[1] !~ /NonProd/ && $data[2] !~ /NonProd/)
         {
            print "Avamar,$data[-1],$l_group,$l_sched\n";
 	 }
	else
	{ 
	   # DO NOTHING
	   # print "NOT ADDING $data[2]\n"; 
	}
      }
   }
}

sub get_sched {
   my ($l_group) = @_;
   my $option = "--name=$l_group";
   my $test = "";
   my $cmd = "$mccli group show $option $test";
   
   my $sched;
   my $junk;

   open(CMD, "$cmd |") || die "cant open $cmd: $!\n\n";
   while (<CMD>)
   {
      chomp;
      if ($_ =~ /Schedule/)
      {
         ($junk, $sched) = split("/", $_);
         $groups{$l_group}{"sched"} .= $sched;
      }
   }
}

sub get_groups {

   my %return;
   my $option = "" ;
   #my $test = "|grep AFG_0000";
   my $test = "";
   my $cmd = "$mccli group show $option $test";

   open(CMD, "$cmd |") || die "cant open $cmd: $!\n\n";
   while (<CMD>)
   {
      chomp;
      if ($_ =~ /Normal/)
      {
         s/\s+/ /g;
         my ($group,$type) = split(" / ", $_);
  
         $return{$group} = ({
		              "type" => $type});
      }
   }
return %return;
}

