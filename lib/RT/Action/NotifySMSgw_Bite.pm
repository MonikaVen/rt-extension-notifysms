package RT::Action::NotifySMSgw_Bite;

use base qw(RT::Action::NotifySMS);

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Headers;
use MIME::Base64;
use JSON qw(decode_json);

use URI;
use Data::Dumper;
use JSON;
use HTTP::Tiny;

=head2 NotifySMSgw_Bite

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
    #RT::Logger->error(sprintf($args{Msg}));
    foreach my $phone_number ( $args{Recipients} ) {
                my $pn = $$phone_number[0];
                substr($pn, 0, 1) = "";
                my $json = encode_json {
                        src => 'BITERTIR',
                        dst => $pn,
                        messageText => $args{Msg},
                        dataCoding => 'latin1',
                        registered => 1
                };
                RT::Logger->error($json);
                my ($data, $queue_id);
                my $http = HTTP::Tiny->new();
                my $response = $http->post( $url => {
                        content => $json,
                        headers => { 'Cache-Control' => 'no-cache', 'Content-T$
                } );
                if ($response->{'status'} != 200) {
                                RT::Logger->error("SMS notification failed, go$
                                return -1;
                                }
                RT::Logger->error("SMS message is sent to: +" . $pn);
                RT::Logger->debug(sprintf("SMS Message sent."));
                # sleep for 1 sec, not to overflood gateway
                sleep 2;
    }
    return ( 1, 'Message(s) sent' );
}

1;
