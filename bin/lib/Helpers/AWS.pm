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
  our $VERSION = "0.08";
}


my $AWS_EC2_TYPES = {
                      't1.nano'   => 1,
                      't2.nano'   => 1,
                      't1.micro'  => 1,
                      't2.micro'  => 1,
                    };

my $AWS_EC2_REGIONS = {
                        'us-east-1'       => 1,
                        'us-east-2'       => 1,
                        'us-west-1'       => 1,
                        'us-west-2'       => 1,
                        'eu-west-1'       => 1,
                        'eu-west-2'       => 1,
                        'ap-south-1'      => 1,
                        'ap-northeast-1'  => 1,
                        'ap-northeast-2'  => 1,
                        'ap-southeast-1'  => 1,
                        'ap-southeast-2'  => 1,
                        'sa-east-1'       => 1,
                        'ca-central-1'    => 1,
                        'eu-central-1'    => 1,
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

sub isValidSecurityGroup
{
  my $sg = shift @_;
  return 0 if (Helpers::Misc::isEmpty($sg));

  $sg =~ s/^sg-[[:xdigit:]]+$//g;
  return 1 if ($sg eq '');
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

sub isValidAWSUsername
{
  my $username = shift @_;

  return 0 if (Helpers::Misc::isEmpty($username));
  $username =~ s/[A-Z]|[0-9]|-|_//gi;
  return 1 if ($username eq '');
  return 0;
}

sub isValidAWSUserPath
{
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

sub isValidEC2InstanceId
{
  my $instance_id = shift @_;

  return 0 if (Helpers::Misc::isEmpty($instance_id));
  $instance_id =~ s/^i-//g;
  $instance_id =~ s/^[[:xdigit:]]+$//g;
  return 1 if ($instance_id eq '');
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

sub getAllAWSRegions {
  return keys %{$AWS_EC2_REGIONS};
}

sub isValidAWSRegion
{
  my $region = shift @_;

  return undef if (!defined $region);
  return 1 if (defined $AWS_EC2_REGIONS->{$region});
  return 0;
}

sub isValidAWSAz {
  my $az = shift @_;

  return 0 if (!defined $az);

  my $chr = chop($az);
  return 0 unless $chr =~ m/^(a|b|c)$/g;
  return 0 if (!isValidAWSRegion($az));
  return 1;
}

sub azToRegion
{
  my $az = shift @_;

  return undef if (!defined $az);
  foreach my $r (keys %$AWS_EC2_REGIONS)
    {
      return $r if ($az =~ m/^$r/)
    }
  return undef;
}

1;
