//
//  DatabaseController.m
//  SkyPhotobomb
//
//  Created by Simon Haycock on 06/05/2015.
//  Copyright (c) 2015 sky. All rights reserved.
//

#import "DatabaseController.h"
#import "FMDB.h"

@implementation DatabaseController {
    // sqlite database
    FMDatabase *db;
    
    // used to define names in database
    NSString *tableNameString;
    
    // derived from _columnArray in initWithDatabaseFile, used in SQL call to create the table and deposit data
    NSMutableString *columnNamesForInsertingToTable;
    
    // uses number of colums to create question marks used to store data
    NSMutableString *questionMarksForSQL;
    
    // derived from _columnArray. used to check for appropriate number of values being passed in to store. number of entries should tally with number of columns. actual number of columns in created table may differ from actual number of columns due to an added index
    NSUInteger numberOfDescribedColumns;
    
}

-(instancetype)initWithDatabaseFilePath:(NSString*)absolutePath tableName:(NSString*)tableName columnArray:(NSArray*)columnArray {
    self = [super init];
    if (self) {
        
        db = [FMDatabase databaseWithPath:absolutePath];
        if (![db open]) {
            NSException *exception = [NSException
                                      exceptionWithName:@"DatabaseControllerPathNotValidException"
                                      reason:[NSString stringWithFormat:@"Path used to initialise DatabaseController is not valid, as database could not be created / opened. Check permissions for path: %@", absolutePath]
                                      userInfo:nil];
            @throw exception;
            return nil;
        }
        
        tableNameString = tableName;
        _columnArray = columnArray;
        
        // go through _columnArray and gradually build up the column names as a string to be used when creating the sqlite table ( "name type, name type, ... name type" )
        NSMutableString *columnNamesForCreatingTable = [[NSMutableString alloc] initWithString:@"'id' INTEGER PRIMARY KEY, "];
        columnNamesForInsertingToTable = [[NSMutableString alloc] init];
        NSUInteger columnArrayCount = [self.columnArray count];
        NSUInteger arrayFocusCounter = 0;
        for (DatabaseControllerColumn *column in self.columnArray) {
            
            // SQL string for creating columns in table
            NSMutableString *tempString = [NSMutableString stringWithFormat:@"'%@' %@", column.columnName, [self sqlStringForDataType:column.columnDataType]];
            if (arrayFocusCounter != (columnArrayCount - 1)) { // no comma and space for the last column
                [tempString appendString:@", "];
            }
            [columnNamesForCreatingTable appendString:tempString];
            
            // SQL string for inserting data into table (omits type)
            [columnNamesForInsertingToTable appendString:[NSString stringWithFormat:@"'%@'",column.columnName]];
            if (arrayFocusCounter != (columnArrayCount - 1)) { // no comma and space for the last column
                [columnNamesForInsertingToTable appendString:@", "];
            }
            
            arrayFocusCounter++;
            
        }
//        NSLog(@"DatabaseController: columnNamesForCreatingTable:%@", columnNamesForCreatingTable);
//        NSLog(@"DatabaseController: columnNamesForInsertingToTable:%@", columnNamesForInsertingToTable);
        
        // make ? placeholders for sql table inserts
        questionMarksForSQL = [[NSMutableString alloc] init];
        for (NSUInteger index = 0; index < [self.columnArray count]; index++) {
            [questionMarksForSQL appendString:@"?"];
            if (index != ([self.columnArray count] - 1)) { // if not last, add a comma and a space
                [questionMarksForSQL appendString:@", "];
            }
        }
        
        // check for number of DatabaseControllerColumn objects pulled out of array, and store number for later
        if (columnArrayCount != arrayFocusCounter) {
            NSLog(@"DatabaseController: %li objects in _columnArray used to initialise database controller were not of type DatabaseControllerColumn. Behaviour whilst storing data is undefined. Table will not be created. Any attempt to store data will fail, as it is assumed the number of columns is 0", (columnArrayCount - arrayFocusCounter));
            numberOfDescribedColumns = 0;
            
        } else {
            numberOfDescribedColumns = arrayFocusCounter;
            
            // create table if doesn't already exist (below only works on SQL 3.3 and above)
            [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@);", tableNameString, columnNamesForCreatingTable]];
        }

    }
    return self;
}

-(BOOL)addEntryToDatabase:(NSDictionary*)entryDictionary {

    if (numberOfDescribedColumns == 0) {
        NSLog(@"DatabaseController: Entry not added. NumberOfDescribedColumns is 0. If no columns have been described, this class is useless. Initialise this class properly using an array of DatabaseControllerColumn objects");
        return NO;
    }
    
    // replace placeholder values in this array
    NSMutableArray *valuesArray = [[NSMutableArray alloc] init];
    [self fillValueArrayWithBlankDataBasedOnEstablishedColumnTypes:valuesArray];
    
    // go through entryDictionary, and based on keys and value types, put values into the correct place in values array
    for (NSString *key in entryDictionary) {
        
//        NSLog(@"DatabaseController: *DEBUG* key in question is '%@'. value for key is '%@' ", key, entryDictionary[key]);
        
        // find the column corresponding to the entry
        DatabaseControllerColumn *columnForEntry;
        BOOL seekSuccess = NO;
        for (DatabaseControllerColumn *column in self.columnArray) {
            
            if ([key isEqualToString:column.columnName]) {
//                NSLog(@"DatabaseController: *DEBUG* column found: %@", column.columnName);
                columnForEntry = column;
                seekSuccess = YES;
            }
        }
        if (!seekSuccess) {
            NSLog(@"DatabaseController: No column name found for key '%@'. Please check your entryDictionary keys, and match these up to the column names used to initialise this class", key);
        } else {
            // before adding entry value to appropriate place in array, check the type matches the column type in table
            DatabaseControllerColumnDataType dataTypeOfEntry = columnForEntry.columnDataType;
            if (![entryDictionary[key] isKindOfClass:[self classForColumnType:dataTypeOfEntry]]) {
                NSLog(@"DatabaseController: *Warning* Type mismatch between key and value in entryDictionary. It is likely adding object to table will result in an error. Type of entry: %@. Expected type for column (based on column name and defined type): %@", NSStringFromClass([entryDictionary[key] class]), NSStringFromClass([self classForColumnType:dataTypeOfEntry]) );
            }
            [valuesArray replaceObjectAtIndex:[self.columnArray indexOfObject:columnForEntry] withObject:entryDictionary[key]];
//            NSLog(@"DatabaseController: *DEBUG* object added to valuesArray");
        }
    }
    
    if ([valuesArray count] == 0) {
        NSLog(@"DatabaseController: None of the values in entryDictionary correspond to columns defined when initialising the class. Entry not added to table.");
        return NO;
    }
    
//    NSLog(@"DatabaseControleer: *DEBUG* valuesArray: %@", valuesArray);
    
    NSString *queryString = [NSString stringWithFormat:@"INSERT INTO '%@'(%@) VALUES(%@)", tableNameString, columnNamesForInsertingToTable, questionMarksForSQL];
//    NSLog(@"DatabaseController: queryString used for execute update: %@", queryString);
    BOOL success = [db executeUpdate:queryString withArgumentsInArray:valuesArray];
    return success;
    
}

-(void)dealloc {
    [db close];
}



#pragma mark - internal utility methods
-(NSString*)sqlStringForDataType:(DatabaseControllerColumnDataType)dataType {
    NSString *returnString;
    switch (dataType) {
        case DatabaseControllerColumnDataTypeNull:
            returnString = @"NULL";
            break;
        case DatabaseControllerColumnDataTypeText:
            returnString = @"TEXT";
            break;
        case DatabaseControllerColumnDataTypeInteger:
            returnString = @"INTEGER";
            break;
        case DatabaseControllerColumnDataTypeReal:
            returnString = @"REAL";
            break;
        case DatabaseControllerColumnDataTypeBlob:
            returnString = @"BLOB";
            break;
        default:
            break;
    }
    return returnString;
}

-(void)fillValueArrayWithBlankDataBasedOnEstablishedColumnTypes:(NSMutableArray*)_valuesArray {
    if (!self.columnArray) {
        NSLog(@"DatabaseController: No columnArray.");
        return;
    }
    if ([self.columnArray count] == 0) {
        NSLog(@"DatabaseController: ColumnArray is empty");
        return;
    }
    for (DatabaseControllerColumn *column in self.columnArray) {
        switch (column.columnDataType) {
            case DatabaseControllerColumnDataTypeNull:
                [_valuesArray addObject:[NSNull null]];
                break;
            case DatabaseControllerColumnDataTypeText:
                [_valuesArray addObject:[NSString stringWithFormat:@"n/a"]];
                break;
            case DatabaseControllerColumnDataTypeInteger:
                [_valuesArray addObject:[NSNumber numberWithInt:0]];
                break;
            case DatabaseControllerColumnDataTypeReal:
                [_valuesArray addObject:[NSNumber numberWithFloat:0.0]];
                break;
            case DatabaseControllerColumnDataTypeBlob:
                [_valuesArray addObject:[NSData data]];
                break;
            default:
                break;
        }
    }
}

-(Class)classForColumnType:(DatabaseControllerColumnDataType)type {
    Class returnClass;
    switch (type) {
        case DatabaseControllerColumnDataTypeNull:
            returnClass = [NSNull class];
            break;
        case DatabaseControllerColumnDataTypeText:
            returnClass = [NSString class];
            break;
        case DatabaseControllerColumnDataTypeInteger:
            returnClass = [NSNumber class];
            break;
        case DatabaseControllerColumnDataTypeReal:
            returnClass = [NSNumber class];
            break;
        case DatabaseControllerColumnDataTypeBlob:
            returnClass = [NSData class];
            break;
        default:
            break;
    }
    
    return returnClass;
}


@end

/*
// Database Controller usage example

// set these to customize database name and location
NSString *folderForDatabase = @"/tmp/";
NSString *databaseNameAndExtension = @"database.sqlite";
NSString *pathStringForDatabase = [NSString stringWithFormat:@"%@%@", folderForDatabase, databaseNameAndExtension];
NSString *tableName = @"userDetails";
DatabaseControllerColumn *lastNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"LastName" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *firstNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"FirstName" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *addresssColumn = [[DatabaseControllerColumn alloc] initWithName:@"Address" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *emailColumn = [[DatabaseControllerColumn alloc] initWithName:@"Email" dataType:DatabaseControllerColumnDataTypeText];
NSArray *columnDefinitionArray = @[lastNameColumn,firstNameColumn,addresssColumn,emailColumn];
DatabaseController *dbController = [[DatabaseController alloc] initWithDatabaseFilePath:pathStringForDatabase tableName:tableName columnArray:columnDefinitionArray];
// add a test entry
NSDictionary *testDictionary = @{@"LastName": @"Gander",@"FirstName": @"Simion",@"Address": @"62, Hatstand Trestle, London W4A 4A4",@"Email": @"simon@hatstand.com"};
if ([dbController addEntryToDatabase:testDictionary]) {
    NSLog(@"DatabaseController: Database entry added successfully");
} else {
    NSLog(@"DatabaseController: Warning: Database entry NOT added successfully");
}
// -- end main test */

/*
// -- different test (3 columns)
// set these to customize database name and location
NSString *folderForDatabase = @"/tmp/";
NSString *databaseNameAndExtension = @"database.sqlite";
NSString *pathStringForDatabase = [NSString stringWithFormat:@"%@%@", folderForDatabase, databaseNameAndExtension];
NSString *tableName = @"Steelers Wheel Lyrical Analysis";
DatabaseControllerColumn *left = [[DatabaseControllerColumn alloc] initWithName:@"left of me" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *right = [[DatabaseControllerColumn alloc] initWithName:@"to the right" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *middle = [[DatabaseControllerColumn alloc] initWithName:@"in the middle with you" dataType:DatabaseControllerColumnDataTypeText];
NSArray *columnDefinitionArray = @[left,right,middle];
DatabaseController *dbController = [[DatabaseController alloc] initWithDatabaseFilePath:pathStringForDatabase tableName:tableName columnArray:columnDefinitionArray];
NSDictionary *testDictionary = @{@"left of me": @"Clowns",@"to the right": @"Jokers",@"in the middle with you": @"Me, stuck."};
if ([dbController addEntryToDatabase:testDictionary]) {
    NSLog(@"DatabaseController: Database entry added successfully");
} else {
    NSLog(@"DatabaseController: Warning: Database entry NOT added successfully");
}
// -- end -- */





