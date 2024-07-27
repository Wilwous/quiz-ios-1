//
//  ArrayTests.swift
//  ArrayTests
//
//  Created by Антон Павлов on 11.07.2023.
//

import XCTest
@testable import MovieQuiz

class ArrayTest: XCTestCase {
    func testGetValueInRnge() throws {
        
        let array = [1,1,2,3,5]
        
        let value = array[safe:2]
        
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 2)
    }
    
    func testGetValueOutOfRange() throws {
        
        let array = [1,1,2,3,5]
        
        let value = array[safe: 20]
        
        XCTAssertNil(value)
    }
}

