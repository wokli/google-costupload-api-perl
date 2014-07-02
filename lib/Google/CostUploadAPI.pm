package Google::CostUploadAPI;

# use 5.014002;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;

use JSON;
use Encode;

our $VERSION = '0.02';

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};

  $self -> {'ua'} = new LWP::UserAgent;
  $self -> {'token'} = $params{'token'} or die __PACKAGE__." constructor failed: access token required!";

  for (qw/data_source account property date dry reset /) {
    $self -> {$_} =  $params{$_} || '';
  }

  $self -> {'error'} = '';
  return bless($self, $class);
}

sub get_error {
  my $self = shift;
  return $self -> {'error'};
}

sub _reset_error {
  my $self = shift;
  $self -> {'error'} = '';
}

sub _create_error {
  my $self = shift;
  my ($msg, $code) = @_;

  $self -> {'error'} = {
    'error' => {
      'message' => $msg  || 'unknown error',
      'code'    => $code || 'unknown code'
    }
  };

  return 1;
}

sub upload {
  my $self    = shift;
  my %args    = @_;

  $self -> _reset_error();

  my $date = $args{'date'} || $self -> {'date'};
  unless ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
    $self -> {'error'} = { 'error' => { 'message' => 'Bad input: date', 'code' => '400'}};
    return undef;
  }

  my $acc_id  = $args{'account'} || $self -> {'account'};
  my $wp_id   = $args{'property'} || $self -> {'property'};
  my $cds_id  = $args{'data_source'} || $self -> {'data_source'};

  my $reset = $args{'reset'} || $self -> {'reset'} ? 'true' : 'false';

  my $append  = $args{'append'} || '1';

  unless ($acc_id && $wp_id && $cds_id) {
    $self -> _create_error("Bad input: missing ". ( $acc_id ? ($wp_id ? "custom_data_source_id" : "webproperty_id") : "account_id"), '400');
    return undef;
  }

  my $content = $args{'bytes'} || '';

  unless ($content) {
    $self -> _create_error("Bad input: missing content", "400");
    return undef;
  }

  # dry run, no actual request
  if ($args{'dry'} || $self -> {'dry'}) {
    return [$acc_id, $wp_id, $cds_id];
  }

  my $r = new HTTP::Request(POST => 'https://www.googleapis.com/upload/analytics/v3/management' .
    '/accounts/' . $acc_id .
    '/webproperties/' . $wp_id .
    '/customDataSources/' . $cds_id . 
    '/dailyUploads/' . $args{'date'}.'/uploads?type=cost&reset='.$reset.'&appendNumber='.$append);

  $r -> header('authorization' => "Bearer ".$self -> {'token'});
  $r -> header('Content-type' => 'application/octet-stream');
  $r -> content(encode_utf8($content));

  my $response = $self -> {'ua'} -> request($r);

  # 200 OK
  if ($response -> is_success) {
    my $decoded_content = eval { decode_json($response -> content) };
    warn $@ if $@;
    return $decoded_content || {};
  }

  # api error
  if ($response -> code eq '400') {
    my $error = eval { decode_json($response -> content) };
    warn $@ if $@;
    $self -> {'error'} =  $error || { 'error' => {'message' => $@, 'code' => '400'}};
    return undef;
  }  

  # neither 200 nor 400, network down, no route - you name it
  $self -> _create_error($response -> status_line, $response -> code);
  return undef;
}

1;
__END__
