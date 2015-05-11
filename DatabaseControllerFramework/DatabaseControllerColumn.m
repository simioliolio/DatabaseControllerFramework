//
//  DatabaseControllerColumn.m
//  SkyPhotobomb
//
//  Created by Simon Haycock on 07/05/2015.
//  Copyright (c) 2015 sky. All rights reserved.
//

#import "DatabaseControllerColumn.h"

@implementation DatabaseControllerColumn

-(instancetype)initWithName:(NSString *)name dataType:(DatabaseControllerColumnDataType)dataType {
    self = [super init];
    if (self) {
        self.columnName = name;
        self.columnDataType = dataType;
    }
    return self;
}

@end
