//
//  ColorUtilsTests.swift
//  iParapheurTests
//
//  Created by Adrien Bricchi on 15/11/2017.
//

import XCTest
@testable import iParapheur


class ColorUtilsTests: XCTestCase {


    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }


    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testColorForAction() {
		XCTAssertEqual(ColorUtils.colorForAction(action: "VISA"), ColorUtils.DarkGreen)
		XCTAssertEqual(ColorUtils.colorForAction(action: "SIGNATURE"), ColorUtils.DarkGreen)
		XCTAssertEqual(ColorUtils.colorForAction(action: "REJET"), ColorUtils.DarkRed)
		XCTAssertEqual(ColorUtils.colorForAction(action: "ARCHIVER"), UIKit.UIColor.black)
		XCTAssertEqual(ColorUtils.colorForAction(action: "PLOP"), UIKit.UIColor.lightGray)
    }


//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
	
}
