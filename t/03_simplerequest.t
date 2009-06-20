#!perl

use Test::NoWarnings;
use Test::More tests => 47 + 1;

use lib qw(t/);
use testlib;

diag(<<NOTE
##############################################################################
# ATTENTION!                                                                 #
# The following tests require a connection to the UPS online tracking        #
# webservices. If these tests fail due to HTTP errors it is not this modules #
# fault.                                                                     #
##############################################################################
NOTE
);

my $response = testrequest(
    TrackingNumber    => '1Z12345E0291980793',
    CustomerContext   => 'TESTCONTEXT',
);

isa_ok($response,'Business::UPS::Tracking::Response');
isa_ok($response->shipment,'ARRAY');
isa_ok($response->request,'Business::UPS::Tracking::Request');
is($response->CustomerContext,'TESTCONTEXT','Customer context is ok');
my $shipment = $response->shipment->[0];
isa_ok($shipment,'Business::UPS::Tracking::Shipment::SmallPackage');

is($shipment->ShipperNumber,'12345E','ShipperNumber is ok');
isa_ok($shipment->ShipToAddress,'Business::UPS::Tracking::Element::Address');
is($shipment->ShipToAddress->AddressLine1,'SAMPLE CONSIGNEE','Shipper address line 1 is ok');
is($shipment->ShipToAddress->AddressLine2,'1307 PEACHTREE STREET','Shipper address line 2 is ok');
is($shipment->ShipToAddress->AddressLine3,undef,'Shipper address line 2 is ok');
is($shipment->ShipToAddress->City,'ANYTOWN','Shipper city is ok');
is($shipment->ShipToAddress->StateProvinceCode,'GA','Shipper address province is ok');
is($shipment->ShipToAddress->CountryCode,'US','Shipper address country code is ok');
is($shipment->ServiceCode,'002','Service code is ok');
is($shipment->ServiceDescription,'2ND DAY AIR','Service description is ok');
is($shipment->ShipmentReferenceNumber,'LINE4AND115','Reference number print is ok');
isa_ok($shipment->ShipmentReferenceNumber,'Business::UPS::Tracking::Element::ReferenceNumber');
is($shipment->ShipmentReferenceNumber->Value,'LINE4AND115','Reference number is ok');
is($shipment->ShipmentReferenceNumber->Code,'01','Reference number is ok');
is($shipment->ShipmentReferenceNumber->Description,'Unspecified','Reference number is ok');
is($shipment->ShipmentIdentificationNumber,'1Z12345E0291980793','Shipment identification number is ok');
isa_ok($shipment->PickupDate,'DateTime');
is($shipment->PickupDate->ymd('.'),'1999.06.08','PickupDate is ok');
is($shipment->TrackingNumber,'1Z12345E0291980793','Tracking number is ok');
isa_ok($shipment->PackageWeight,'Business::UPS::Tracking::Element::Weight');
is($shipment->PackageWeight->UnitOfMeasurementCode,'LBS','Package weight unit is ok');
is($shipment->PackageWeight->Weight,'5.00','Package weight is ok');
is($shipment->PackageWeight,'5.00 LBS','Package weight print is ok');
isa_ok($shipment->ReferenceNumber,'ARRAY');
my $reference1 = $shipment->ReferenceNumber->[0];
my $reference2 = $shipment->ReferenceNumber->[1];
isa_ok($reference1,'Business::UPS::Tracking::Element::ReferenceNumber');
isa_ok($reference2,'Business::UPS::Tracking::Element::ReferenceNumber');
is($reference1,'LINE4AND115','Reference number 1 print is ok');
is($reference2->Code,'08','Reference number 2 code is ok');
is($reference2->Value,'LJ67Y5','Reference number 2 value is ok');
isa_ok($shipment->Activity,'ARRAY');
my $activity1 = $shipment->Activity->[0];
my $activity2 = $shipment->Activity->[1];
isa_ok($activity1,'Business::UPS::Tracking::Element::Activity');
isa_ok($activity2,'Business::UPS::Tracking::Element::Activity');
isa_ok($activity1->ActivityLocationAddress,'Business::UPS::Tracking::Element::Address');
is($activity1->ActivityLocationAddress->City,'ANYTOWN','Activity 1 location city is ok');
is($activity1->ActivityLocationCode,'ML','Activity 1 location code is ok');
is($activity1->ActivityLocationDescription,'BACK DOOR','Activity 1 location description is ok');
is($activity1->SignedForByName,'HELEN SMITH','Activity 1 location signed for is ok');
is($activity1->StatusTypeCode,'D','Activity 1 status type code is ok');
is($activity1->StatusTypeDescription,'DELIVERED','Activity 1 status type description is ok');
is($activity1->StatusCode,'KM','Activity 1 status code description is ok');
isa_ok($activity1->DateTime,'DateTime');
is($activity1->DateTime->format_cldr('yyyy.MM.dd HH:mm:ss'),'1999.06.10 12:00:00','Activity 1 datetime is ok');