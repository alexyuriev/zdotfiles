package Helpers::Logger;
use strict;
use warnings;

BEGIN {
  our $VERSION = 0.08;
}

use Sys::Syslog qw(:standard :macros);
use Helpers::Misc;

use constant HTTP_STATUS_LOGGER_IMPOSSIBLE_CODE => 588;
use constant HTTP_STATUS_LOGGER_UNSET_CODE      => 587;
use constant HTTP_STATUS_LOGGER_UNKNOWN_CODE    => 589;

sub new
{
  my $class = shift @_;
  my $opt = shift @_;

  my $self =  {
                'syslog'      => 0,
                'stdout'      => 0,
                'stderr'      => 1,
                'stdout_json' => 0,
                'json_status' => HTTP_STATUS_LOGGER_UNSET_CODE,
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
  foreach my $this_logger ( qw/stdout stderr stdout_json/)
    {
      $self->{$this_logger} = $opt->{'loggers'}->{$this_logger} if (defined $opt->{'loggers'}->{$this_logger});
    }

  return bless $self, $class;
}

sub loggers {
  my $self = shift @_;

  my $opt = shift @_;

  my @loggers = qw/syslog stdout stderr stdout_json/;
  if (defined $opt)
    {
      foreach my $this_logger (@loggers)
        {
          $self->{$this_logger} = $opt->{$this_logger} if (defined $opt->{$this_logger})
        }
    }
  my $k = undef;
  foreach my $this_logger (@loggers)
    {
      $k->{$this_logger} = $self->{$this_logger};
    }
  return $k;
}

sub status
{
  my $self = shift @_;
  my $status = shift @_;

  if (defined $status)
    {
      if (!Helpers::Misc::isUnsignedInteger($status))
        {
          $self->{'json_status'} = HTTP_STATUS_LOGGER_IMPOSSIBLE_CODE;
        }
      else
        {
          if ($status =~ m/^(200|500|503)$/)
            {
              $self->{'json_status'} = $status;
            }
          else
            {
              $self->{'json_status'} = HTTP_STATUS_LOGGER_UNKNOWN_CODE;
            }
        }
    }
  return $self->{'json_status'};
}

sub log_no_stdout
{
  my $self = shift @_;

  my @loggers_stdout = qw/stdout stdout_json/;
  my $stdout_loggers = undef;

  my $saved_loggers = $self->loggers;
  foreach my $f (@loggers_stdout)
    {
      $stdout_loggers->{$f} = $saved_loggers->{$f};
      $saved_loggers->{$f} = 0;
    }
  $self->loggers($saved_loggers);
  $self->log(@_);
  foreach my $f (@loggers_stdout)
    {
      $saved_loggers->{$f} = $stdout_loggers->{$f};
    }
  $self->loggers($saved_loggers);
}

sub log
{
  my $self = shift @_;
  my $msg = shift @_;

  return if (Helpers::Misc::isEmpty($msg));

  my $assembled_msg = sprintf($msg, @_);
  chomp $assembled_msg;

  my $msg_ident = sprintf("%s[%s]: %s\n", $self->{'ident'}, $$, $assembled_msg);

  syslog('info', $assembled_msg) if ($self->{'syslog'});

  if ($self->{'stdout_json'})
    {
      my $status_obj =  {
                          'status' => $self->status,
                          'msg'   => $assembled_msg,
                        };
      my ($ret, $json_msg) = Helpers::Misc::toJSON($status_obj);
      print STDOUT $json_msg;
    }
  print STDOUT $msg_ident if ($self->{'stdout'});
  print STDERR $msg_ident if ($self->{'stderr'});
}

1;
