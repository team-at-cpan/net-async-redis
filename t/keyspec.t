use strict;
use warnings;

# Set this to generate test cases based on actual Redis responses.
use constant REDIS_COMPARE => $ENV{REDIS_COMPARE} ? 1 : 0;

use Test::More;
use Test::Deep;
use Net::Async::Redis;

our $redis;
if(REDIS_COMPARE) {
    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;
    $loop->add(
        $redis = Net::Async::Redis->new
    );
    $redis->connect->get;
};

my $fh;
if(REDIS_COMPARE) {
    open $fh, '>:encoding(UTF-8)', 'redis-keyspec-tests.txt' or die $!;
}

for my $case (
    [ [ qw{subscribe x y z} ] => [ qw{} ] ],
    [ [ qw{get x} ] => [ qw{x} ] ],
    [ [ qw{mget x y z} ] => [ qw{x y z} ] ],
    [ [ qw{set x y} ] => [ qw{x} ] ],
    [ [ qw{xinfo stream x} ] => [ qw{x} ] ],
    [ [ qw{xadd x nomkstream * a b c d e f} ] => [ qw{x} ] ],
    [ [ qw{EXISTS mykey} ] => [ qw{mykey} ] ],
    [ [ qw{APPEND mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{APPEND mykey}, " World" ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{APPEND ts 0043} ] => [ qw{ts} ] ],
    [ [ qw{APPEND ts 0035} ] => [ qw{ts} ] ],
    [ [ qw{GETRANGE ts 0 3} ] => [ qw{ts} ] ],
    [ [ qw{GETRANGE ts 4 7} ] => [ qw{ts} ] ],
    [ [ qw{SET mykey foobar} ] => [ qw{mykey} ] ],
    [ [ qw{BITCOUNT mykey} ] => [ qw{mykey} ] ],
    [ [ qw{BITCOUNT mykey 0 0} ] => [ qw{mykey} ] ],
    [ [ qw{BITCOUNT mykey 1 1} ] => [ qw{mykey} ] ],
    [ [ qw{BITCOUNT mykey 1 1 BYTE} ] => [ qw{mykey} ] ],
    [ [ qw{BITCOUNT mykey 5 30 BIT} ] => [ qw{mykey} ] ],
    [ [ qw{SET key1 foobar} ] => [ qw{key1} ] ],
    [ [ qw{SET key2 abcdef} ] => [ qw{key2} ] ],
    [ [ qw{BITOP AND dest key1 key2} ] => [ qw{dest key1 key2} ] ],
    [ [ qw{GET dest} ] => [ qw{dest} ] ],
    [ [ qw{SET mykey}, "\xff\xf0\x00" ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 0} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey}, "\x00\xff\xf0" ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 1 0} ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 1 2} ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 1 2 -1 BYTE} ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 1 7 15 BIT} ] => [ qw{mykey} ] ],
    [ [ qw{set mykey}, "\x00\x00\x00" ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 1} ] => [ qw{mykey} ] ],
    [ [ qw{BITPOS mykey 1 7 -3 BIT} ] => [ qw{mykey} ] ],
    [ [ qw{CLIENT ID} ] => [ qw{} ] ],
    [ [ qw{CLIENT INFO} ] => [ qw{} ] ],
    [ [ qw{COMMAND COUNT} ] => [ qw{} ] ],
    [ [ qw{COMMAND DOCS SET} ] => [ qw{} ] ],
    [ [ qw{COMMAND GETKEYS MSET a b c d e f} ] => [ qw{} ] ],
    [ [ qw{COMMAND GETKEYS EVAL}, "not consulted", qw{3 key1 key2 key3 arg1 arg2 arg3 argN} ] => [ qw{} ] ],
    [ [ qw{COMMAND GETKEYSANDFLAGS LMOVE mylist1 mylist2 left left} ] => [ qw{} ] ],
    [ [ qw{COMMAND GETKEYS MSET a b c d e f} ] => [ qw{} ] ],
    [ [ qw{COMMAND GETKEYS EVAL}, "not consulted", qw{3 key1 key2 key3 arg1 arg2 arg3 argN} ] => [ qw{} ] ],
    [ [ qw{COMMAND GETKEYS SORT mylist ALPHA STORE outlist} ] => [ qw{} ] ],
    [ [ qw{COMMAND INFO get set eval} ] => [ qw{} ] ],
    [ [ qw{COMMAND INFO foo evalsha config bar} ] => [ qw{} ] ],
    [ [ qw{SET mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{DECRBY mykey 3} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{DECR mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey 234293482390480948029348230948} ] => [ qw{mykey} ] ],
    [ [ qw{DECR mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET key1 Hello} ] => [ qw{key1} ] ],
    [ [ qw{SET key2 World} ] => [ qw{key2} ] ],
    [ [ qw{DEL key1 key2 key3} ] => [ qw{key1 key2 key3} ] ],
    [ [ qw{ECHO}, "Hello World!" ] => [ qw{} ] ],
    [ [ qw{SET key1 Hello} ] => [ qw{key1} ] ],
    [ [ qw{EXISTS key1} ] => [ qw{key1} ] ],
    [ [ qw{EXISTS nosuchkey} ] => [ qw{nosuchkey} ] ],
    [ [ qw{SET key2 World} ] => [ qw{key2} ] ],
    [ [ qw{EXISTS key1 key2 nosuchkey} ] => [ qw{key1 key2 nosuchkey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{EXISTS mykey} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIREAT mykey 1293840000} ] => [ qw{mykey} ] ],
    [ [ qw{EXISTS mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRE mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey}, "Hello World" ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRE mykey 10 XX} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRE mykey 10 NX} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIREAT mykey 33177117420} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRETIME mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEODIST Sicily Palermo Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEORADIUS Sicily 15 37 100 km} ] => [ qw{Sicily} ] ],
    [ [ qw{GEORADIUS Sicily 15 37 200 km} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEODIST Sicily Palermo Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEODIST Sicily Palermo Catania km} ] => [ qw{Sicily} ] ],
    [ [ qw{GEODIST Sicily Palermo Catania mi} ] => [ qw{Sicily} ] ],
    [ [ qw{GEODIST Sicily Foo Bar} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOHASH Sicily Palermo Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOPOS Sicily Palermo Catania NonExisting} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.583333 37.316667 Agrigento} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEORADIUSBYMEMBER Sicily Agrigento 100 km} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEORADIUS Sicily 15 37 200 km WITHDIST} ] => [ qw{Sicily} ] ],
    [ [ qw{GEORADIUS Sicily 15 37 200 km WITHCOORD} ] => [ qw{Sicily} ] ],
    [ [ qw{GEORADIUS Sicily 15 37 200 km WITHDIST WITHCOORD} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 12.758489 38.788135 edge1 17.241510 38.788135 edge2} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOSEARCH Sicily FROMLONLAT 15 37 BYRADIUS 200 km ASC} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOSEARCH Sicily FROMLONLAT 15 37 BYBOX 400 400 km ASC WITHCOORD WITHDIST} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 13.361389 38.115556 Palermo 15.087269 37.502669 Catania} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOADD Sicily 12.758489 38.788135 edge1 17.241510 38.788135 edge2} ] => [ qw{Sicily} ] ],
    [ [ qw{GEOSEARCHSTORE key1 Sicily FROMLONLAT 15 37 BYBOX 400 400 km ASC COUNT 3} ] => [ qw{key1 Sicily} ] ],
    [ [ qw{GEOSEARCH key1 FROMLONLAT 15 37 BYBOX 400 400 km ASC WITHCOORD WITHDIST WITHHASH} ] => [ qw{key1} ] ],
    [ [ qw{GEOSEARCHSTORE key2 Sicily FROMLONLAT 15 37 BYBOX 400 400 km ASC COUNT 3 STOREDIST} ] => [ qw{key2 Sicily} ] ],
    [ [ qw{ZRANGE key2 0 -1 WITHSCORES} ] => [ qw{key2} ] ],
    [ [ qw{SETBIT mykey 7 1} ] => [ qw{mykey} ] ],
    [ [ qw{GETBIT mykey 0} ] => [ qw{mykey} ] ],
    [ [ qw{GETBIT mykey 7} ] => [ qw{mykey} ] ],
    [ [ qw{GETBIT mykey 100} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{GETDEL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{GETEX mykey} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GETEX mykey EX 60} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GET nonexisting} ] => [ qw{nonexisting} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey}, "This is a string" ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey 0 3} ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey -3 -1} ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey 0 -1} ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey 10 100} ] => [ qw{mykey} ] ],
    [ [ qw{INCR mycounter} ] => [ qw{mycounter} ] ],
    [ [ qw{GETSET mycounter 0} ] => [ qw{mycounter} ] ],
    [ [ qw{GET mycounter} ] => [ qw{mycounter} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{GETSET mykey World} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{HSET myhash field1 "foo"} ] => [ qw{myhash} ] ],
    [ [ qw{HDEL myhash field1} ] => [ qw{myhash} ] ],
    [ [ qw{HDEL myhash field2} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field1 foo} ] => [ qw{myhash} ] ],
    [ [ qw{HEXISTS myhash field1} ] => [ qw{myhash} ] ],
    [ [ qw{HEXISTS myhash field2} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field1 Hello} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field2 World} ] => [ qw{myhash} ] ],
    [ [ qw{HGETALL myhash} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field1 foo} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field1} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field2} ] => [ qw{myhash} ] ],
    [ [ qw{HSET mykey field 10.50} ] => [ qw{mykey} ] ],
    [ [ qw{HINCRBYFLOAT mykey field 0.1} ] => [ qw{mykey} ] ],
    [ [ qw{HINCRBYFLOAT mykey field -5} ] => [ qw{mykey} ] ],
    [ [ qw{HSET mykey field 5.0e3} ] => [ qw{mykey} ] ],
    [ [ qw{HINCRBYFLOAT mykey field 2.0e2} ] => [ qw{mykey} ] ],
    [ [ qw{HSET myhash field 5} ] => [ qw{myhash} ] ],
    [ [ qw{HINCRBY myhash field 1} ] => [ qw{myhash} ] ],
    [ [ qw{HINCRBY myhash field -1} ] => [ qw{myhash} ] ],
    [ [ qw{HINCRBY myhash field -10} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field1 Hello} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field2 World} ] => [ qw{myhash} ] ],
    [ [ qw{HKEYS myhash} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field1 Hello} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field2 World} ] => [ qw{myhash} ] ],
    [ [ qw{HLEN myhash} ] => [ qw{myhash} ] ],
    [ [ qw{HMSET myhash field1 Hello field2 World} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field1} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field2} ] => [ qw{myhash} ] ],
    [ [ qw{HMSET coin heads obverse tails reverse edge null} ] => [ qw{coin} ] ],
    [ [ qw{HRANDFIELD coin} ] => [ qw{coin} ] ],
    [ [ qw{HRANDFIELD coin} ] => [ qw{coin} ] ],
    [ [ qw{HRANDFIELD coin -5 WITHVALUES} ] => [ qw{coin} ] ],
    [ [ qw{HSET myhash field1 Hello} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field1} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field2 Hi field3 World} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field2} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field3} ] => [ qw{myhash} ] ],
    [ [ qw{HGETALL myhash} ] => [ qw{myhash} ] ],
    [ [ qw{HSETNX myhash field Hello} ] => [ qw{myhash} ] ],
    [ [ qw{HSETNX myhash field World} ] => [ qw{myhash} ] ],
    [ [ qw{HGET myhash field} ] => [ qw{myhash} ] ],
    [ [ qw{HMSET myhash f1 HelloWorld f2 99 f3 -256} ] => [ qw{myhash} ] ],
    [ [ qw{HSTRLEN myhash f1} ] => [ qw{myhash} ] ],
    [ [ qw{HSTRLEN myhash f2} ] => [ qw{myhash} ] ],
    [ [ qw{HSTRLEN myhash f3} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field1 Hello} ] => [ qw{myhash} ] ],
    [ [ qw{HSET myhash field2 World} ] => [ qw{myhash} ] ],
    [ [ qw{HVALS myhash} ] => [ qw{myhash} ] ],
    [ [ qw{SET mykey 10.50} ] => [ qw{mykey} ] ],
    [ [ qw{INCRBYFLOAT mykey 0.1} ] => [ qw{mykey} ] ],
    [ [ qw{INCRBYFLOAT mykey -5} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey 5.0e3} ] => [ qw{mykey} ] ],
    [ [ qw{INCRBYFLOAT mykey 2.0e2} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{INCRBY mykey 5} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{INCR mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{MSET firstname Jack lastname Stuntman age 35} ] => [ qw{firstname lastname age} ] ],
    [ [ qw{KEYS *name*} ] => [ qw{} ] ],
    [ [ qw{KEYS a??} ] => [ qw{} ] ],
    [ [ qw{KEYS *} ] => [ qw{} ] ],
    [ [ qw{LPUSH mylist World} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist Hello} ] => [ qw{mylist} ] ],
    [ [ qw{LINDEX mylist 0} ] => [ qw{mylist} ] ],
    [ [ qw{LINDEX mylist -1} ] => [ qw{mylist} ] ],
    [ [ qw{LINDEX mylist 3} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist Hello} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist World} ] => [ qw{mylist} ] ],
    [ [ qw{LINSERT mylist BEFORE World There} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist World} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist Hello} ] => [ qw{mylist} ] ],
    [ [ qw{LLEN mylist} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist one} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist two} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist three} ] => [ qw{mylist} ] ],
    [ [ qw{LMOVE mylist myotherlist RIGHT LEFT} ] => [ qw{mylist myotherlist} ] ],
    [ [ qw{LMOVE mylist myotherlist LEFT RIGHT} ] => [ qw{mylist myotherlist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE myotherlist 0 -1} ] => [ qw{myotherlist} ] ],
    [ [ qw{LMPOP 2 non1 non2 LEFT COUNT 10} ] => [ qw{non1 non2} ] ],
    [ [ qw{LPUSH mylist one two three four five} ] => [ qw{mylist} ] ],
    [ [ qw{LMPOP 1 mylist LEFT} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LMPOP 1 mylist RIGHT COUNT 10} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist one two three four five} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist2 a b c d e} ] => [ qw{mylist2} ] ],
    [ [ qw{LMPOP 2 mylist mylist2 right count 3} ] => [ qw{mylist mylist2} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LMPOP 2 mylist mylist2 right count 5} ] => [ qw{mylist mylist2} ] ],
    [ [ qw{LMPOP 2 mylist mylist2 right count 10} ] => [ qw{mylist mylist2} ] ],
    [ [ qw{EXISTS mylist mylist2} ] => [ qw{mylist mylist2} ] ],
    [ [ qw{RPUSH mylist one two three four five} ] => [ qw{mylist} ] ],
    [ [ qw{LPOP mylist} ] => [ qw{mylist} ] ],
    [ [ qw{LPOP mylist 2} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist a b c d 1 2 3 4 3 3 3} ] => [ qw{mylist} ] ],
    [ [ qw{LPOS mylist 3} ] => [ qw{mylist} ] ],
    [ [ qw{LPOS mylist 3 COUNT 0 RANK 2} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist world} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist hello} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSH mylist World} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSHX mylist Hello} ] => [ qw{mylist} ] ],
    [ [ qw{LPUSHX myotherlist Hello} ] => [ qw{myotherlist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE myotherlist 0 -1} ] => [ qw{myotherlist} ] ],
    [ [ qw{RPUSH mylist one} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist two} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist three} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 0} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist -3 2} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist -100 100} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 5 10} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist hello} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist hello} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist foo} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist hello} ] => [ qw{mylist} ] ],
    [ [ qw{LREM mylist -2 hello} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist one} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist two} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist three} ] => [ qw{mylist} ] ],
    [ [ qw{LSET mylist 0 four} ] => [ qw{mylist} ] ],
    [ [ qw{LSET mylist -2 five} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist one} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist two} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist three} ] => [ qw{mylist} ] ],
    [ [ qw{LTRIM mylist 1 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{SET key1 Hello} ] => [ qw{key1} ] ],
    [ [ qw{SET key2 World} ] => [ qw{key2} ] ],
    [ [ qw{MGET key1 key2 nonexisting} ] => [ qw{key1 key2 nonexisting} ] ],
    [ [ qw{MSET key1 Hello key2 World} ] => [ qw{key1 key2} ] ],
    [ [ qw{GET key1} ] => [ qw{key1} ] ],
    [ [ qw{GET key2} ] => [ qw{key2} ] ],
    [ [ qw{MSETNX key1 Hello key2 there} ] => [ qw{key1 key2} ] ],
    [ [ qw{MSETNX key2 new key3 world} ] => [ qw{key2 key3} ] ],
    [ [ qw{MGET key1 key2 key3} ] => [ qw{key1 key2 key3} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRE mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{PERSIST mykey} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{PEXPIREAT mykey 1555555555005} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{PTTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{PEXPIRE mykey 1500} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{PTTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{PEXPIRE mykey 1000 XX} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{PEXPIRE mykey 1000 NX} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{PEXPIREAT mykey 33177117420000} ] => [ qw{mykey} ] ],
    [ [ qw{PEXPIRETIME mykey} ] => [ qw{mykey} ] ],
    [ [ qw{PFADD hll a b c d e f g} ] => [ qw{hll} ] ],
    [ [ qw{PFCOUNT hll} ] => [ qw{hll} ] ],
    [ [ qw{PFADD hll foo bar zap} ] => [ qw{hll} ] ],
    [ [ qw{PFADD hll zap zap zap} ] => [ qw{hll} ] ],
    [ [ qw{PFADD hll foo bar} ] => [ qw{hll} ] ],
    [ [ qw{PFCOUNT hll} ] => [ qw{hll} ] ],
    [ [ qw{PFADD some-other-hll 1 2 3} ] => [ qw{some-other-hll} ] ],
    [ [ qw{PFCOUNT hll some-other-hll} ] => [ qw{hll some-other-hll} ] ],
    [ [ qw{PFADD hll1 foo bar zap a} ] => [ qw{hll1} ] ],
    [ [ qw{PFADD hll2 a b c foo} ] => [ qw{hll2} ] ],
    [ [ qw{PFMERGE hll3 hll1 hll2} ] => [ qw{hll3 hll1 hll2} ] ],
    [ [ qw{PFCOUNT hll3} ] => [ qw{hll3} ] ],
    [ [ qw{PING} ] => [ qw{} ] ],
    [ [ qw{PING}, "hello world" ] => [ qw{} ] ],
    [ [ qw{PSETEX mykey 1000 Hello} ] => [ qw{mykey} ] ],
    [ [ qw{PTTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRE mykey 1} ] => [ qw{mykey} ] ],
    [ [ qw{PTTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{RENAME mykey myotherkey} ] => [ qw{mykey myotherkey} ] ],
    [ [ qw{GET myotherkey} ] => [ qw{myotherkey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{SET myotherkey World} ] => [ qw{myotherkey} ] ],
    [ [ qw{RENAMENX mykey myotherkey} ] => [ qw{mykey myotherkey} ] ],
    [ [ qw{GET myotherkey} ] => [ qw{myotherkey} ] ],
    [ [ qw{ROLE} ] => [ qw{} ] ],
    [ [ qw{RPUSH mylist one} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist two} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist three} ] => [ qw{mylist} ] ],
    [ [ qw{RPOPLPUSH mylist myotherlist} ] => [ qw{mylist myotherlist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE myotherlist 0 -1} ] => [ qw{myotherlist} ] ],
    [ [ qw{RPUSH mylist one two three four five} ] => [ qw{mylist} ] ],
    [ [ qw{RPOP mylist} ] => [ qw{mylist} ] ],
    [ [ qw{RPOP mylist 2} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist hello} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist world} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSH mylist Hello} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSHX mylist World} ] => [ qw{mylist} ] ],
    [ [ qw{RPUSHX myotherlist World} ] => [ qw{myotherlist} ] ],
    [ [ qw{LRANGE mylist 0 -1} ] => [ qw{mylist} ] ],
    [ [ qw{LRANGE myotherlist 0 -1} ] => [ qw{myotherlist} ] ],
    [ [ qw{SADD myset Hello} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset World} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset World} ] => [ qw{myset} ] ],
    [ [ qw{SMEMBERS myset} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset Hello} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset World} ] => [ qw{myset} ] ],
    [ [ qw{SCARD myset} ] => [ qw{myset} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SDIFF key1 key2} ] => [ qw{key1 key2} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SDIFFSTORE key key1 key2} ] => [ qw{key key1 key2} ] ],
    [ [ qw{SMEMBERS key} ] => [ qw{key} ] ],
    [ [ qw{SETBIT mykey 7 1} ] => [ qw{mykey} ] ],
    [ [ qw{SETBIT mykey 7 0} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SETEX mykey 10 Hello} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET anotherkey}, "will expire in a minute", qw{EX 60} ] => [ qw{anotherkey} ] ],
    [ [ qw{SETNX mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{SETNX mykey World} ] => [ qw{mykey} ] ],
    [ [ qw{GET mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET key1}, "Hello World" ] => [ qw{key1} ] ],
    [ [ qw{SETRANGE key1 6 Redis} ] => [ qw{key1} ] ],
    [ [ qw{GET key1} ] => [ qw{key1} ] ],
    [ [ qw{SETRANGE key2 6 Redis} ] => [ qw{key2} ] ],
    [ [ qw{GET key2} ] => [ qw{key2} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 d} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SINTER key1 key2} ] => [ qw{key1 key2} ] ],
    [ [ qw{SINTERCARD 2 key1 key2} ] => [ qw{key1 key2} ] ],
    [ [ qw{SINTERCARD 2 key1 key2 LIMIT 1} ] => [ qw{key1 key2} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SINTER key1 key2} ] => [ qw{key1 key2} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SINTERSTORE key key1 key2} ] => [ qw{key key1 key2} ] ],
    [ [ qw{SMEMBERS key} ] => [ qw{key} ] ],
    [ [ qw{SADD myset one} ] => [ qw{myset} ] ],
    [ [ qw{SISMEMBER myset one} ] => [ qw{myset} ] ],
    [ [ qw{SISMEMBER myset two} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset Hello} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset World} ] => [ qw{myset} ] ],
    [ [ qw{SMEMBERS myset} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset one} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset one} ] => [ qw{myset} ] ],
    [ [ qw{SMISMEMBER myset one notamember} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset one} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset two} ] => [ qw{myset} ] ],
    [ [ qw{SADD myotherset three} ] => [ qw{myotherset} ] ],
    [ [ qw{SMOVE myset myotherset two} ] => [ qw{myset myotherset} ] ],
    [ [ qw{SMEMBERS myset} ] => [ qw{myset} ] ],
    [ [ qw{SMEMBERS myotherset} ] => [ qw{myotherset} ] ],
    [ [ qw{SADD myset one} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset two} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset three} ] => [ qw{myset} ] ],
    [ [ qw{SPOP myset} ] => [ qw{myset} ] ],
    [ [ qw{SMEMBERS myset} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset four} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset five} ] => [ qw{myset} ] ],
    [ [ qw{SPOP myset 3} ] => [ qw{myset} ] ],
    [ [ qw{SMEMBERS myset} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset one two three} ] => [ qw{myset} ] ],
    [ [ qw{SRANDMEMBER myset} ] => [ qw{myset} ] ],
    [ [ qw{SRANDMEMBER myset 2} ] => [ qw{myset} ] ],
    [ [ qw{SRANDMEMBER myset -5} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset one} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset two} ] => [ qw{myset} ] ],
    [ [ qw{SADD myset three} ] => [ qw{myset} ] ],
    [ [ qw{SREM myset one} ] => [ qw{myset} ] ],
    [ [ qw{SREM myset four} ] => [ qw{myset} ] ],
    [ [ qw{SMEMBERS myset} ] => [ qw{myset} ] ],
    [ [ qw{SET mykey}, "Hello world" ] => [ qw{mykey} ] ],
    [ [ qw{STRLEN mykey} ] => [ qw{mykey} ] ],
    [ [ qw{STRLEN nonexisting} ] => [ qw{nonexisting} ] ],
    [ [ qw{SET mykey}, "This is a string" ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey 0 3} ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey -3 -1} ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey 0 -1} ] => [ qw{mykey} ] ],
    [ [ qw{GETRANGE mykey 10 100} ] => [ qw{mykey} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SUNION key1 key2} ] => [ qw{key1 key2} ] ],
    [ [ qw{SADD key1 a} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 b} ] => [ qw{key1} ] ],
    [ [ qw{SADD key1 c} ] => [ qw{key1} ] ],
    [ [ qw{SADD key2 c} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 d} ] => [ qw{key2} ] ],
    [ [ qw{SADD key2 e} ] => [ qw{key2} ] ],
    [ [ qw{SUNIONSTORE key key1 key2} ] => [ qw{key key1 key2} ] ],
    [ [ qw{SMEMBERS key} ] => [ qw{key} ] ],
    [ [ qw{TIME} ] => [ qw{} ] ],
    [ [ qw{TIME} ] => [ qw{} ] ],
    [ [ qw{SET key1 Hello} ] => [ qw{key1} ] ],
    [ [ qw{SET key2 World} ] => [ qw{key2} ] ],
    [ [ qw{TOUCH key1 key2} ] => [ qw{key1 key2} ] ],
    [ [ qw{SET mykey Hello} ] => [ qw{mykey} ] ],
    [ [ qw{EXPIRE mykey 10} ] => [ qw{mykey} ] ],
    [ [ qw{TTL mykey} ] => [ qw{mykey} ] ],
    [ [ qw{SET key1 value} ] => [ qw{key1} ] ],
    [ [ qw{LPUSH key2 value} ] => [ qw{key2} ] ],
    [ [ qw{SADD key3 value} ] => [ qw{key3} ] ],
    [ [ qw{TYPE key1} ] => [ qw{key1} ] ],
    [ [ qw{TYPE key2} ] => [ qw{key2} ] ],
    [ [ qw{TYPE key3} ] => [ qw{key3} ] ],
    [ [ qw{SET key1 Hello} ] => [ qw{key1} ] ],
    [ [ qw{SET key2 World} ] => [ qw{key2} ] ],
    [ [ qw{UNLINK key1 key2 key3} ] => [ qw{key1 key2 key3} ] ],
    [ [ qw{XADD mystream * name Sara surname OConnor} ] => [ qw{mystream} ] ],
    [ [ qw{XADD mystream * field1 value1 field2 value2 field3 value3} ] => [ qw{mystream} ] ],
    [ [ qw{XLEN mystream} ] => [ qw{mystream} ] ],
    [ [ qw{XRANGE mystream - +} ] => [ qw{mystream} ] ],
    [ [ qw{XADD mystream * item 1} ] => [ qw{mystream} ] ],
    [ [ qw{XADD mystream * item 2} ] => [ qw{mystream} ] ],
    [ [ qw{XADD mystream * item 3} ] => [ qw{mystream} ] ],
    [ [ qw{XLEN mystream} ] => [ qw{mystream} ] ],
    [ [ qw{XADD writers * name Virginia surname Woolf} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Jane surname Austen} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Toni surname Morrison} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Agatha surname Christie} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Ngozi surname Adichie} ] => [ qw{writers} ] ],
    [ [ qw{XLEN writers} ] => [ qw{writers} ] ],
    [ [ qw{XRANGE writers - + COUNT 2} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Virginia surname Woolf} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Jane surname Austen} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Toni surname Morrison} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Agatha surname Christie} ] => [ qw{writers} ] ],
    [ [ qw{XADD writers * name Ngozi surname Adichie} ] => [ qw{writers} ] ],
    [ [ qw{XLEN writers} ] => [ qw{writers} ] ],
    [ [ qw{XREVRANGE writers + - COUNT 1} ] => [ qw{writers} ] ],
    [ [ qw{XADD mystream * field1 A field2 B field3 C field4 D} ] => [ qw{mystream} ] ],
    [ [ qw{XTRIM mystream MAXLEN 2} ] => [ qw{mystream} ] ],
    [ [ qw{XRANGE mystream - +} ] => [ qw{mystream} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 uno} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZCARD myzset} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZCOUNT myzset -inf +inf} ] => [ qw{myzset} ] ],
    [ [ qw{ZCOUNT myzset (1 3)} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 3 three} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZDIFF 2 zset1 zset2} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZDIFF 2 zset1 zset2 WITHSCORES} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 3 three} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZDIFFSTORE out 2 zset1 zset2} ] => [ qw{out zset1 zset2} ] ],
    [ [ qw{ZRANGE out 0 -1 WITHSCORES} ] => [ qw{out} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZINCRBY myzset 2 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 3 three} ] => [ qw{zset2} ] ],
    [ [ qw{ZINTER 2 zset1 zset2} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZINTERCARD 2 zset1 zset2} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZINTERCARD 2 zset1 zset2 LIMIT 1} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 3 three} ] => [ qw{zset2} ] ],
    [ [ qw{ZINTER 2 zset1 zset2} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZINTER 2 zset1 zset2 WITHSCORES} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 3 three} ] => [ qw{zset2} ] ],
    [ [ qw{ZINTERSTORE out 2 zset1 zset2 WEIGHTS 2 3} ] => [ qw{out zset1 zset2} ] ],
    [ [ qw{ZRANGE out 0 -1 WITHSCORES} ] => [ qw{out} ] ],
    [ [ qw{ZADD myzset 0 a 0 b 0 c 0 d 0 e} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 0 f 0 g} ] => [ qw{myzset} ] ],
    [ [ qw{ZLEXCOUNT myzset - +} ] => [ qw{myzset} ] ],
    [ [ qw{ZLEXCOUNT myzset [b [f} ] => [ qw{myzset} ] ],
    [ [ qw{ZMPOP 1 notsuchkey MIN} ] => [ qw{notsuchkey} ] ],
    [ [ qw{ZADD myzset 1 one 2 two 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZMPOP 1 myzset MIN} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZMPOP 1 myzset MAX COUNT 10} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset2 4 four 5 five 6 six} ] => [ qw{myzset2} ] ],
    [ [ qw{ZMPOP 2 myzset myzset2 MIN COUNT 10} ] => [ qw{myzset myzset2} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZMPOP 2 myzset myzset2 MAX COUNT 10} ] => [ qw{myzset myzset2} ] ],
    [ [ qw{ZRANGE myzset2 0 -1 WITHSCORES} ] => [ qw{myzset2} ] ],
    [ [ qw{EXISTS myzset myzset2} ] => [ qw{myzset myzset2} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZMSCORE myzset one two nofield} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZPOPMAX myzset} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZPOPMIN myzset} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD dadi 1 uno 2 due 3 tre 4 quattro 5 cinque 6 sei} ] => [ qw{dadi} ] ],
    [ [ qw{ZRANDMEMBER dadi} ] => [ qw{dadi} ] ],
    [ [ qw{ZRANDMEMBER dadi} ] => [ qw{dadi} ] ],
    [ [ qw{ZRANDMEMBER dadi -5 WITHSCORES} ] => [ qw{dadi} ] ],
    [ [ qw{ZADD myzset 0 a 0 b 0 c 0 d 0 e 0 f 0 g} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYLEX myzset - [c} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYLEX myzset - (c} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYLEX myzset [aaa (g} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYSCORE myzset -inf +inf} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYSCORE myzset 1 2} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYSCORE myzset (1 2} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGEBYSCORE myzset (1 (2} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one 2 two 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 2 3} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset -2 -1} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one 2 two 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one 2 two 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset (1 +inf BYSCORE LIMIT 1 1} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD srczset 1 one 2 two 3 three 4 four} ] => [ qw{srczset} ] ],
    [ [ qw{ZRANGESTORE dstzset srczset 2 -1} ] => [ qw{dstzset srczset} ] ],
    [ [ qw{ZRANGE dstzset 0 -1} ] => [ qw{dstzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANK myzset three} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANK myzset four} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANK myzset three WITHSCORE} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANK myzset four WITHSCORE} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZREM myzset two} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 0 aaaa 0 b 0 c 0 d 0 e} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 0 foo 0 zap 0 zip 0 ALPHA 0 alpha} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1} ] => [ qw{myzset} ] ],
    [ [ qw{ZREMRANGEBYLEX myzset [alpha [omega} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZREMRANGEBYRANK myzset 0 1} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZREMRANGEBYSCORE myzset -inf (2} ] => [ qw{myzset} ] ],
    [ [ qw{ZRANGE myzset 0 -1 WITHSCORES} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 0 a 0 b 0 c 0 d 0 e 0 f 0 g} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYLEX myzset [c -} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYLEX myzset (c -} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYLEX myzset (g [aaa} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYSCORE myzset +inf -inf} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYSCORE myzset 2 1} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYSCORE myzset 2 (1} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGEBYSCORE myzset (2 (1} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGE myzset 0 -1} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGE myzset 2 3} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANGE myzset -2 -1} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 2 two} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 3 three} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANK myzset one} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANK myzset four} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANK myzset three WITHSCORE} ] => [ qw{myzset} ] ],
    [ [ qw{ZREVRANK myzset four WITHSCORE} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD myzset 1 one} ] => [ qw{myzset} ] ],
    [ [ qw{ZSCORE myzset one} ] => [ qw{myzset} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 3 three} ] => [ qw{zset2} ] ],
    [ [ qw{ZUNION 2 zset1 zset2} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZUNION 2 zset1 zset2 WITHSCORES} ] => [ qw{zset1 zset2} ] ],
    [ [ qw{ZADD zset1 1 one} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset1 2 two} ] => [ qw{zset1} ] ],
    [ [ qw{ZADD zset2 1 one} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 2 two} ] => [ qw{zset2} ] ],
    [ [ qw{ZADD zset2 3 three} ] => [ qw{zset2} ] ],
    [ [ qw{ZUNIONSTORE out 2 zset1 zset2 WEIGHTS 2 3} ] => [ qw{out zset1 zset2} ] ],
    [ [ qw{ZRANGE out 0 -1 WITHSCORES} ] => [ qw{out} ] ],
) {
    my $keys = REDIS_COMPARE ? (eval { $redis->command_getkeys($case->[0]->@*)->get } // []) : $case->[1];
    $fh->print("    [ [ qw{@{$case->[0]}} ] => [ qw{@{$keys}} ] ],\n") if REDIS_COMPARE;
    cmp_deeply(
        [ Net::Async::Redis->extract_keys_for_command($case->[0]) ],
        bag($keys->@*),
        'keyspec for ' . join(' ', $case->[0]->@*)
    ) or note explain +{ case => $case->[0], keys => $keys };
}

done_testing;

