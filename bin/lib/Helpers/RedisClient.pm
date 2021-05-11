package Helpers::RedisClient;
use strict;
use warnings;

BEGIN {
  our $VERSION = "0.23";
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
use constant ERROR_REDIS_NO_VALUE   => qq(ERRORL %s - Value is not defined);

use constant _REDIS_CLIENT_MAGIC_MARKER => qq(*** Helpers::RedisClient magic marker ***);

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

  my @v = ();
  eval  {
          @v = $redis->send_command("exec");
        };

  return (0, $@) if ($@);
  return (1, \@v);
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

sub del {
  my $redis = shift @_;
  my $key   = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,  $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,    $pf_name)) if (Helpers::Misc::isEmpty($key));

  # del can take multiple keys

  my @args = (); push @args, $key;
  while ($key = shift @_) { push @args, $key; }

  my $v = undef;
  eval  {
          $v = $redis->del(@args);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub rpoplpush
{
  my $redis = shift @_;
  my $src_q = shift @_;
  my $dst_q = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,  $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,    $pf_name)) if (Helpers::Misc::isEmpty($src_q));
  return (0, sprintf(ERROR_REDIS_NO_2NDKEY, $pf_name)) if (Helpers::Misc::isEmpty($dst_q));

  my ($ret, $v) = queue_move_element($redis, $src_q, $dst_q);
  return ($ret, $v);
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

sub lpush
{
  my $redis  = shift @_;
  my $q_name = shift @_;
  my $elem   = shift @_;

  my ($ret, $r) = queue_add_element($redis, $q_name, $elem);
  return ($ret, $r);

}

sub rpush
{
  my $redis  = shift @_;
  my $key    = shift @_;
  my $value  = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,  $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,    $pf_name)) if (Helpers::Misc::isEmpty($key));
  return (0, sprintf(ERROR_REDIS_NO_VALUE,  $pf_name)) if (Helpers::Misc::isEmpty($value));

  my $v = undef;
  eval  {
          $v = $redis->rpush($key, $value);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub ltrim
{
  my $redis  = shift @_;
  my $key    = shift @_;
  my $start  = shift @_;
  my $stop   = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,  $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,    $pf_name)) if (Helpers::Misc::isEmpty($key));
  return (0, sprintf("Start position not defined",  $pf_name)) if (Helpers::Misc::isEmpty($start));
  return (0, sprintf("Stop position not defined",   $pf_name)) if (Helpers::Misc::isEmpty($stop));

  my $v = undef;
  eval  {
          $v = $redis->ltrim($key, $start, $stop);
        };
  return (0, $@) if ($@);
  return (1, $v);
}

sub echo
{
  my $redis  = shift @_;
  my $value  = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  my $v = undef;
  eval {
          $v = $redis->echo($value);
       };
  return (0, sprintf(ERROR_REDIS_ERROR, $pf_name, $@)) if ($@);
  return (1, $v);
}

sub type
{
  my $redis = shift @_;
  my $key   = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS, $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,   $pf_name)) if (Helpers::Misc::isEmpty($key));

  my $v = undef;
  eval { $v = $redis->type($key); };
  return (0, sprintf(ERROR_REDIS_ERROR, $pf_name, $@)) if ($@);
  return (1, $v);
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

sub lrem
{
  my $redis  = shift @_;
  my $q_name = shift @_;
  my $elem   = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,   $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,     $pf_name)) if (Helpers::Misc::isEmpty($q_name));
  return (0, sprintf(ERROR_REDIS_NO_PAYLOAD, $pf_name)) if (Helpers::Misc::isEmpty($elem));

  my ($ret, $dptr) = queue_remove_element($redis, $q_name, $elem);
  return ($ret, $dptr);
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

sub llen {
  my $redis = shift @_;
  my $q_name = shift @_;

  return (0, qq(Redis must be defined))           if (!defined $redis);
  return (0, qq(Queue name name must be defined)) if (Helpers::Misc::isEmpty($q_name));

  my ($ret, $v) = queue_length($redis, $q_name);
  return ($ret, $v);
}

sub lrange {
  my $redis   = shift @_;
  my $q_name  = shift @_;
  my $start   = shift @_;
  my $end     = shift @_;

  return (0, qq(Redis must be defined))           if (!defined $redis);
  return (0, qq(Queue name name must be defined)) if (Helpers::Misc::isEmpty($q_name));

  my @v = ();
  eval  {
          @v = $redis->lrange($q_name, $start, $end);
        };
  return (0, $@)    if ($@);
  return (1, undef) if (scalar @v == 0);
  return (1, \@v);
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

sub smembers
{
  my $redis    = shift @_;
  my $set_name = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,    $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,      $pf_name)) if (Helpers::Misc::isEmpty($set_name));

  my ($ret, $v) = get_set_members($redis, $set_name);
  return ($ret, $v);
}

sub srem {
  my $redis    = shift @_;
  my $set_name = shift @_;
  my $v        = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,    $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,      $pf_name)) if (Helpers::Misc::isEmpty($set_name));
  return (0, sprintf(ERROR_REDIS_NO_2NDKEY,   $pf_name)) if (Helpers::Misc::isEmpty($v));

  my $r = undef;

  eval  {
          $r = $redis->srem($set_name, $v);
        };
  return (0, $@) if ($@);
  return (1, $r);
}


sub sadd {
  my $redis    = shift @_;
  my $set_name = shift @_;
  my $v        = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,    $pf_name))  if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,      $pf_name))  if (Helpers::Misc::isEmpty($set_name));
  return (0, sprintf(ERROR_REDIS_NO_PAYLOAD,  $pf_name))  if (!defined $v);

  my $r = undef;

  eval  {
          $r = $redis->sadd($set_name, $v);
        };
  return (0, $@) if ($@);
  return (1, $r);
}

sub scard {
  my $redis    = shift @_;
  my $set_name = shift @_;

  my $pf_name = Helpers::Misc::perl_function();

  return (0, sprintf(ERROR_REDIS_NO_REDIS,    $pf_name)) if (!defined $redis);
  return (0, sprintf(ERROR_REDIS_NO_KEY,      $pf_name)) if (Helpers::Misc::isEmpty($set_name));

  my $r = undef;

  eval  {
          $r = $redis->scard($set_name);
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

sub hmset {
  my $redis    = shift @_;
  my $key      = shift @_;
  my $attr_ref = shift @_;

  return (0, qq(Redis must be defined))               if (!defined $redis);
  return (0, qq(Hash key name must be defined))       if (Helpers::Misc::isEmpty($key));
  return (0, qq(Hash key attribute must be defined))  if (!defined $attr_ref);

  my ($ret, $v) = set_hash_additive($redis, $key, $attr_ref);
  return ($ret, $v);
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

  my %v;
  eval { %v = $redis->hgetall($key); };
  return (0, $@) if ($@);
  return (1, undef) if (! keys %v);
  return (1, \%v);
}

sub hgetall_multi {
  my $redis = shift @_;
  my $key   = shift @_;

  my $v;
  eval { $v = $redis->hgetall($key); };
  return (0, $@) if ($@);
  return (0, undef) if ($v ne qq(QUEUED));
  return (1, "QUEUED");
}

sub set {
  my $redis = shift @_;
  my $key   = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($key));

  my @v = ();
  while (my $val = shift @_)
    {
      push @v, $val;
    }
  return (0, "value missing") if (scalar @v == 0);

  my $r = undef;
  eval { $r = $redis->send_command("set", $key, @v); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub setnx {
  my $redis = shift @_;
  my $key   = shift @_;
  my $v     = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($key));
  return (0, "missing value")          if (Helpers::Misc::isEmpty($v));

  my $r = undef;
  eval { $r = $redis->setnx($key, $v); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub get {
  my $redis = shift @_;
  my $key   = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($key));

  my $r = undef;
  eval { $r = $redis->get($key); };
  return (0, $@) if ($@);
  return (1, $r);

}

sub expire {
  my $redis = shift @_;
  my $key   = shift @_;
  my $ttl   = shift @_;

  return (0, "unknown redis")      if (!defined $redis);
  return (0, "bad or missing key") if (Helpers::Misc::isEmpty($key));
  return (0, "bad ttl")            if (!Helpers::Misc::isInteger($ttl));

  my $r = undef;
  eval { $r = $redis->expire($key, $ttl); };
  return (0, $@) if ($@);
  return (1, $r);
}

sub persist {
  my $redis = shift @_;
  my $key   = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($key));

  my $r = undef;
  eval { $r = $redis->persist($key); };
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

sub hsetnx {
  my $redis = shift @_;
  my $k = shift @_;
  my $e = shift @_;
  my $v = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($k));
  return (0, "bad or missing element") if (Helpers::Misc::isEmpty($e));
  return (0, "bad or missing value")   if (Helpers::Misc::isEmpty($v));

  my $r = undef;
  eval { $r = $redis->hsetnx($k, $e => $v); };
  return (0, $@) if ($@);
  return (1, $r);
}


sub hdel {
  my $redis = shift @_;
  my $k = shift @_;
  my $e = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($k));
  return (0, "bad or missing element") if (Helpers::Misc::isEmpty($e));

  my $r = undef;
  eval { $r = $redis->hdel($k, $e); };
  return (0, $@) if ($@);
  return (1, $r);
}


sub hget {
  my $redis = shift @_;
  my $k = shift @_;
  my $e = shift @_;

  return (0, "unknown redis")          if (!defined $redis);
  return (0, "bad or missing key")     if (Helpers::Misc::isEmpty($k));
  return (0, "bad or missing element") if (Helpers::Misc::isEmpty($e));

  my $v = undef;
  eval { $v = $redis->hget($k, $e); };
  return (0, $@) if ($@);
  return (1, $v);
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
            "del"     => \&del,
            "set"     => \&set,
            "get"     => \&get,
            "hset"    => \&hset,
            "hmset"   => \&hmset,
            "hgetall" => \&hgetall_multi,
            "lrem"    => \&lrem,
            "llen"    => \&llen,
            "lpush"   => \&lpush,
            "expire"  => \&expire,
            "exec"    => \&redis_exec,
          };

  my $v = undef;
  foreach my $this_command (@cmd_list)
    {
      my $ret = undef;

      my ($redis_cmd) = keys %{$this_command};

      if (!defined $t->{$redis_cmd})
        {
          ($ret, $v) = Helpers::RedisClient::discard($redis);
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
          ($ret, $v) = Helpers::RedisClient::discard($redis);
          return (0, $v);
        }
    }

  return (1, $v);
}

sub new_multi_exec
{
  my $redis = shift @_;
  my $cmd_ptr = shift @_;

  my @cmd_list_orig = @{$cmd_ptr};

  # Because Redis returns array of arrays on multi/exec which is the results of the
  # execution of all the commands in the order they were issued and because perl Redis::Client
  # flattens them we have to inject a marker that would separate results of the commands by
  # making the server insert a separator string between them.
  #
  # Since the string is always inserted it will always be the last element of the last command which
  # makes parsing reply easier.

  my @cmd_list = ( { 'multi' => [] } );
  foreach my $cmd (@{$cmd_ptr})
    {
      push @cmd_list, $cmd;
      push @cmd_list, { 'echo' => [ _REDIS_CLIENT_MAGIC_MARKER ]};
    }
  push @cmd_list, { 'exec' => [] };

  # table contains:
  #    "name" of redis command => { call => \&implementation, type => type of the result }

  my $t = {
            "multi"   =>  {
                            call => \&multi,
                            type => "string",
                          },
            "type"     => {
                            call => \&type,
                            type => "string",
                          },
            "del"     =>  {
                            call => \&del,
                            type => "string",
                          },
            "set"     =>  {
                            call => \&set,
                            type => "string",
                          },
            "setnx"   =>  {
                            call => \&setnx,
                            type => "string",
                          },
            "get"     =>  {
                            call => \&get,
                            type => "string",
                          },
            "hset"    =>  {
                            call => \&hset,
                            type => "string",
                          },
            "hsetnx"  =>  {
                            call => \&hsetnx,
                            type => "string",
                          },
            "hdel"    =>  {
                            call => \&hdel,
                            type => "string",
                          },
            "hmset"   => {
                            call => \&hmset,
                            type => "string",
                          },
            "hgetall" => {
                            call => \&hgetall_multi,
                            type => "hash",
                          },
            "lrem"    => {
                            call => \&lrem,
                            type => "string",
                          },
            "llen"    => {
                            call => \&llen,
                            type => "string",
                          },
            "lpush"   => {
                            call => \&lpush,
                            type => "string",
                          },
            "rpush"   => {
                            call => \&rpush,
                            type => "string",
                          },
            "ltrim"   => {
                            call => \&rpush,
                            type => "string",
                          },
            "lrange"   => {
                            call => \&lrange,
                            type => "array",
                          },
            "expire"  =>  {
                            call => \&expire,
                            type => "string",
                          },
            "persist" =>  {
                            call => \&persist,
                            type => "string",
                          },
            "echo"    =>  {
                            call => \&echo,
                            type => "string",
                          },
            "sadd"    =>  {
                            call => \&sadd,
                            type => "string",
                          },
            "srem"    =>  {
                            call => \&srem,
                            type => "string",
                          },
            "exec"    => {
                            call => \&redis_exec,
                            type => "string",
                          }
          };

  my $v = undef;
  foreach my $this_command (@cmd_list)
    {
      my $ret = undef;

      my ($redis_cmd) = keys %{$this_command};

      if (!defined $t->{$redis_cmd})
        {
          ($ret, $v) = Helpers::RedisClient::discard($redis);
          return (0, sprintf("unknown redis command '%s'", $redis_cmd));
        }
      if (scalar @{$this_command->{$redis_cmd}})
        {
            ($ret, $v) = $t->{$redis_cmd}->{'call'}->($redis, @{$this_command->{$redis_cmd}});
        }
      else
        {
            ($ret, $v) = $t->{$redis_cmd}->{'call'}->($redis);
        }

      if (!$ret)
        {
          ($ret, $v) = Helpers::RedisClient::discard($redis);
          return (0, $v);
        }
    }

  my $len = scalar @$v;

  my @final = ();
  my $cmd_index = 0;
  my $index_start = 0; my $array_length = 0;
  for (my $i = 0; $i < $len; $i++)
    {
      if (defined @$v[$i] && @$v[$i] eq _REDIS_CLIENT_MAGIC_MARKER )
        {
          my $entry = $cmd_list_orig[$cmd_index];
          my ($cmd) = keys %$entry;

          my $cmd_type = $t->{$cmd}->{'type'};
          $cmd_type = "default" if (   $cmd_type ne qq(string)
                                    && $cmd_type ne qq(hash)
                                    && $cmd_type ne qq(array));

          my $opt = {  'cmd'          => $cmd,
                       'index-start'  => $index_start,
                       'array-length' => $array_length,
                     };

          my $dt =  {
                      "string"    => \&stringFromSubArray,
                      "hash"      => \&hashFromSubArray,
                      "array"     => \&subArray,
                      "default"   => \&defaultArrayFromSubArray,
                    };

          push @final, $dt->{$cmd_type}($v, $opt);

          $index_start = $i + 1;
          $array_length = 0;
          $cmd_index++;
          next;
        }
      $array_length++;
    }

  return (1, \@final);
}

sub subArray
{
  my $array_ptr = shift @_;
  my $opt = shift @_;

  my @src = @$array_ptr;

  my @new_array = @src[$opt->{'index-start'} .. ($opt->{'index-start'} + $opt->{'array-length'}) - 1 ]; # range operates on indexes, so we need to decrease a length by 1.
  return \@new_array;

}

sub defaultArrayFromSubArray
{
  my $array_ptr = shift @_;
  my $opt = shift @_;

  my @src = @$array_ptr;

  print STDERR sprintf("\nHelpers::RedisClient::new_multi_exec() for type %s needs to be implemented. For now, returning array.\n",
                        $opt->{'cmd'},
                        $opt->{'array-length'});

  return subArray($array_ptr, $opt);
}


sub stringFromSubArray
{
  my $array_ptr = shift @_;
  my $opt = shift @_;

  my @src = @$array_ptr;

  if ($opt->{'array-length'} != 1 )
    {
      print STDERR sprintf( "\nHelpers::RedisClient::new_multi_exec() for %s is supposed to return a string but it has length %s. Returning array\n",
                            $opt->{'cmd'},
                            $opt->{'array-length'});

      return subArray($array_ptr, $opt);
    }

  my $str = $src[$opt->{'index-start'}];
  return $str;
}

sub hashFromSubArray
{
  my $array_ptr = shift @_;
  my $opt = shift @_;

  my @src = @$array_ptr;
  my $hash_ptr = undef;

  if (Helpers::Misc::is_odd($opt->{'array-length'}))
    {
      print STDERR sprintf( "\nHelpers::RedisClient::new_multi_exec() for %s is supposed to return hash but has an odd number of elements %s. Returning array\n",
                            $opt->{'cmd'},
                            $opt->{'array-length'});

      return subArray($array_ptr, $opt);
    }

  for (my $i = 0; $i < $opt->{'array-length'} ; $i = $i + 2)
    {
      my $key_index = $opt->{'index-start'} + $i;
      my $v_index = $key_index + 1;

      $hash_ptr->{$src[$key_index]} = $src[$v_index];
    }
  return undef if scalar keys %$hash_ptr == 0;
  return $hash_ptr;
}

1;

