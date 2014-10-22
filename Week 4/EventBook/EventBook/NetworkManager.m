//
//  NetworkManager.m
//  EventBook
//
//  Created by Matthew Lewis on 10/22/14.
//  Copyright (c) 2014 com.fullsail. All rights reserved.
//

#import "NetworkManager.h"
#import "Reachability.h"

@implementation NetworkManager

static NetworkManager *_instance = nil;
Reachability *reachHost;

+(NetworkManager*)GetIntance {
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    return _instance;
}

+(id)alloc {
    _instance = [super alloc];
    return _instance;
}

-(id)init {
    if (self = [super init]) {
        
    }
    return self;
}

-(bool)networkConnected {
    bool isConnected;
    
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    
    NetworkStatus status = [reach currentReachabilityStatus];
    if (status == NotReachable) {
        isConnected = false;
    } else {
        isConnected = true;
    }
    
    return isConnected;
}
@end
