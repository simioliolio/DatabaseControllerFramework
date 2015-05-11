//
//  DatabaseControllerColumn.h
//  SkyPhotobomb
//
//  Created by Simon Haycock on 07/05/2015.
//  Copyright (c) 2015 sky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DatabaseControllerColumn : NSObject

typedef NS_ENUM(NSInteger, DatabaseControllerColumnDataType) {
    DatabaseControllerColumnDataTypeNull,       // NSNull
    DatabaseControllerColumnDataTypeInteger,    // NSNumber
    DatabaseControllerColumnDataTypeReal,       // NSNumber
    DatabaseControllerColumnDataTypeText,       // NSString
    DatabaseControllerColumnDataTypeBlob        // NSData
};

@property (strong) NSString *columnName;
@property (nonatomic) DatabaseControllerColumnDataType columnDataType;

-(instancetype)initWithName:(NSString*)name dataType:(DatabaseControllerColumnDataType)dataType;

@end
