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



#pragma mark -- create

/* Column array contains DatabaseControllerColumn objects
 * which dictate the name and data type of each column.
 */
-(instancetype)initWithDatabaseFilePath:(NSString*)absolutePath tableName:(NSString*)tableName columnArray:(NSArray*)columnArray;



#pragma mark - insert

/* Entry is added to the bottom of the table, and given an
 * appropriate index.
 * entryDictionary should reference the column names
 * used to define the DatabaseControllerColumn objects
 * passed in during initialisation. Also, values in 
 * dictionary must be of the exact class defined in 
 * DatabaseControllerColumn.h (ie, a column defined as
 * DatabaseControllerColumnDataTypeText will accept an
 * object of type NSString, etc).
 
 */
-(BOOL)addRowToTableWithValues:(NSDictionary*)entryDictionary;



#pragma mark - select

/* Returned dictionary contains keys which represent the 
 * columns, and objects for those columns at the index 'index'.
 */
-(NSDictionary*)aquireAllEntriesInRowForIndex:(NSNumber*)index;

/* The whole database is searched, and returns an array 
 * of NSNumber objects representing index values for rows 
 * which contain 'entry'.
 * Note: When searching for a string, use '%' to
 * search within strings. For example, an NSString
 * formatted "%jon%" will return rows containing the 
 * string "Jonathan". All string searches are 
 * case-insensitive.
 */
-(NSArray*)acquireIndexesForTableEntry:(id)entry ofColumnType:(DatabaseControllerColumnDataType)columnType;

/* todo
 */
-(NSArray*)acquireAllEntriesFromColumnWithName:(NSString*)columnName;

// not a zero-counted index
-(NSArray*)acquireEntriesFromColumnWithName:(NSString*)columnName withRangeOfIndexes:(NSRange)range;

-(NSNumber*)currentNumberOfEntriesInTable;
@end
