use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;

use JSON;
use Test::More tests => 25;

use Data::Dumper;

use constant C_TEST_DATA => "ga:medium,ga:source,ga:adCost,ga:adClicks,ga:impressions,ga:campaign,ga:adContent\ncpc,bing,0,0,0,test1,test1\n";

BEGIN { use_ok('Google::CostUploadAPI') };

sub _get_access_token {
  my $refresh_token = shift;

  my $client_id = $ENV{GOOGLE_COST_UPLOAD_CLIENT_ID};
  my $client_secret = $ENV{GOOGLE_COST_UPLOAD_CLIENT_SECRET}; 

  return undef unless ($client_id && $client_secret);

  my $ua = new LWP::UserAgent;
  my $r = new HTTP::Request(POST => 'https://accounts.google.com/o/oauth2/token', 
    ['Content-Type', 'application/x-www-form-urlencoded'],
    "client_id=".$client_id."&client_secret=".$client_secret."&refresh_token=".$refresh_token."&grant_type=refresh_token"
    );
  my $response = $ua -> request($r);

  unless ($response -> is_success) { warn "Failed to fetch access token: ".$response -> status_line; return undef; }
  my $decoded = eval { decode_json($response -> content) };

  return $decoded -> {'access_token'} if $decoded;
  return undef;
}

my $access_token = 'dummy_token';
ok (my $api = new Google::CostUploadAPI(token => $access_token), 'constructor test');

my $res = '';

$res = $api -> upload(dry => 1);
is($res, undef);
is($api -> get_error() -> {'error'} -> {'code'}, '400');
like($api -> get_error() -> {'error'} -> {'message'}, qr/date$/);

$res = $api -> upload(dry => 1, date => '2014-04-17');
is($res, undef);
is($api -> get_error() -> {'error'} -> {'code'}, '400');
like($api -> get_error() -> {'error'} -> {'message'}, qr/account_id$/);

$res = $api -> upload(dry => 1, date => '2014-04-17', account => 'dummy');
is($res, undef);
is($api -> get_error() -> {'error'} -> {'code'}, '400');
like($api -> get_error() -> {'error'} -> {'message'}, qr/webproperty_id$/);

$res = $api -> upload(dry => 1, date => '2014-04-17', account => 'dummy', property => 'dummy');
is($res, undef);
is($api -> get_error() -> {'error'} -> {'code'}, '400');
like($api -> get_error() -> {'error'} -> {'message'}, qr/source_id$/);

$res = $api -> upload(dry => 1, date => '2014-04-17', account => 'dummy', property => 'dummy', data_source => 'dummy');
is($res, undef);
is($api -> get_error() -> {'error'} -> {'code'}, '400');
like($api -> get_error() -> {'error'} -> {'message'}, qr/content$/);

$res = $api -> upload(dry => 1, date => '2014-04-17', account => 'dummy_acc', property => 'dummy_prop', data_source => 'dummy_src', bytes => 'Content');
is($api -> get_error(), '');
is_deeply($res, ['dummy_acc', 'dummy_prop', 'dummy_src']);


$api = new Google::CostUploadAPI(token => $access_token, account => 'dummy_acc', property => 'dummy_prop');

$res = $api -> upload(dry => 1, date => '2014-04-17', data_source => 'dummy_src', bytes => 'Content');
is($api -> get_error(), '');
is_deeply($res, ['dummy_acc', 'dummy_prop', 'dummy_src']);

$res = $api -> upload(dry => 1, date => '2014-04-17', bytes => 'Content');
is($res, undef);
is($api -> get_error() -> {'error'} -> {'code'}, '400');
like($api -> get_error() -> {'error'} -> {'message'}, qr/source_id$/);


my $refresh_token = $ENV{GOOGLE_REFRESH_TOKEN};
my $src  = $ENV{GOOGLE_COST_UPLOAD_DS};
my $prop = $ENV{GOOGLE_COST_UPLOAD_WP};
my $acc =  $ENV{GOOGLE_COST_UPLOAD_ACC};


SKIP: {
  my $tests_to_skip = 1;
  skip "no token in ENV", $tests_to_skip unless $refresh_token;
  skip "no upload data in ENV", $tests_to_skip unless ($src && $prop && $acc);

  $access_token = _get_access_token($refresh_token);
  skip "failed to fetch access token", $tests_to_skip unless $access_token;

  my $api = new Google::CostUploadAPI(token => $access_token, reset => '1');
  my $res = $api -> upload(date => '2014-04-17', data_source => $src, property => $prop, account => $acc , bytes => C_TEST_DATA);
  diag $api -> get_error() -> {'error'} -> {'message'} unless ($res);
  is($res -> {'accountId'}, $acc);
}