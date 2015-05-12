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
    
    // gather data and use to initialise database and create table. if table with chosen column names already exists, new entries will be added to it.
    NSArray *columnDefinitionArray = @[lastNameColumn,firstNameColumn,addresssColumn,emailColumn];
    NSString *pathStringForDatabase = [NSString stringWithFormat:@"%@%@", folderForDatabase, databaseNameAndExtension];
    DatabaseController *dbController = [[DatabaseController alloc] initWithDatabaseFilePath:pathStringForDatabase tableName:tableName columnArray:columnDefinitionArray];
    
    // make a test entry
    NSDictionary *testDictionary = @{@"LastName"    : @"Gander",
                                     @"FirstName"   : @"Simion",
                                     @"Address"     : @"62, Hatstand Trestle, London W4A 4A4",
                                     @"Email"       : @"simon@hatstand.com"};
    
    BOOL entryAddedSuccessfully = [dbController addEntryToDatabase:testDictionary];
    XCTAssertEqual(entryAddedSuccessfully, YES, @"Adding test entry into database was not successful.");
    
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
