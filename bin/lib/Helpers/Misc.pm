package Helpers::Misc;

# Misc helper functions
# All of the functions should only use thread safe modules
#

use strict;
use warnings;

use FileHandle;
use JSON;

BEGIN {
  our $VERSION = "0.05";
}

sub readFile
{
  my $fname = shift @_;
  my $txt = '';
  my $ret = 0;

  my $fh = FileHandle->new($fname);
  if (defined $fh)
    {
      while (my $line = <$fh>) { $txt .= $line; }
      $fh->close();
      $ret = 1;
    }
  return ($ret, \$txt) if ($ret);
  return ($ret, qq(Can't open $fname));
}

sub writeFile
{
  my $fname = shift @_;
  my $txt = shift @_;
  my $opt = shift @_;

  return (0, qq(File name not defined)) if (isEmpty($fname));

  my $fhw = FileHandle->new($fname, "w");
  return (0, qq(Failed to open file $fname for writing)) if (!defined $fhw);
  if (defined $opt && defined $opt->{'mode'})
    {
      my $count = chmod $opt->{'mode'}, $fname;
      if (!$count)
        {
          $fhw->close();
          $count = unlink $fname;
          return (0, qq(Failed to set mode of $fname to ) . $opt->{'mode'} . qq( and failed to delete the file. This is bad)) if (!$count);
          return (0, qq(Failed to set mode of $fname to ) . $opt->{'mode'} . qq( so it is deleted));
        }
    }
  $fhw->print($txt);
  $fhw->close();
  return (1, qq(OK));
}

sub isEmpty
{
  my $a = shift @_;
  my $r = 0;

  return 1 if (!defined $a);
  $r = 1 if (($a eq "") || ($a =~ m/^\s+$/g));

  return $r;
}

sub fromJSON
{
  my $txt = shift @_;

  return (0, qq(Received an undef)) if (isEmpty($txt));
  my $json = JSON->new->utf8->allow_nonref;

  my $ptr = undef;
  eval { $ptr = $json->decode($txt); };
  return (0, $@) if ($@);
  return (1, $ptr);
}

sub toJSON
{
  my $ptr = shift @_;
  my $opt = shift @_;

  return (0, qq(Received an undef)) if (!defined $ptr);

  my $is_pretty = 0; if (defined $opt) { $is_pretty = 1 if (defined $opt->{'pretty'} && $opt->{'pretty'} eq "1"); }

  my $json = JSON->new->utf8->allow_nonref;
  return (1, $json->pretty(1)->encode($ptr)) if ($is_pretty);
  return (1, $json->encode($ptr));
}

sub removeSpaces
{
  my $txt = shift @_;
  return '' if (isEmpty($txt));

  $txt =~ s/\s+//g;

  return $txt;
}

sub display_and_exit
{
  my $code = shift @_;
  my $msg = shift @_;

  my $assembled_msg = undef;
  $assembled_msg = sprintf($msg, @_) if (!Helpers::Misc::isEmpty($msg));

  $assembled_msg = '' if (Helpers::Misc::isEmpty($assembled_msg)); chomp $assembled_msg;
  $code = -1 if (Helpers::Misc::isEmpty($code));

  my $l = $main::logger; if (defined $l) { $l->log("%s", $assembled_msg); } else { printf("%s\n", $assembled_msg); }

  exit($code);
}

sub get_users_home_dir
{
  return $ENV{'HOME'};
}

sub isInArray {
  my $array_ptr = shift @_;
  my $elem = shift @_;

  my $ret = 0;
  foreach my $this_elem (@$array_ptr)
    {
      if ($this_elem eq $elem)
        {
          $ret = 1;
          last;
        }
    }
  return $ret;
}

sub isValidPortNumber
{
  my $port = shift @_;

  return 0 if (!Helpers::Misc::isUnsignedInteger($port));
  return 0 if ($port > 65534);
  return 1;
}

sub isValidIpv4CIDR
{
  my $cidr = shift @_;

  return 0 if (Helpers::Misc::isEmpty($cidr));
  my ($oct1, $oct2, $oct3, $oct4_extra, $junk) = split('\.', $cidr, 4);
  return 0 if (!Helpers::Misc::isEmpty($junk));

  my ($oct4, $net) = split('/', $oct4_extra);
  foreach my $oct ($oct1, $oct2, $oct3, $oct4)
    {
      return 0 if (!isUnsignedInteger($oct));
      return 0 if ($oct > 255);
    }
  return 0 if (!isUnsignedInteger($net));
  return 0 if ($net > 32);
  return 1;

}

sub isUnsignedInteger
{
  my $a = shift @_;

  my $r = 0;
  if (!isEmpty($a))
    {
      $r = 1 if ( $a =~ /^\d+$/g);
    }
  return $r;
}


1;
