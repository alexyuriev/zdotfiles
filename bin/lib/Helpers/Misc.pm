package Helpers::Misc;

# Misc helper functions
# All of the functions should only use thread safe modules
#

use strict;
use warnings;

use FileHandle;
use Cwd;
use JSON;

BEGIN {
  our $VERSION = "0.13";
}

#    FUNCTION: ($ret, $content_ptr) = readFile($fname)
#
# DESCRIPTION: Slurps content of file with a name $fname and returns it to the caller
#
#       INPUT: $fname         - Name of a file to read
#                               If $fname is "empty" then the function reads from STDIN
#       OUPUT: $ret           - return code
#                               0 - failure, typically file not found or permission error
#                                   $content_ptr is set to an error message
#                               1 - success, $content_ptr is a reference to the content of the file
#
#              $content_ptr   - Reference to the content of the file or reference -1
#

sub readFile
{
  my $fname = shift @_;
  my $txt = '';
  my $ret = 0;

  my $fname_txt = $fname;

  my $fh = undef;
  my $is_stdin = 0;
  if (!Helpers::Misc::isEmpty($fname))
    {
      $fh = FileHandle->new($fname);
    }
  else
    {
      $fh = *STDIN;
      $is_stdin = 1;
    }

  if (defined $fh)
    {
      while (my $line = <$fh>) { $txt .= $line; }
      $fh->close() if (!$is_stdin);
      $ret = 1;
    }
  return ($ret, \$txt) if ($ret);
  return ($ret, qq(Can't open $fname_txt));
}

#    FUNCTION: ($ret, $r) = writeFile($fname, $text, $opts)
#
# DESCRIPTION: Writes $text into a file $fname. Support STDOUT and write pipes
#
#       INPUT: $fname  - file name of the file to write to.
#                        If $fname is not defined, then we write to stdout
#                        If $fname starts with |, we presume it is a pipe
#              $text   - Content to write to $fname
#              $opt    - Optional argument hash:
#                        $opt->{'mode'} - chmod file to this permission.
#                        Applicable only to regular files. Failure to change
#                        mode upon opening causes an attempt to delete the file
#                        and always returns error to the caler
#      OUTPUT: $ret    - Result code
#                        1 -- Success
#                        0 -- Failure

sub writeFile
{
  my $fname = shift @_;
  my $txt   = shift @_;
  my $opt   = shift @_;

  my $fname_txt = $fname;

  # if we pass "w" to FileHandle->new() to indicate write, we can't pipe write!
  # so workaround it.

  my $is_pipe = 0;
  my $is_stdout = 0;
  my $fhw = undef;

  if (!Helpers::Misc::isEmpty($fname))
    {
      if ( $fname =~ m/^\|/)
        {
          $fhw = FileHandle->new($fname);
          $is_pipe = 1;
        }
      else
        {
          $fhw = FileHandle->new($fname, "w");
      }
    }
  else
    {
      $fhw = *STDOUT;
      $is_stdout = 1;
      $fname_txt = qq(STDOUT);
    }
  return (0, qq(Failed to open file $fname_txt for writing)) if (!defined $fhw);

  if (!$is_pipe && !$is_stdout && defined $opt && defined $opt->{'mode'})
    {
      my $count = chmod $opt->{'mode'}, $fname;
      if (!$count)
        {
          $fhw->close();
          $count = unlink $fname;
          return (0, qq(Failed to set mode of $fname_txt to ) . $opt->{'mode'} . qq( and failed to delete the file. This is bad)) if (!$count);
          return (0, qq(Failed to set mode of $fname_txt to ) . $opt->{'mode'} . qq( so it is deleted));
        }
    }
  $fhw->print($txt);
  $fhw->close() if (!$is_stdout);
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

  my $undefok = 0; $undefok = 1 if (defined $opt && defined $opt->{'undef_ok'} && $opt->{'undef_ok'} eq "1");
  if (!defined $ptr)
    {
      return (0, qq(Received an undef)) if (!$undefok);
      return (1, qq({}));
    }
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

  my $l = $main::logger;
  if (defined $l)
    {
      my $t_table = {
                      '0'   => qq(200),
                      '1'   => qq(503),
                      '-1'  => qq(500),
                    };
      my $json_code = qq(589); $json_code = $t_table->{$code} if (defined $t_table->{$code});
      $l->status($json_code);
      $l->log("%s", $assembled_msg);
    }
  else
    {
      printf("%s\n", $assembled_msg);
    }

  my $cwd = $main::saved_starting_dir;
  chdir($cwd) if (!Helpers::Misc::isEmpty($cwd));

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

sub deleteValueFromArray {
  my $array_ptr = shift @_;
  my $value = shift @_;

  my @new_array = ();
  foreach my $this_value (@$array_ptr)
    {
      push @new_array, $this_value if (!defined $value || $this_value ne $value);
    }
  return \@new_array;
}

sub isValidPortNumber
{
  my $port = shift @_;

  return 0 if (!Helpers::Misc::isUnsignedInteger($port));
  return 0 if ($port > 65534);
  return 1;
}

sub isValidIpV4CIDR
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

sub collapse_spaces
{
  my $txt = shift @_;
  return undef if (!defined $txt);

  $txt =~ s/\s+/ /g;
  $txt =~ s/^\s+//g;
  $txt =~ s/\s+$//g;

  return $txt;
}


1;
