package RT::Action::NotifySMSgw;

use base qw(RT::Action::NotifySMS);

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Headers;
use MIME::Base64;

use JSON qw(decode_json);

=head2 NotifySMSgw

Send a message using the SMS gw api
=cut

sub SendMessage {
    my $self = shift;
    my %args = (
        Recipients => undef,
        Msg        => undef,
        @_
    );

    foreach my $config (
        qw /SMSgwAccount SMSgwPaswd SMSgwAPIURL /)
    {
        return ( 0, 'Need to set ' . $config . ' in RT_SiteConfig.pm' )
            unless RT::Config->Get($config);
    }

    return ( 0, 'Please provide a message to send' ) unless $args{Msg};
    return ( 0, 'Please provide a recipient' )
        unless scalar $args{Recipients};

	my $url = RT::Config->Get('SMSgwAPIURL');
	my $Gateway_Username = RT::Config->Get('SMSgwAccount');
	my $Gateway_Password = RT::Config->Get('SMSgwPaswd');
	
	my $SMS_XML = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'.
			' xmlns:pos="poseidonService.xsd">'.
			'<soapenv:Header/>'.
			'<soapenv:Body>'.
			'<pos:QueueAdd>'.
			'<Queue>GsmOut</Queue>'.
			'<Gsm>'.
			'       <Cmd>SMS</Cmd>'.
			'       <Nmr>%s</Nmr>'.
			'       <Text>%s</Text>'.
			'</Gsm>'.
			'</pos:QueueAdd>'.
			'</soapenv:Body>'.
			'</soapenv:Envelope>';	

    my $ua = LWP::UserAgent->new;

	my $authorization_header = sprintf("Basic %s", 
				encode_base64($Gateway_Username . ":" . $Gateway_Password));
#RT::Logger->debug("SMS notification to ". Data::Dumper->Dump($args{Recipients}));

    foreach my $phone_number ( $args{Recipients} ) {
#RT::Logger->debug("SMS notification to ". $$phone_number[0], ref($phone_number));
		my ($data, $queue_id);
		my $xml = sprintf($SMS_XML, $$phone_number[0],  $args{Msg});
		$ua->agent("sendSMSgwalert/1.0 " . $ua->agent);
		# set timeout for sms gw connection
		$ua->timeout (3);
		my $request = new HTTP::Request (POST => $url);
		$request->content($xml);
		$request->header('Authorisation' => $authorization_header);
		$request->header('Content-Length' => length($xml));
		my $response = $ua->request($request);
		
		if (! $response->is_success()) {
				RT::Logger->error("SMS notification failed, got " . $response->status_line());
				return -1;
				}
		$data = $response->content();
		if ($data =~ m/<ID>(\d+)<\/ID>/) {
				$queue_id = "$1";
		} else {
				$queue_id = 'UNKNOWN';
		}
		RT::Logger->debug(sprintf("SMS Message sent with ID %s to '%s'\n", $queue_id, $phone_number));
		# sleep for 1 sec, not to overflood gateway
		sleep 2;
		
    }

    return ( 1, 'Message(s) sent' );
}

1;
