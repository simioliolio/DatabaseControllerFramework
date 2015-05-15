//
//  DatabaseControllerFrameworkTests.m
//  DatabaseControllerFrameworkTests
//
//  Created by Simon Haycock on 11/05/2015.
//  Copyright (c) 2015 Oxygn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <DatabaseControllerFramework/DatabaseControllerFramework.h>

@interface DatabaseControllerFrameworkTests : XCTestCase

@end

@implementation DatabaseControllerFrameworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testDatabaseCreationAndEntry {
    
    // set these to customize database name and location
    NSString *folderForDatabase = @"/tmp/";
    NSString *databaseNameAndExtension = @"database.sqlite";
    NSString *tableName = @"userDetails";
    DatabaseControllerColumn *lastNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"LastName" dataType:DatabaseControllerColumnDataTypeText];
    DatabaseControllerColumn *firstNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"FirstName" dataType:DatabaseControllerColumnDataTypeText];
    DatabaseControllerColumn *addresssColumn = [[DatabaseControllerColumn alloc] initWithName:@"Address" dataType:DatabaseControllerColumnDataTypeText];
    DatabaseControllerColumn *emailColumn = [[DatabaseControllerColumn alloc] initWithName:@"Email" dataType:DatabaseControllerColumnDataTypeText];
    DatabaseControllerColumn *ageColumn = [[DatabaseControllerColumn alloc] initWithName:@"Age" dataType:DatabaseControllerColumnDataTypeInteger];
    
    // gather data and use to initialise database and create table. if table with chosen column names already exists, new entries will be added to it.
    NSArray *columnDefinitionArray = @[lastNameColumn, firstNameColumn, addresssColumn, emailColumn, ageColumn];
    NSString *pathStringForDatabase = [NSString stringWithFormat:@"%@%@", folderForDatabase, databaseNameAndExtension];
    DatabaseController *dbController = [[DatabaseController alloc] initWithDatabaseFilePath:pathStringForDatabase tableName:tableName columnArray:columnDefinitionArray];
    
    /*
    // add a test entry
    NSDictionary *testDictionary = @{@"LastName"    : @"Terry",
                                     @"FirstName"   : @"John",
                                     @"Address"     : @"Stamford Bridge",
                                     @"Email"       : @"john@terry.com",
                                     @"Age"         : [NSNumber numberWithInt:41]};
    
    BOOL entryAddedSuccessfully = [dbController addRowToTableWithValues:testDictionary];
    */
    
    // add loads of test entries
    NSUInteger numberOfEntries = 1000;
    BOOL entryAddedSuccessfully = NO;
    for (NSUInteger i = 1; i <= numberOfEntries; i++) {
        NSDictionary *testDictionary = @{@"LastName"    : [NSString stringWithFormat:@"Terry no.%li", i],
                                         @"FirstName"   : [NSString stringWithFormat:@"John no.%li", i],
                                         @"Address"     : [NSString stringWithFormat:@"Stamford Bridge version %li", i],
                                         @"Email"       : [NSString stringWithFormat:@"john%li @ terry . com", i],
                                         @"Age"         : [NSNumber numberWithInt:(41 + i)]};
        entryAddedSuccessfully = [dbController addRowToTableWithValues:testDictionary];
    }
    
    /*
    // print a row from the created database
    NSNumber *testReadIndex = [NSNumber numberWithInt:3];
    NSDictionary *resultDictionary = [dbController aquireAllEntriesInRowForIndex:testReadIndex];
    NSLog(@"objects and column names at index %@: \n%@", testReadIndex, resultDictionary);
    */
    
    /*
    // find index for a certain string
    NSString *searchString = @"%%Stam%%";
    NSArray *idsContainingString = [dbController acquireIndexesForTableEntry:searchString ofColumnType:DatabaseControllerColumnDataTypeText];
    NSLog(@"idsContainingString: \n%@", idsContainingString);
    */
    
    /*
    // find index for a number
    NSNumber *searchNumber = [NSNumber numberWithInt:414];
    NSArray *idsContainingNumber = [dbController acquireIndexesForTableEntry:searchNumber ofColumnType:DatabaseControllerColumnDataTypeInteger];
    NSLog(@"idsContainingNumber: \n%@", idsContainingNumber);
    */
    
    /*
    // find number of entries in table
    NSNumber *numberOfEntriesInTable = [dbController currentNumberOfEntriesInTable];
    NSLog(@"numberOfEntriesInTable: %@", numberOfEntriesInTable);
    */
    
    /*
    // get values in a column
    NSRange indexRange;
    indexRange.location = 7;
    indexRange.length = 18;
    NSArray *arrayOfLastNames = [dbController acquireEntriesFromColumnWithName:@"LastName" withRangeOfIndexes:indexRange];
    NSLog(@"arrayOfSelectedLastNames: %@", arrayOfLastNames);
     */
    
    /*
    // get all values in column
    NSArray *arrayOfAllFirstNames = [dbController acquireAllEntriesFromColumnWithName:@"FirstName"];
//    NSLog(@"arrayOfAllFirstNames: %@", arrayOfAllFirstNames);
    */
    
    XCTAssertEqual(entryAddedSuccessfully, YES, @"Adding test entry into database was not successful.");
    
}

-(void)testPerformanceOfIndexLookup {
    [self measureBlock:^{
        // set these to customize database name and location
        NSString *folderForDatabase = @"/tmp/";
        NSString *databaseNameAndExtension = @"database.sqlite";
        NSString *tableName = @"userDetails";
        DatabaseControllerColumn *lastNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"LastName" dataType:DatabaseControllerColumnDataTypeText];
        DatabaseControllerColumn *firstNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"FirstName" dataType:DatabaseControllerColumnDataTypeText];
        DatabaseControllerColumn *addresssColumn = [[DatabaseControllerColumn alloc] initWithName:@"Address" dataType:DatabaseControllerColumnDataTypeText];
        DatabaseControllerColumn *emailColumn = [[DatabaseControllerColumn alloc] initWithName:@"Email" dataType:DatabaseControllerColumnDataTypeText];
        DatabaseControllerColumn *ageColumn = [[DatabaseControllerColumn alloc] initWithName:@"Age" dataType:DatabaseControllerColumnDataTypeInteger];
        
        // gather data and use to initialise database and create table. if table with chosen column names already exists, new entries will be added to it.
        NSArray *columnDefinitionArray = @[lastNameColumn, firstNameColumn, addresssColumn, emailColumn, ageColumn];
        NSString *pathStringForDatabase = [NSString stringWithFormat:@"%@%@", folderForDatabase, databaseNameAndExtension];
        DatabaseController *dbController = [[DatabaseController alloc] initWithDatabaseFilePath:pathStringForDatabase tableName:tableName columnArray:columnDefinitionArray];
        
        NSNumber *numberOfEntries = [dbController currentNumberOfEntriesInTable];
//        NSLog(@"numberOfEntries = %@", numberOfEntries);
        
        // print a row from the created database
        NSNumber *testReadIndex = [NSNumber numberWithInteger:[numberOfEntries integerValue] - 1];
        NSDictionary *resultDictionary = [dbController aquireAllEntriesInRowForIndex:testReadIndex];
//        NSLog(@"objects and column names at index %@: \n%@", testReadIndex, resultDictionary);
        
    }];
}


//- (void)testExample {
//    // This is an example of a functional test case.
//    XCTAssert(YES, @"Pass");
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
