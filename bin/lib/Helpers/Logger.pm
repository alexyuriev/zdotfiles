package Helpers::Logger;
use strict;
use warnings;

BEGIN {
  our $VERSION = 0.04;
}

use Sys::Syslog qw(:standard :macros);
use Helpers::Misc;

sub new {
  my $class = shift @_;
  my $opt = shift @_;

  my $self =  {
                'syslog' => 0,
                'stdout' => 0,
                'stderr' => 1,
              };
  return undef if (!defined $opt);

  return undef if (Helpers::Misc::isEmpty($opt->{'ident'}));
  $self->{'ident'} = $opt->{'ident'};

  return undef if (!defined $opt->{'loggers'});
  if (defined $opt->{'loggers'}->{'syslog'})
    {
      my $facility = qq(user);
      $facility = $opt->{'loggers'}->{'syslog'}->{'facility'} if (!Helpers::Misc::isEmpty($opt->{'loggers'}->{'syslog'}->{'facility'}));
      openlog($self->{'ident'}, qq(nofatal,pid), $facility);
      $self->{'syslog'} = 1;
    }
  foreach my $this_logger ( qw/stdout stderr/)
    {
      $self->{$this_logger} = $opt->{'loggers'}->{$this_logger} if (defined $opt->{'loggers'}->{$this_logger});
    }

  return bless $self, $class;
}

sub log {
  my $self = shift @_;
  my $msg = shift @_;

  return if (Helpers::Misc::isEmpty($msg));

  my $assembled_msg = sprintf($msg, @_);
  chomp $assembled_msg;

  my $msg_ident = sprintf("%s[%s]: %s\n", $self->{'ident'}, $$, $assembled_msg);

  syslog('info', $assembled_msg) if ($self->{'syslog'});
  print STDOUT $msg_ident if ($self->{'stdout'});
  print STDERR $msg_ident if ($self->{'stderr'});
}

1;
