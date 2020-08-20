//
//  WifiGatewayIP.m
//  AmahiAnywhere
//
//  Created by Shresth Pratap Singh on 18/08/20.
//  Copyright © 2020 Amahi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WifiGatewayIPHelper.c"
#import "WifiGatewayIP.h"
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation WifiGatewayIP

+ (NSString *)getGatewayIP {
    NSString *ipString = nil;
    struct in_addr gatewayaddr;
    int r = getdefaultgateway(&(gatewayaddr.s_addr));
    if(r >= 0) {
        ipString = [NSString stringWithFormat: @"%s",inet_ntoa(gatewayaddr)];
    } else {
        NSLog(@"Wifi is not connected or you are using simulator Gateway ip address will be nil");
    }
    
    return ipString;
}

@end
