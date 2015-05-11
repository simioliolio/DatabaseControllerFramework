//
//  DatabaseController.h
//  SkyPhotobomb
//
//  Created by Simon Haycock on 06/05/2015.
//  Copyright (c) 2015 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DatabaseControllerColumn.h"

@interface DatabaseController : NSObject

/* Array of DatabaseControllerColumn objects in use in the 
 * current table. These are set during initWithDatabaseFile, 
 * but can be referenced after init via this property
 */
@property (readonly, strong) NSArray *columnArray;

/* Column array contains DatabaseControllerColumn objects
 * which dictate the name and data type of each column.
 */
-(instancetype)initWithDatabaseFilePath:(NSString*)absolutePath tableName:(NSString*)tableName columnArray:(NSArray*)columnArray;

/* entryDictionary should reference the column names
 * used to define the DatabaseControllerColumn objects
 * passed in during initialisation. Also, values in dictionary must be of the exact class defined in DatabaseControllerColumn (ie, defining an NSString using @"string" definition
 */
-(BOOL)addEntryToDatabase:(NSDictionary*)entryDictionary;

@end
