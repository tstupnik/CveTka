//
//  CvTBluetooth.h
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

#define CvTService_UUID                 @"8D2C983F-588A-424E-9E89-9CEFFFED246E"
#define CvTInCharacteristic_UUID        @"1FB46421-61EF-4A88-9137-E6F08439DEB5"
#define CvTOutCharacteristic_UUID       @"F4EF31DE-88CD-4137-89B0-6DD4D47DD1DB"

@interface CvTBluetoothServer : NSObject<CBPeripheralManagerDelegate>
{
    CBMutableCharacteristic *InCharacteristic;
    CBMutableCharacteristic *OutCharacteristic;
    CBMutableService *Service;
}

@property (nonatomic, strong) CBPeripheralManager *Manager;

@end


@interface CvTBluetoothClient : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBPeripheral *Peripheral;
}

@property (nonatomic, strong) CBCentralManager *Manager;
@property (nonatomic, strong) NSMutableData *Data;

@end
