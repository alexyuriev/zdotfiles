package Helpers::RedisClient;
use strict;
use warnings;

BEGIN {
  our $VERSION = "0.6";
}

use strict;
use warnings;

use Redis::Client;
use Helpers::Misc;

use constant ERROR_REDIS_ERROR      => qq(ERROR: %s - %s);
use constant ERROR_REDIS_NO_REDIS   => qq(ERROR: %s - Redis handle must be defined);
use constant ERROR_REDIS_NO_KEY     => qq(ERROR: %s - Redis key must be defined);
use constant ERROR_REDIS_NO_2NDKEY  => qq(ERROR: %s - 2nd redis key must also be defined);
use constant ERROR_REDIS_NO_PAYLOAD => qq(ERROR: %s - Redis payload not defined);

sub validateRedisCredentials
{
  my $creds = shift @_;

  return (0, qq(redis_creds - no hostname)) if (Helpers::Misc::isEmpty($creds->{'hostname'}));
  return (0, qq(redis_creds - no port))     if (Helpers::Misc::isEmpty($creds->{'port'}));
  return (0, qq(redis_creds - no password)) if (Helpers::Misc::isEmpty($creds->{'password'}));
  return (0, qq(redis_creds - no database)) if (Helpers::Misc::isEmpty($creds->{'db'}));

  return (1, qq(OK));
}

sub getRedisConnection
{
  my $creds = shift @_;

  my $err_tmpl = qq(ERROR:) . Helpers::Misc::perl_function() . " - %s";
  my ($ret, $v) = validateRedisCredentials($creds);
  return (0, sprintf($err_tmpl, $v)) if (!$ret);

  my $redis_url = Helpers::RedisClient::obj_to_string($creds);

  my $redis = Redis::Client->new( host => $creds->{'hostname'}, port => $creds->{'port'} );
  return (0, sprintf($err_tmpl, "failed to connect to redis server " . $redis_url)) if (!defined $redis);

  ($ret, $v) = auth($redis, $creds->{'password'});
  return (0, sprintf($err_tmpl, "auth failed - " . $v)) if (!$ret);

  ($ret, $v) = select_db($redis, $creds->{'db'});
  return (0, sprintf($err_tmpl, "db switch failed - ". $v)) if (!$ret);
  return (1, $redis);
}

sub obj_to_string {
  my $r = shift @_;

  return sprintf("redis://%s:%s/%s", $r->{'hostname'}, $r->{'port'}, $r->{'db'});
}

sub auth {
  my $redis  = shift @_;
  my $passwd = shift @_;

  my $v = undef;
  eval  {
          $v = $redis->send_command("auth", $passwd);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub select_db {
  my $redis = shift @_;
  my $db    = shift @_;

  my $v = undef;
  eval  {
          $v = $redis->send_command("select", $db);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub multi {
  my $redis = shift @_;

  my $v = undef;
  eval  {
          $v = $redis->send_command("multi");
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub redis_exec {
  my $redis = shift @_;

  my $v = undef;
  eval  {
          $v = $redis->send_command("exec");
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub discard {
  my $redis = shift @_;

  my $v = undef;
  eval  {
          $v = $redis->send_command("discard");
        };
  return (0, $@) if ($@);
  return (1, $v);
}


sub queue_move_element
{
  my $redis = shift @_;
  my $src_q = shift @_;
  my $dst_q = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,  $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,    $pf_name)) if (Helpers::Misc::isEmpty($src_q));
  return (0, sprintf(ERROR_REDIS_NO_2NDKEY, $pf_name)) if (Helpers::Misc::isEmpty($dst_q));

  my $v = undef;
  eval {
          $v = $redis->rpoplpush($src_q, $dst_q);
       };
  return (0, sprintf(ERROR_REDIS_ERROR, $pf_name, $@)) if ($@);
  return (1, $v);
}

sub queue_safe_load_element
{
  my $redis  = shift @_;
  my $q_name = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS, $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,   $pf_name)) if (Helpers::Misc::isEmpty($q_name));

  my ($ret, $v) = queue_move_element($redis, $q_name, $q_name);
}

sub queue_add_element
{
  my $redis  = shift @_;
  my $q_name = shift @_;
  my $elem   = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,   $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,     $pf_name)) if (Helpers::Misc::isEmpty($q_name));
  return (0, sprintf(ERROR_REDIS_NO_PAYLOAD, $pf_name)) if (Helpers::Misc::isEmpty($elem));

  my $r = undef;
  eval  {
          $r = $redis->lpush($q_name, $elem);
        };
  return (0, sprintf(ERROR_REDIS_ERROR, $pf_name, $@)) if ($@);
  return (1, $r);
}

sub queue_remove_element
{
  my $redis  = shift @_;
  my $q_name = shift @_;
  my $elem   = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,   $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,     $pf_name)) if (Helpers::Misc::isEmpty($q_name));
  return (0, sprintf(ERROR_REDIS_NO_PAYLOAD, $pf_name)) if (Helpers::Misc::isEmpty($elem));

  my $r = undef;
  eval  {
           $r = $redis->lrem($q_name, 0, $elem);
        };
  return (0, sprintf(ERROR_REDIS_ERROR, $pf_name, $@)) if ($@);
  return (1, $r);
}

sub queue_safe_load_element_blocking
{
  my $redis   = shift @_;
  my $q_name  = shift @_;
  my $timeout = shift @_;

  $timeout = 1 if (!Helpers::Misc::isUnsignedInteger($timeout));
  my $v = undef;

  eval  {
          $v = $redis->brpoplpush($q_name, $q_name, $timeout);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub queue_length
{
  my $redis  = shift @_;
  my $q_name = shift @_;

  my $v = undef;
  eval  {
          $v = $redis->llen($q_name);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub get_set_members
{
  my $redis    = shift @_;
  my $set_name = shift @_;

  my @v = ();
  eval  {
          @v = $redis->smembers($set_name);
        };
   return (0, $@)    if ($@);
   return (1, undef) if (scalar @v == 0);
   return (1, \@v);
}

sub sadd {
  my $redis    = shift @_;
  my $set_name = shift @_;
  my $v        = shift @_;

  my $r = undef;

  eval  {
          $r = $redis->sadd($set_name, $v);
        };
  return (0, $@) if ($@);
  return (1, $r);
}

sub sismember {
  my $redis     = shift @_;
  my $set_name  = shift @_;
  my $v         = shift @_;

  my $r = undef;

  eval {
          $r = $redis->sismember($set_name, $v);
       };
  return (0, $@) if ($@);
  return (1, $r);
}

sub queue_load_by_index {
  my $redis   = shift @_;
  my $q_name  = shift @_;
  my $index   = shift @_;

  my $v = undef;

  eval  {
          $v = $redis->lindex($q_name, $index);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub set_hash_additive {
  my $redis    = shift @_;
  my $key      = shift @_;
  my $attr_ref = shift @_;

  my $v = undef;
  eval { $v = $redis->hmset($key, %$attr_ref); };
  return (0, $@) if ($@);
  return (1, $v);
}

sub get_hash_attributes {
  my $redis     = shift @_;
  my $key       = shift @_;
  my $attr_ref  = shift @_;

  return (0, qq(key must be defined)) if (Helpers::Misc::isEmpty($key));

  my $errtxt = qq(Attribute list must be an array);
  return (0, $errtxt) if (Helpers::Misc::isEmpty($attr_ref));
  return (0, $errtxt) if (ref $attr_ref ne qq(ARRAY));

  my ($ret, $full_hash_ref) = hgetall($redis, $key);
  return (0, $full_hash_ref) if (!$ret);

  my %this_stripped_hash;

  foreach my $this_key (@$attr_ref)
    {
      $this_stripped_hash{$this_key} = $full_hash_ref->{$this_key};
    }
  return (1, \%this_stripped_hash);
}

sub get_hash_single_attribute {
  my $redis = shift @_;
  my $key   = shift @_;
  my $attr  = shift @_;

  return (0, qq(Redis must be defined)) if (!defined $redis);
  return (0, qq(Hash key name must be defined)) if (Helpers::Misc::isEmpty($key));
  return (0, qq(Hash key attribute must be defined)) if (Helpers::Misc::isEmpty($attr));

  my $v = undef;
  eval { $v = $redis->hget($key, $attr); };
  return (0, $@) if ($@);
  return (1, $v);
}

sub hgetall {
  my $redis = shift @_;
  my $key   = shift @_;

  my %v = {};
  eval { %v = $redis->hgetall($key); };
  return (0, $@) if ($@);
  return (1, \%v);
}

sub get {
  my $redis = shift @_;
  my $key   = shift @_;

  my $v = undef; eval { $v = $redis->get($key); };
  return (0, $@) if ($@);
  return (1, $v);
}

sub set {
  my $redis = shift @_;
  my $key   = shift @_;
  my $v     = shift @_;

  my $r = undef;
  eval { $r = $redis->set($key, $v); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub expire {
  my $redis = shift @_;
  my $key   = shift @_;
  my $ttl   = shift @_;

  my $r = undef;
  eval { $r = $redis->expire($key, $ttl); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub ping {
  my $redis = shift @_;

  my $r = undef;
  eval { $r = $redis->ping(); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub hset {
  my $redis = shift @_;
  my $k = shift @_;
  my $e = shift @_;
  my $v = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($k));
  return (0, "bad or missing element") if (Helpers::Misc::isEmpty($e));
  return (0, "bad or missing value")   if (Helpers::Misc::isEmpty($v));

  my $r = undef;
  eval { $r = $redis->hset($k, $e => $v); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub redis_keys {
  my $redis = shift @_;
  my $key   = shift @_;

  my @v = undef;
  eval { @v = $redis->keys($key); };
  return (0, $@) if ($@);
  return (1, \@v);
}

sub zrange {
  my $redis = shift @_;
  my $key   = shift @_;
  my $start = shift @_;
  my $end   = shift @_;

  my @v = undef;
  eval { @v = $redis->zrange($key, $start, $end); };
  return (0, @$) if ($@);
  return (1, \@v);
}

sub multi_exec
{
  my $redis = shift @_;
  my $cmd_ptr = shift @_;

  my @cmd_list = @{$cmd_ptr};
  my $cmd = { 'multi' => [] };
  unshift @cmd_list, $cmd;
  $cmd = { 'exec' => [] };
  push @cmd_list, $cmd;

  my $t = {
            "multi"   => \&multi,
            "set"     => \&set,
            "hset"    => \&hset,
            "expire"  => \&expire,
            "exec"    => \&redis_exec,
          };

  foreach my $this_command (@cmd_list)
    {
      my $r = undef;
      my $v = undef;
      my $ret = undef;

      my ($redis_cmd) = keys %{$this_command};
      if (!defined $t->{$redis_cmd})
        {
          ($ret, $r) = Helpers::RedisClient::discard($redis);
          return (0, sprintf("unknown redis command '%s'", $redis_cmd));
        }
      if (scalar @{$this_command->{$redis_cmd}})
        {
            ($ret, $v) = $t->{$redis_cmd}->($redis, @{$this_command->{$redis_cmd}});
        }
      else
        {
            ($ret, $v) = $t->{$redis_cmd}->($redis);
        }

      if (!$ret)
        {
          ($ret, $r) = Helpers::RedisClient::discard($redis);
          return (0, $v);
        }
    }
  return (1, "ok");
}


1;

