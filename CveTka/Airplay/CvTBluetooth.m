//
//  CvTBluetooth.m
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTBluetooth.h"

@implementation CvTBluetoothServer

-(id)init
{
    self = [super init];
    _Manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:NULL];
    return self;
}

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        OutCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CvTOutCharacteristic_UUID] properties:CBCharacteristicPropertyNotify value:NULL permissions:CBAttributePermissionsReadable];
        InCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CvTInCharacteristic_UUID] properties:CBCharacteristicPropertyNotify value:NULL permissions:CBAttributePermissionsWriteable];
        
        Service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:CvTService_UUID] primary:TRUE];
        [Service setCharacteristics:@[InCharacteristic, OutCharacteristic]];
        
        [_Manager addService:Service];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error == NULL)
    {
        [_Manager startAdvertising:@{ CBAdvertisementDataLocalNameKey : @"CveTka",CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:CvTService_UUID]] }];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    //if ([request.characteristic.UUID isEqual:] )
    
    //request.value = [mycharacteristic.value subdataWithRange:NSMakeRange(request.offset, mycharacteristic.value.length - request.offset)];
    
    [_Manager respondToRequest:request withResult:CBATTErrorSuccess];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    //mycharacteristic.value  =request.valuue;
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
}

//    [_BTManager updateValue:<#(NSData *)#> forCharacteristic:<#(CBMutableCharacteristic *)#> onSubscribedCentrals:<#(NSArray *)#>]

@end


@implementation CvTBluetoothClient

-(id)init
{
    self = [super init];
    _Manager = [[CBCentralManager alloc] initWithDelegate:self queue:NULL];
    return self;
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [_Manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:CvTService_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @TRUE }];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [_Manager stopScan];
    if (Peripheral != peripheral)
    {
        Peripheral = peripheral;
        [_Manager connectPeripheral:Peripheral options:NULL];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [Peripheral setDelegate:self];
    [Peripheral discoverServices:@[[CBUUID UUIDWithString:CvTService_UUID]]];
}

-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        
    }
    
    for (CBService *service in aPeripheral.services)
        if ([service.UUID isEqual:[CBUUID UUIDWithString:CvTService_UUID]])
            [Peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CvTInCharacteristic_UUID], [CBUUID UUIDWithString:CvTOutCharacteristic_UUID]] forService:service];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
}

@end
