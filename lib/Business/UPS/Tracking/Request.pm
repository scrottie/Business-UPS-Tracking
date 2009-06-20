# ================================================================
package Business::UPS::Tracking::Request;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use DateTime;
use XML::LibXML;
use Moose::Util::TypeConstraints;

use Business::UPS::Tracking::Utils;
use Business::UPS::Tracking::Response;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Request - A UPS tracking request

=head1 SYNOPSIS

  my $request = Business::UPS::Tracking::Request->new(
    tracking        => $tracking_object,
    ReferenceNumber => 'myreferencenumber',
  );
  $request->DestinationPostalCode('1020');
  my $response = $request->run();
  
  OR
  
  my $response = $tracking_object->request(
    ReferenceNumber       => 'myreferencenumber',
    DestinationPostalCode => '1020',
  );
  
=head1 DESCRIPTION

This class represents a UPS tracking request. You can search either for a
UPS TrackingNumber or for a custom ReferenceNumber. Since ReferenceNumbers are
not guaranteed to be unique you can provide additional parameters to narrow
the ReferenceNumber search. 

You have to provide either a ReferenceNumber or a TrackingNumber.

=head1 ACCESSORS

=head2 tracking

L<Business::UPS::Tracking> object.

=head2 TrackingNumber

Unique UPS tracking number.

=head2 ReferenceNumber

Custom reference number.

=head2 ShipperNumber

Shipper customer number. Only in combination with L<ReferenceNumber>.

=head2 DestinationPostalCode

Shipment destination postal code. Only in combination with L<ReferenceNumber>.

=head2 DestinationCountryCountry

Shipment destination country (<>ISO 3166-1 alpha-2)s. Only in combination 
with L<ReferenceNumber>.

=head2 OriginPostalCode

Shipment origin postal code. Only in combination with L<ReferenceNumber>.

=head2 OriginCountryCode

Shipment origin country (ISO 3166-1 alpha-2). Only in combination 
with L<ReferenceNumber>.

=head2 ShipmentIdentificationNumber

Shipment identification number. Only in combination with L<ReferenceNumber>.

=head2 PickupDateRangeBegin

Shipment pickup range. Either a string formated 'YYYYMMDD' or a L<DateTime>
object. Only in combination with L<ReferenceNumber>.

=head2 PickupDateRangeEnd

Shipment pickup range. Either a string formated 'YYYYMMDD' or a L<DateTime>
object. Only in combination with L<ReferenceNumber>.

=head2 ShmipmentType

Type of shipment. '01' small packackage or '02' freight. Only in combination 
with L<ReferenceNumber>.

=head2 CustomerContext

Arbitraty string that will be echoed back by UPS webservice.

=head2 IncludeFreight

Indicates whether the search should only include freight or small package 
only. The default is small package only.

=cut

has 'tracking' => (
    is       => 'rw',
    required => 1,
    isa      => 'Business::UPS::Tracking',
);
has 'TrackingNumber' => (
    is  => 'rw',
    isa => 'TrackingNumber'
);
has 'ReferenceNumber' => (
    is  => 'rw',
    isa => 'Str'
);
has 'ShipperNumber' => (
    is  => 'rw',
    isa => 'Str'
);
has 'DestinationPostalCode' => (
    is  => 'rw',
    isa => 'Str'
);
has 'DestinationCountryCode' => (
    is  => 'rw',
    isa => 'CountryCode'
);
has 'OriginPostalCode' => (
    is  => 'rw',
    isa => 'Str'
);
has 'OriginCountryCode' => (
    is  => 'rw',
    isa => 'CountryCode'
);
has 'CustomerContext' => (
    is  => 'rw',
    isa => 'Str'
);
has 'ShipmentIdentificationNumber' => (
    is  => 'rw',
    isa => 'Str'
);
has 'PickupDateRangeBegin' => (
    is     => 'rw',
    isa    => 'DateStr',
    coerce => 1,
);
has 'PickupDateRangeEnd' => (
    is     => 'rw',
    isa    => 'DateStr',
    coerce => 1,
);
has 'ShmipmentType' => (
    is      => 'rw',
    isa     => enum( [ '01', '02' ] ),
    default => '01',
);
has 'IncludeFreight' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head1 METHODS

=head2 tracking_request

 my $xmlrequest = $request->tracking_request;

Generates the xml request body.

=cut

sub tracking_request {
    my ($self) = @_;

    my $dom           = XML::LibXML::Document->new('1.0');
    my $track_request = $dom->createElement('TrackRequest');
    my $request       = $track_request->addNewChild( '', 'Request' );
    $request->addNewChild( '', 'RequestAction' )->appendTextNode('Track');
    $request->addNewChild( '', 'RequestOption' )->appendTextNode('activity');

    # Tracking number search
    if ( $self->TrackingNumber ) {
        $track_request->addNewChild( '', 'TrackingNumber' )
            ->appendTextNode( $self->TrackingNumber );
    }
    # Shipment identification number search
    elsif ( $self->ShipmentIdentificationNumber ) {
        $track_request->addNewChild( '', 'ShipmentIdentificationNumber' )
            ->appendTextNode( $self->ShipmentIdentificationNumber );
    }
    # Reference number search
    elsif ( $self->ReferenceNumber ) {
        $track_request->addNewChild( '', 'ReferenceNumber' )
            ->addNewChild( '', 'Value' )
            ->appendTextNode( $self->ReferenceNumber );

        foreach my $key (
            qw(ShipperNumber DestinationPostalCode DestinationCountryCode OriginPostalCode OriginCountryCode)
            )
        {
            if ( my $value = $self->$key ) {
                $track_request->addNewChild( '', $key )
                    ->appendTextNode($value);
            }
        }

        if ( $self->PickupDateRangeBegin && $self->PickupDateRangeEnd ) {
            my $range = $track_request->addNewChild( '', 'PickupDateRange' );
            $range->addNewChild( '', 'BeginDate' )
                ->appendTextNode( $self->PickupDateRangeBegin );
            $range->addNewChild( '', 'EndDate' )
                ->appendTextNode( $self->PickupDateRangeEnd );
        }

        if ( $self->ShmipmentType ) {
            my $shipmenttype
                = $track_request->addNewChild( '', 'ShipmentType' );
            $shipmenttype->addNewChild( '', 'Code' )
                ->appendTextNode( $self->ShmipmentType );
        }
    }
    else {
        Business::UPS::Tracking::X->throw(
            "Please provide either 'TrackingNumber','ShipmentIdentificationNumber' or 'ReferenceNumber'"
        );
    }

    # Small package only or small package and freight
    if ( $self->IncludeFreight ) {
        $track_request->addNewChild( '', 'IncludeFreight' )
            ->appendTextNode('01');
    }

    # Customer context
    if ( $self->CustomerContext ) {
        $request->addNewChild( '', 'TransactionReference' )
            ->addNewChild( '', 'CustomerContext' )
            ->appendTextNode( $self->CustomerContext );
    }

    $dom->setDocumentElement($track_request);
    return $dom->toString();
}

=head2 run

 my $response = $request->run;

Executes the request and returns either an exception or a 
L<Business::UPS::Tracking::Response> object.

=cut

sub run {
    my ($self) = @_;

    my $tracking = $self->tracking;

    # Get request string
    my $content = $tracking->access_request . "\n" . $self->tracking_request;

    my $count = 0;
    while (1) {
        # HTTP request
        my $response = $tracking->_ua->post(
            $tracking->url,
            Content_Type => 'text/xml',
            Content      => $content,
        );
        # Success
        if ( $response->is_success ) {
            return Business::UPS::Tracking::Response->new(
                request => $self,
                xml     => $response->content,
            );
        }
        # Failed but try again
        elsif ( $count < $tracking->retry_http ) {
            $count++;
            sleep 1;
            next;
        }
        # Failed and stop trying
        else {
            Business::UPS::Tracking::X::HTTP->throw(
                error         => $response->status_line,
                http_response => $response,
                request       => $self
            );
        }
    }
    return;
}

=head1 METHODS

=head2 meta

Moose meta method

=cut

__PACKAGE__->meta->make_immutable;

1;