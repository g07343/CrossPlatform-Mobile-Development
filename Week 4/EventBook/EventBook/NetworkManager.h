//
//  NetworkManager.h
//  EventBook
//
//  Created by Matthew Lewis on 10/22/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

+(NetworkManager*)GetIntance;
-(bool)networkConnected;
@end
