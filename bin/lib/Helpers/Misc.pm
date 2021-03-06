package Helpers::Misc;

# Misc helper functions
# All of the functions should only use thread safe modules

use strict;
use warnings;

use FileHandle;
use File::Path;
use Cwd;
use DateTime;
use JSON;

BEGIN {
  our $VERSION = "0.39";
}

# readfile() and readfile_new() are functions to slurp content of a file.
# The difference is now an empty file is handled.
#
# readFile_new() returns (1, undef) for an empty file
# readFile()     returns (1, $dptr) where dptr is a reference to ''
#
# NOTICE: THIS FUNCTION API IS DEPRECATED. WHILE CODE IS BEING TRANSITIONED TO THE
#         WAY OF HANDLING -EMPTY- FILES USE readFile_new() DIRECTLY
#
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
#              $content_ptr   - Reference to the content of the file or an error message
#

sub readFile
{
  my $fname = shift @_;

  my ($ret, $dptr) = readFile_new($fname);
  return ($ret, $dptr) if (!$ret);

  my $old_empty = '';
  return ($ret, \$old_empty) if (!defined $dptr);
  return ($ret, $dptr);
}

sub readFile_new
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
      $fh        = *STDIN;
      $fname_txt = "<STDIN>";
      $is_stdin  = 1;
    }
  return (0, "Can't open $fname_txt") if (!defined $fh);

  while (my $line = <$fh>) { $txt .= $line; }
  $fh->close() if (!$is_stdin);
  return (1, \$txt) if ($txt ne '');
  return (1, undef);
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
#                        - mode          : chmod file to this permission.  Failure to change
#                                          mode upon opening causes an attempt to delete the
#                                          file and always returns error to the caler.
#                                          Applicable only to regular files.
#                        - append_file   : 1 - append to file instead of truncating it and
#                                              rewriting from the start
#                                          0 - normal operation - truncate the file
#                                          Applicable only to regular files.
#
#      OUTPUT: $ret    - Result code
#                        1 -- Success
#                        0 -- Failure
#              $r      - Text status of the result code. Typically additioanl hints about errors.

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
  my $is_append = 0;

  if (defined $opt && defined $opt->{'append_mode'})
    {
      my $errmsg = qq(writeFiile() received an {'append_mode'} parameter which was not 0 or 1);
      return (0, $errmsg) if (!isUnsignedInteger($opt->{'append_mode'}));
      return (0, $errmsg) if ($opt->{'append_mode'} != 0 && $opt->{'append_mode'} != 1);
      $is_append = 1 if ($opt->{'append_mode'} == 1);
    }

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
          my $write_mode = { "0" => "w", "1" => "a" };
          $fhw = FileHandle->new($fname, $write_mode->{$is_append});
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

#    FUNCTION: ($ret, $err) = deleteFile($filename, $opt)
#
#       INPUT: $filename   - a name of a file to delete
#              $opt        - a control hash
#
#                   .skip-not-found   1 - do not return an error if delete failed because file was not found
#                                     0 (default) - return error if delete failed because file was not found
#
#      OUTPUT:
#
# DESCRIPTION:
#
# $opt affects how the delete process is handled.
#
#  .skip-not-found => 1    Do not return an error in $ret if delete failed because file was not found.
#                  => 0    (default) Return error in $ret, $err if delete failed because file was not found.
#

sub deleteFile {
  my $fname = shift @_;
  my $opt   = shift @_;

  my $control = {
                  'skip-not-found' => 0,
                };

  if (defined $opt)
    {
      my $f = 'skip-not-found';
      if (defined $opt->{$f})
        {
          return (0, sprintf("opt.%s must be 0 or 1", $f)) if ($opt->{$f} ne "0" && $opt->{$f} ne "1");
          $control->{$f} = $opt->{$f};
        }
    }

  return (0, "Must provide the name of a file to delete") if (Helpers::Misc::isEmpty($fname));

  my $ret = unlink $fname;
  return (1, "OK") if ($ret == 1);

  # skip-not-found override

  return (1, $!) if ($control->{'skip-not-found'} && $! eq "No such file or directory");

  return (0, $!);
}


sub deleteDirectory {
  my $dirname = shift @_;

  return (0, "Must provide the name of a directory to delete") if (Helpers::Misc::isEmpty($dirname));

  my $ret = rmdir $dirname;

  return (0, $!) if ($ret != 1);
  return (1, "OK");

}

sub createDirectory {
  my $dir = shift @_;
  my $opt = shift @_;

  return (0, "directory must be defined")             if (Helpers::Misc::isEmpty($dir));
  return (0, "directory attributes must be defined")  if (!defined $opt);
  return (0, "directory mode must be defined")        if (!defined $opt->{'mode'});

  my $flag_need_create = 1;

  if ( -d $dir)
    {
      return (0, qq(Directory already exists)) if (defined $opt->{'exists-fails'} && $opt->{'exists-fails'});
      $flag_need_create = 0 if (defined $opt->{'exists-skips-create'} && $opt->{'exists-skips-create'});
    }

  $opt->{'logger'}->log($opt->{'creating-message'}) if (defined $opt->{'logger'} && !Helpers::Misc::isEmpty($opt->{'creating-message'}));

  my $ret_code = undef;

  File::Path::make_path($dir, { 'verbose' => 0, 'mode' => $opt->{'mode'}, 'error' => \$ret_code});
  return (0, @$ret_code[0]->{$dir}) if (scalar @$ret_code != 0);
  return (1, "OK");
}

sub deleteFileList
{
  my $list = shift @_;
  my $opt  = shift @_;

  return (0, "List is not defined")   if (!defined $list);
  return (0, "List is not an array")  if (ref($list) ne qq(ARRAY));

  my $l           = undef; $l = $opt->{'logger'} if (defined $opt && defined $opt->{'logger'});

  my $log_error       = undef; $log_error      = 1 if (defined $l && defined $opt->{'log-error'}   && $opt->{'log-error'}   eq "1");
  my $log_success     = undef; $log_success    = 1 if (defined $l && defined $opt->{'log-success'} && $opt->{'log-success'} eq "1");

  my $log_not_found   = 0; $log_not_found  = 1 if (defined $l && defined $opt->{'log-not-found'} && $opt->{'log-not-found'} eq "1");
  my $skip_not_found  = 0; $skip_not_found = 1 if (defined $opt->{'skip-not-found'} && $opt->{'skip-not-found'} eq "1");;

  my $has_errors = 0;

  foreach my $this_file (@{$list})
    {
      my ($ret, $errcode) = Helpers::Misc::deleteFile($this_file, { 'skip-not-found' => $skip_not_found });
      if (!$ret)
        {
          $l->log("Failed to delete file %s : %s", $this_file, $errcode) if ($log_error);
          $has_errors = 1 if (!$has_errors);
        }
      else
        {
          if ($log_not_found && $errcode eq "No such file or directory")
            {
              $l->log("Non-fatal error: file %s was not found", $this_file);
            }
          else
            {
              $l->log("Successfully deleted file %s", $this_file) if ($log_success);
            }
        }
    }
  return (0, "Some files were not deleted") if ($has_errors);
  return (1, "OK");

}

sub deleteDirectoryList
{
  my $list = shift @_;
  my $opt  = shift @_;

  return (0, "List is not defined")   if (!defined $list);
  return (0, "List is not an array")  if (ref($list) ne qq(ARRAY));

  my $l           = undef; $l = $opt->{'logger'} if (defined $opt && defined $opt->{'logger'});

  my $log_error   = undef; $log_error   = 1 if (defined $l && defined $opt->{'log-error'}   && $opt->{'log-error'}   eq "1");
  my $log_success = undef; $log_success = 1 if (defined $l && defined $opt->{'log-success'} && $opt->{'log-success'} eq "1");

  my $has_errors = 0;

  my @next_pass_list = @{$list};

  for (my $this_pass = 1;; $this_pass++)
    {
      $has_errors      = 0;
      my $pass_deleted = 0;

      my @dirs2remove  = @next_pass_list;
      @next_pass_list  = ();

      foreach my $this_dir (@dirs2remove)
        {
          my ($ret, $errcode) = Helpers::Misc::deleteDirectory($this_dir);
          if (!$ret)
            {
              $l->log("Failed to delete directory %s during pass #%s : %s", $this_dir, $this_pass, $errcode) if ($log_error);
              $has_errors = 1 if (!$has_errors);

              push @next_pass_list, $this_dir;
              next;
            }

          $l->log("Successfully deleted directory %s during pass #%s", $this_dir, $this_pass) if ($log_success);
          $pass_deleted++;
        }

      last if ($has_errors   == 0); # it was a final pass because we deleted everything
      last if ($pass_deleted == 0); # it was a final pass because we deleted nothing
    }
  return (0, "Some directories were not deleted") if ($has_errors);
  return (1, "OK");
}


sub isEmpty
{
  my $a = shift @_;
  my $r = 0;

  return 1 if (!defined $a);
  $r = 1 if (($a eq "") || ($a =~ m/^\s+$/g));

  return $r;
}

sub isStringOctal
{
  my $str = shift @_;

  return 0 if (isEmpty($str));
  return 0 if (substr($str, 0, 1 ne '0'));

  $str =~ s/[0-7]+//g;
  return 0 if ($str ne '');
  return 1;
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
  my $is_pretty     = 0;
  my $is_canonical  = 0;
  if (defined $opt)
    {
      $is_pretty    = $opt->{'pretty'}    if (defined $opt->{'pretty'}    && $opt->{'pretty'} eq "1"    );
      $is_canonical = $opt->{'canonical'} if (defined $opt->{'canonical'} && $opt->{'canonical'} eq "1" );
    }

  my $json = JSON->new->utf8->allow_nonref;
  $json = $json->canonical(1) if ($is_canonical);
  $json = $json->pretty(1)    if ($is_pretty);

  return (1, $json->encode($ptr));
}

# FUNCTION: $str = strip_comments($s)
#
# DESCRIPTION: Function strips comments starting from #.
#
#       INPUT: $s   - string
#
#      OUTPUT: $str - string to the left of a comment symbol.
#                     $str is undef if $f is undef
#                     $str is '' if comment symbol if the first
#                     character of the string.

sub strip_comments
{
  my $str = shift @_;

  return undef if (!defined $str);

  my ($before, $after) = split('#', $str, 2);
  $before = '' if (!defined $before);
  return $before;
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

sub removeValueFromArray {
  my $array_ptr = shift @_;
  my $value = shift @_;

  my @new_array = ();
  my $count = 0;
  foreach my $this_value (@$array_ptr)
    {
      if (!defined $value || $this_value ne $value)
        {
          push @new_array, $this_value;
          next;
        }
      $count++;
    }
  return ($count, \@new_array);
}


sub isValidPortNumber
{
  my $port = shift @_;

  return 0 if (!Helpers::Misc::isUnsignedInteger($port));
  return 0 if ($port > 65534);
  return 1;
}

sub isValidRegex
{
  my $regex = shift @_;

  eval { qr/$regex/ }; if ($@) { return 0; }
  return 1;
}

sub isValidIpV4
{
  my $ipv4 = shift @_;

  return 0 if (Helpers::Misc::isEmpty($ipv4));

  my @octets = split('\.', $ipv4, 5);
  return 0 if (scalar @octets != 4);
  foreach my $octet (@octets)
    {
      return 0 if (!Helpers::Misc::isUnsignedInteger($octet));
      return 0 if ($octet > 255);
    }
  return 1;
}

sub isValidIpV4CIDR
{
  my $cidr = shift @_;

  return 0 if (Helpers::Misc::isEmpty($cidr));
  my ($ipv4, $slash, $junk) = split('/', $cidr, 3);
  return 0 if (!Helpers::Misc::isEmpty($junk));
  return 0 if (!Helpers::Misc::isValidIpV4($ipv4));
  return 0 if (!Helpers::Misc::isUnsignedInteger($slash));
  return 0 if ($slash > 32);

  return 1;
}

sub isValidDNSZone
{
  my $zone = shift @_;
  return 0 if (Helpers::Misc::isEmpty($zone));

  return 0 if ($zone =~ m/^\./);
  return 0 if ($zone =~ m/\.\./);

  $zone =~ s/[a-z]|[A-Z]//g;
  $zone =~ s/-|_//g;
  $zone =~ s/[0-9]//g;
  $zone =~ s/\.//g;
  return 0 if $zone ne '';
  return 1;

}

sub isUnsignedInteger
{
  my $a = shift @_;

  return 0 if (isEmpty($a));
  return 1 if ( $a =~ /^\d+$/g );
  return 0;
}

sub isPositiveInteger
{
  my $a = shift @_;

  return 0 if (!isInteger($a));
  return ($a > 0);
}

sub isInteger
{
  my $a = shift @_;

  my $r = 0;
  if (!isEmpty($a))
    {
      $a = sprintf("%s", $a);
      $a =~ s/^\+//g;
      $a =~ s/^-//g;

      $r = isUnsignedInteger($a);
    }
  return $r;
}

sub collapse_spaces
{
  my $txt = shift @_;
  my $opt = shift @_;

  return undef if (!defined $txt);


  my $default_opt = {
                      'trailing' => 1,
                      'middle'   => 1,
                      'leading'  => 1,
                    };

  if (defined $opt)
    {
      foreach my $f (keys %{$default_opt})
        {
          $default_opt->{$f} = $opt->{$f} if (defined $opt->{$f});
        }
    }

  $txt =~ s/\s+/ /g if ($default_opt->{'middle'}   == 1);
  $txt =~ s/^\s+//g if ($default_opt->{'leading'}  == 1);
  $txt =~ s/\s+$//g if ($default_opt->{'trailing'} == 1);

  return $txt;
}

sub perl_function
{
  return (caller(1))[3];
}

# sanitizePath collapses certain annoying patterns

sub sanitizePath
{
  my $p = shift @_;
  return undef if (!defined $p);

  $p =~ s/\/+/\//g;   # collapse multiple / into a single slash
  $p =~ s/\/\.\/$//g; # strip /./ at the end of a sanitizePath

  return $p;
}

sub timestamp_in_ms
{
  my $dt = DateTime->now();
  my $etime_ms = int($dt->epoch()) * 1000;
  return sprintf("%s", $etime_ms);
}

sub utc_to_string
{
  my $opt = shift @_;

  my $default_formatter = "%Y-%m-%d %H:%M:%S %Z";
  my $default_epoch     = time();

  my $formatter = $default_formatter; $formatter = $opt->{'formatter'} if (defined $opt->{'formatter'});
  my $epoch     = $default_epoch;     $epoch     = $opt->{'epoch'}     if (defined $opt->{'epoch'});

  my $dt = DateTime->from_epoch(epoch => $epoch );
  my $now_str = sprintf("%s", $dt->strftime($formatter));
  return $now_str;
}

sub datetime_ymd_hms
{
  my $dt = shift @_;

  $dt = DateTime->now() if (!defined $dt);
  my $now_str = sprintf("%s %s", $dt->ymd, $dt->hms);
  return $now_str;
}

sub is_odd
{
  my $num = shift @_;

  return $num % 2;
}

sub is_active_pid {
  my $pid = shift @_;

  my $cnt = kill 'ZERO', $pid;
  return $cnt == 1;
}

# FUNCTION $ret = is_active_pid_in_file($pidfile)
#
# DESCRIPTION: Checks if the content of a $pidfile is a
#              currently running process ID.
#
#  INPUT: $pidfile - file name to check
#
# OUTPUT: 1 - the conent of a file is a currently running
#             process ID.
#         0 - the content of a file is not a currently running
#             process ID or an error happened while checking

sub is_active_pid_in_file {
  my $fname = shift @_;

  return 0 if (Helpers::Misc::isEmpty($fname));
  return 0 if (! -e $fname);

  my ($ret, $dptr) = Helpers::Misc::readFile($fname);
  return 0 if (!$ret);
  my $pid = $$dptr;
  return 0 if (!Helpers::Misc::isUnsignedInteger($pid));

  ($ret, $dptr) = Helpers::Misc::readFile(qw(/proc/sys/kernel/pid_max));
  return 0 if (!$ret);
  my $max_pid = $$dptr;
  return 0 if (!Helpers::Misc::isUnsignedInteger($max_pid));

  return 0 if ($pid < 2 || $pid > $max_pid);

  return Helpers::Misc::is_active_pid($pid);
}

sub isValidUuidV4 {
  my $uuid = shift @_;

  return 0 if (!defined $uuid);

  $uuid =~ s/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$//i;

  return 1 if ($uuid eq '');
  return 0;
}

sub isInBetween
{
  my $p    = shift @_;
  my $low  = shift @_;
  my $high = shift @_;

  return 0 if (!isInteger($p));
  return 0 if (!isInteger($low));
  return 0 if (!isInteger($high));

  return 0 if ($p < $low);
  return 0 if ($p > $high);
  return 1;
}

1;
