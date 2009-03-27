#!/usr/local/bin/perl -w
###########################################################################
# File    - test.pl
#	    Created 12 Feb, 2000, Brent B. Powers
#
# Purpose - test for Memoize::ExpireLRU
#
# ToDo    - Test when tied to other module
#
#
###########################################################################
use strict;
use Memoize;
use Test::More tests => 49;

my $n = 0;
use vars qw($test_debugging);
$test_debugging = 0;
$| = 1;

use Memoize::ExpireLRU;

my %CALLS = ();

sub scalar_sub {
    return $_[0];
}

## 1 gives mutable_return as a list, 0 as a scalar
my $flag  = 1; 

sub mutable_return {
    return $flag ? (1, $_[0]) : ($_[0]);
}

sub routine3 {
    return $_[0];
}
# Basic test.  We set up a front-end cache that can hold 4 items, with a
# mid-cache of 6.

tie my %scalar_46, 
    'Memoize::ExpireLRU', 
    CACHESIZE => 4, 
    TUNECACHESIZE => 6, 
    INSTANCE => 'scalar_sub'; 

memoize('scalar_sub',
	SCALAR_CACHE => ['HASH', \%scalar_46],
	LIST_CACHE => 'FAULT');

# List/scalar test. 1 item front-end, 5-item mid-cache.
tie my %hash_15, 'Memoize::ExpireLRU',
                           CACHESIZE => 1,
                           TUNECACHESIZE => 5,
                           INSTANCE => 'mutable_return';
if ($flag) {
    memoize('mutable_return',
	    LIST_CACHE => ['HASH',\%hash_15],
	    SCALAR_CACHE => 'FAULT',);
} else {
    memoize('mutable_return',
	    SCALAR_CACHE => ['HASH', \%hash_15],
	    LIST_CACHE => 'FAULT');
}

# No mid-cache test. 4-item front-end cache.
tie my %hash_40,  'Memoize::ExpireLRU',
                         CACHESIZE => 4,
                         INSTANCE => 'routine3';
memoize('routine3',
	SCALAR_CACHE => ['HASH', \%hash_40],
	LIST_CACHE => 'FAULT');

$Memoize::ExpireLRU::DEBUG = 1;
$Memoize::ExpireLRU::DEBUG = 0;

## Fill the cache
for (0..3) {
    is scalar_sub($_), $_, "Scalar sub fill with $_ works";
    $CALLS{$_} = $_;
}

## Ensure that the return values were correct
is_deeply [sort values %CALLS], [0, 1, 2, 3], 'right values returned';

## Check returns from the cache
for (0..3) {
  is scalar_sub($_),  $_, 'repeat calls return right values';
}

## Check that cache contents are as expected for front-end and mid-cache.
fail('Need to write these tests');

## Make sure we can get each one of the array
foreach (0,2,0,0) {
    is scalar_sub($_),  $_, 'out-of-order calls work';
}

## Make sure we can get each one of the aray, where the timestamps are
## different
my($i);
for (0..3) {
    sleep(1);
    $i = scalar_sub($_);
    is $i, $_, 'different times still return right cache values';
}

for (0,2,0,0) {
    is scalar_sub($_),  $_, 'out-of-order calls still working';
}

## Check getting a new one
## Set the  most-recently-used order.
for (3,2,1,0) {
    $i = scalar_sub($_);
}

## Validate cache contents.
fail('write this test');

## Push off the last one, and ensure that the
## one we pushed off is really pushed off
for (4, 3) {
    is scalar_sub($_), $_, 'new/old call setup works';
}

## validate cache contents again.
fail('write this one too');

## Play with the second function
## First, fill it
my(@a);
for (5,4,3,2,1,0) {
    if ($flag) {
	is $_, (mutable_return($_))[1], 'second item correct';
    } else {
	is $_,  mutable_return($_), 'return value correct';
    }
}


## Now, hit each of them, in order
## Force at least one cache hit
if ($flag) {
    @a = mutable_return(0);
} else {
    mutable_return(0);
}

for (1..4) {
    if ($flag) {
	ok((mutable_return($_))[1] == $_, 'correct value');
    } else {
	ok($_ == mutable_return($_), 'correct value');
    }
}

# Validate cache contents.
fail 'write this test';

for (0,1,2,3,4,5,5,4,3) {
    ok($_ == routine3($_), 'cache load');
}

## No really, validate.
fail 'no validation in place';

my($q) = <<EOT;
mutable_return:
    Cache Keys:
        '4'
    Test Cache Keys:
        '3'
        '2'
        '1'
        '0'
EOT

is $q, Memoize::ExpireLRU::DumpCache('mutable_return'), 'cache loaded right';

$q = <<EOT;
ExpireLRU Statistics:

                   ExpireLRU instantiation: scalar_sub
                                Cache Size: 4
                   Experimental Cache Size: 6
                                Cache Hits: 20
                              Cache Misses: 6
Additional Cache Hits at Experimental Size: 1
                             Distribution : Hits
                                        0 : 3
                                        1 : 2
                                        2 : 5
                                        3 : 10
                                     ----   -----
                                        4 : 1
                                        5 : 0

                   ExpireLRU instantiation: mutable_return
                                Cache Size: 1
                   Experimental Cache Size: 5
                                Cache Hits: 1
                              Cache Misses: 10
Additional Cache Hits at Experimental Size: 4
                             Distribution : Hits
                                        0 : 1
                                     ----   -----
                                        1 : 1
                                        2 : 1
                                        3 : 1
                                        4 : 1
EOT

is $q, Memoize::ExpireLRU::ShowStats, 'stats right';
