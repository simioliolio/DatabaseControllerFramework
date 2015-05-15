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
    
    // name of index column
    NSString *indexString;
    
    // derived from _columnArray in initWithDatabaseFile, used in SQL call to create the table and deposit data
    NSMutableString *columnNamesForInsertingToTable;
    
    // uses number of colums to create placeholder question marks used in SQL updates / queries
    NSMutableString *questionMarksForSQL;
    
    // derived from _columnArray. used to check for appropriate number of values being passed in to store. number of entries should tally with number of columns. actual number of columns in created table may differ from actual number of columns due to an added index
    NSUInteger numberOfDescribedColumns;
    
}

#pragma mark -- create

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
        indexString = @"entryID";
        _columnArray = columnArray;
        // go through _columnArray and gradually build up the column names as a string to be used when creating the sqlite table ( "name type, name type, ... name type" )
        NSMutableString *columnNamesForCreatingTable = [[NSMutableString alloc] initWithFormat:@"'%@' INTEGER PRIMARY KEY, ", indexString];
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

-(void)dealloc {
    [db close];
}



#pragma mark - insert

-(BOOL)addRowToTableWithValues:(NSDictionary*)entryDictionary {
    if (numberOfDescribedColumns == 0) {
        NSLog(@"DatabaseController: Entry not added. NumberOfDescribedColumns is 0. If no columns have been described, this class is useless. Initialise this class properly using an array of DatabaseControllerColumn objects");
        return NO;
    }
    // check for working database
    if (![self databaseIsReady]) {
        NSLog(@"%s: DatabaseController not initialised correctly. SQLite database either does not exist, or it will not open. Returning NO.", __FUNCTION__);
        return NO;
    }
    // insert placeholder values into array. these will be replaced by known values, leaving any unincluded values for the row as present but ambiguous
    NSMutableArray *valuesArray = [[NSMutableArray alloc] init];
    [self fillValueArrayWithBlankDataBasedOnEstablishedColumnTypes:valuesArray];
    // go through entryDictionary, and based on keys and value types, put values into the correct place in values array
    for (NSString *key in entryDictionary) {
        DatabaseControllerColumn *columnForEntry;
        BOOL seekSuccess = NO;
        for (DatabaseControllerColumn *column in self.columnArray) {
            if ([key isEqualToString:column.columnName]) {
                columnForEntry = column;
                seekSuccess = YES;
            }
        }
        if (!seekSuccess) {
            NSLog(@"%s: No column name found for key '%@'. Please check your entryDictionary keys, and match these up to the column names used to initialise this class", __FUNCTION__, key);
        } else {
            // before adding entry value to appropriate place in array, check the type matches the column type in table
            DatabaseControllerColumnDataType dataTypeOfEntry = columnForEntry.columnDataType;
            if (![entryDictionary[key] isKindOfClass:[self classForColumnType:dataTypeOfEntry]]) {
                NSLog(@"%s: *Warning* Type mismatch between key and value in entryDictionary. It is likely adding object to table will result in an error. Type of entry: %@. Expected type for column (based on column name and defined type): %@", __FUNCTION__,  NSStringFromClass([entryDictionary[key] class]), NSStringFromClass([self classForColumnType:dataTypeOfEntry]) );
            }
            [valuesArray replaceObjectAtIndex:[self.columnArray indexOfObject:columnForEntry] withObject:entryDictionary[key]];
        }
    }
    if ([valuesArray count] == 0) {
        NSLog(@"%s: None of the values in entryDictionary correspond to columns defined when initialising the class. Entry not added to table.", __FUNCTION__);
        return NO;
    }
    // excecute insert into database
    NSString *queryString = [NSString stringWithFormat:@"INSERT INTO '%@'(%@) VALUES(%@)", tableNameString, columnNamesForInsertingToTable, questionMarksForSQL];
    BOOL success = [db executeUpdate:queryString withArgumentsInArray:valuesArray];
    if (!success) {
        NSLog(@"%s: entry into database not successful. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
        return NO;
    }
    return YES;
}



#pragma mark - select

-(NSDictionary*)aquireAllEntriesInRowForIndex:(NSNumber*)index {
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@='%@'", tableNameString, indexString, index];
    // check for working database
    if (![self databaseIsReady]) {
        NSLog(@"%s: DatabaseController not initialised correctly. SQLite database either does not exist, or it will not open. Returning empty NSDictionary.", __FUNCTION__);
        return results;
    }
    // check for empty resultSet
    FMResultSet *resultSet = [db executeQuery:queryString];
    if (!resultSet) {
        NSLog(@"%s: query returned was nil. returning empty NSDictionary. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
        return results;
    }
    // add results to dictionary
    int resultSetCounter = 0;
    while ([resultSet next]) {
        for (int i = 0; i < [self.columnArray count]; i++) {
            NSString *columnName = ((DatabaseControllerColumn*)[self.columnArray objectAtIndex:i]).columnName;
            [results setObject:[resultSet objectForColumnName:columnName] forKey:columnName];
        }
        resultSetCounter++;
    }
    if (resultSetCounter == 0) {
        NSLog(@"%s: no results found. returning empty dictionary. lastErrorMessage: %@", __FUNCTION__, [db lastErrorMessage]);
        return results;
    } else if (resultSetCounter != 1) {
        NSLog(@"%s: *WARNING* number of results returned is %i. for this method, only one set of results should be returned.", __FUNCTION__, resultSetCounter);
    }
    return results;
}

-(NSArray*)acquireIndexesForTableEntry:(id)entry ofColumnType:(DatabaseControllerColumnDataType)columnType {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    // check for working database
    if (![self databaseIsReady]) {
        NSLog(@"%s: DatabaseController not initialised correctly. SQLite database either does not exist, or it will not open. Returning empty NSDictionary.", __FUNCTION__);
        return mutableArray;
    }
    // check for class type
    if (![entry isKindOfClass:[self classForColumnType:columnType]]) {
        NSLog(@"%s: entry class does not match class appropriate for columnType. see DatabaseControllerColumn.h for appropriate types, or check the class for arguement 'entry'. returning empty array", __FUNCTION__);
        return mutableArray;
    }
    // create query string and array of object arguements.
    NSMutableArray *objectArguements = [[NSMutableArray alloc] init];
    NSMutableString *queryString = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM %@ WHERE ", tableNameString];
    for (int i = 0; i < [self.columnArray count]; i++) {
        NSString *columnName = ((DatabaseControllerColumn*)[self.columnArray objectAtIndex:i]).columnName;
        NSString *additionalString = [NSString stringWithFormat:@"%@ LIKE ? ", columnName];
        [queryString appendString:additionalString];
        if (!(i == ([self.columnArray count] - 1))) { // not last one
            [queryString appendString:@"OR "];
        }
        [objectArguements addObject:entry];
    }
    // execute query, and add returned NSNumber objects into array
    FMResultSet *resultSet = [db executeQuery:queryString withArgumentsInArray:objectArguements];
    if (!resultSet) {
        NSLog(@"%s: query returned was nil. returning empty array. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
    }
    while ([resultSet next]) {
        [mutableArray addObject:[resultSet objectForColumnName:indexString]];
    }
    if ([mutableArray count] == 0) {
        NSLog(@"%s: no results found. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
    }
    return mutableArray;
}

-(NSArray*)acquireAllEntriesFromColumnWithName:(NSString*)columnName {
    NSNumber *numberOfEntries = [self currentNumberOfEntriesInTable];
    NSRange fullRange;
    fullRange.location = 1;
    fullRange.length = [numberOfEntries integerValue];
    NSArray *columnDataArray = [self acquireEntriesFromColumnWithName:columnName withRangeOfIndexes:fullRange];
    return columnDataArray;
}

-(NSArray*)acquireEntriesFromColumnWithName:(NSString*)columnName withRangeOfIndexes:(NSRange)range {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    // check for working database
    if (![self databaseIsReady]) {
        NSLog(@"%s: DatabaseController not initialised correctly. SQLite database either does not exist, or it will not open. Returning empty NSDictionary.", __FUNCTION__);
        return mutableArray;
    }
    NSUInteger indexStart = range.location;
    NSUInteger indexLength = range.length;
    NSUInteger indexEnd = indexStart + indexLength - 1;
    if (indexLength == 0) {
        NSLog(@"%s: asking for a range length of 0. returning empty array", __FUNCTION__);
        return mutableArray;
    }
    NSNumber *currentNumberOfEntries = [self currentNumberOfEntriesInTable];
    if (indexStart < 1 || indexEnd > [currentNumberOfEntries integerValue]) {
        NSLog(@"%s: *WARNING* proposed range goes beyond the number of entries available. current number of entries == %li, start index asked for is %li, end index asked for is %li. returning empty array", __FUNCTION__, [currentNumberOfEntries integerValue], indexStart, indexEnd);
        return mutableArray;
    }
    BOOL stringMatchesWithColumnName = NO;
    for (DatabaseControllerColumn *column in self.columnArray) {
        NSString *testColumnString = column.columnName;
        if ([columnName isEqualToString:testColumnString]) {
            stringMatchesWithColumnName = YES;
        }
    }
    if (!stringMatchesWithColumnName) {
        NSLog(@"%s: columnName doesn't match an existing column. check column name. returning empty array.", __FUNCTION__);
        return mutableArray;
    }
    NSString *queryString = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ >= %li AND %@ <= %li", columnName, tableNameString, indexString, indexStart, indexString, indexEnd];
    FMResultSet *resultSet = [db executeQuery:queryString];
    if (!resultSet) {
        NSLog(@"%s: query returned was nil. returning empty array. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
        return mutableArray;
    }
    int resultSetCounter = 0;
    while ([resultSet next]) {
        [mutableArray addObject:[resultSet objectForColumnName:columnName]];
        resultSetCounter++;
    }
    if (resultSetCounter == 0) {
        NSLog(@"%s: no results found. returning an empty array. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
        return mutableArray;
    }
    
    return mutableArray;
}

-(NSNumber*)currentNumberOfEntriesInTable {
    NSNumber *returnNumber = [NSNumber numberWithInt:0];
    // check for working database
    if (![self databaseIsReady]) {
        NSLog(@"%s: DatabaseController not initialised correctly. SQLite database either does not exist, or it will not open. Returning a 0.", __FUNCTION__);
        return returnNumber;
    }
    NSString *queryString = [NSString stringWithFormat:@"SELECT Count(*) FROM %@", tableNameString];
    FMResultSet *resultSet = [db executeQuery:queryString];
    if (!resultSet) {
        NSLog(@"%s: query returned was nil. returning 0. sql error: %@", __FUNCTION__, [db lastErrorMessage]);
        return returnNumber;
    }
    int resultSetCounter = 0;
    while ([resultSet next]) {
        returnNumber = [NSNumber numberWithInt:[resultSet intForColumnIndex:0]];
        resultSetCounter++;
    }
    if (resultSetCounter == 0) {
        NSLog(@"%s: no results found. returning a 0. lastErrorMessage: %@", __FUNCTION__, [db lastErrorMessage]);
        return returnNumber;
    } else if (resultSetCounter != 1) {
        NSLog(@"%s: *WARNING* number of results returned is %i. for this method, only one set of results should be returned.", __FUNCTION__, resultSetCounter);
    }
    
    return returnNumber;
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

-(BOOL)databaseIsReady {
    if (!db) {
        NSLog(@"%s: DatabaseController not initialised correctly. SQLite database does not exist.", __FUNCTION__);
        return NO;
    }
    if (![db open]) {
        NSLog(@"%s: SQLite database not opening. Check database file (chosen on initialisation) is not in use by any other database reader.", __FUNCTION__);
        return NO;
    }
    return YES;
}


@end




