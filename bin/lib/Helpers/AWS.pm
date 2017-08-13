package Helpers::AWS;

# Helper functions to deal with AWS
# All of the functions should only use thread safe modules
#

use strict;
use warnings;

use FileHandle;
use JSON;

use Helpers::Misc;

BEGIN {
  our $VERSION = "0.02";
}


my $AWS_EC2_TYPES = {
                      't1.nano'   => 1,
                      't2.nano'   => 1,
                      't1.micro'  => 1,
                      't2.micro'  => 1,
                    };

my $AWS_EC2_RUN_STATES =  {
                            'running' => 1,
                            'stopped' => 1,
                            'terminated' => 1,
                          };


sub isValidAMI
{
  my $ami = shift @_;
  return 0 if (Helpers::Misc::isEmpty($ami));

  $ami =~ s/^ami-[[:xdigit:]]+$//g;
  return 1 if ($ami eq '');
  return 0;
}

sub isValidHostname
{
  my $hostname = shift @_;

  return 0 if (Helpers::Misc::isEmpty($hostname));
  $hostname =~ s/[a-z]|[A-Z]|[0-9]+//g;
  $hostname =~ s/-|_|\.+//g;
  return 1 if ($hostname eq '');
  return 0;
}

sub isValidAWSUsername{
  my $username = shift @_;

  return 0 if (Helpers::Misc::isEmpty($username));
  $username =~ s/[A-Z]|[0-9]|-|_//gi;
  return 1 if ($username eq '');
  return 0;
}

sub isValidAWSUserPath{
  my $path = shift @_;

  return 0 if (Helpers::Misc::isEmpty($path));

  $path =~ s/[A-Z]|[0-9]|-|_|\///gi;
  return 1 if ($path eq '');
  return 0;
}

sub isValidInstanceType
{
  my $instance_type = shift @_;

  return 0 if (Helpers::Misc::isEmpty($instance_type));
  return 1 if (defined $AWS_EC2_TYPES->{$instance_type});
  return 0;
}

sub isValidEC2InstanceRunState
{
  my $state = shift @_;

  return 0 if (Helpers::Misc::isEmpty($state));
  return 1 if (defined $AWS_EC2_RUN_STATES->{$state});
  return 0;
}

# returns a pointer to a list of just instance Ids from AWS responses

sub getInstanceIds
{
  my $obj = shift @_;

  return undef if (!defined $obj);

  my @ids = ();

  foreach my $this_instance (@{$obj->{'Instances'}})
    {
      push @ids, $this_instance->{'InstanceId'};
    }
  return undef if (!scalar @ids);
  return \@ids;
}

1;
