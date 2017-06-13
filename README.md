# DatabaseControllerFramework

## About ##
This OSX Objective C framework acts as a wrapper around the [fmdb framework](https://github.com/ccgus/fmdb), to simplify the creating and editing of SQLite databases. It was intially created as an experiment to view how useful such a tool would be going forward, and since Apple's introduction of Swift, this project has been put on hold. However it is still a useful reference for others implementing their own use of fmdb in Objective C.

## Usage ##
```
// define database columns
DatabaseControllerColumn *lastNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"LastName" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *firstNameColumn = [[DatabaseControllerColumn alloc] initWithName:@"FirstName" dataType:DatabaseControllerColumnDataTypeText];
DatabaseControllerColumn *ageColumn = [[DatabaseControllerColumn alloc] initWithName:@"Age" dataType:DatabaseControllerColumnDataTypeInteger];
NSArray *columnDefinitionArray = @[lastNameColumn, firstNameColumn, addresssColumn, emailColumn, ageColumn];

// create database
DatabaseController *dbController = [[DatabaseController alloc] initWithDatabaseFilePath:pathStringForDatabase tableName:tableName columnArray:columnDefinitionArray];

// Add row
NSDictionary *entryRow = @{@"LastName"  : @"Bloggs",
                           @"FirstName" : @"Joe",
                           @"Age"       : @(30) };
BOOL success = [dbController addRowToTableWithValues: entryRow];
```
