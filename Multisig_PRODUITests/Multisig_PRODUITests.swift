//
//  Multisig_PRODUITests.swift
//  Multisig_PRODUITests
//
//  Created by Gnosis on 11.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import XCTest

class Multisig_PRODUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        XCUIApplication().launch()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadSafeWithENSName() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        //Given:
        let loadExistingSafeBtn=app/*@START_MENU_TOKEN@*/.buttons["Load existing Safe"].staticTexts["Load existing Safe"]/*[[".buttons[\"Load existing Safe\"].staticTexts[\"Load existing Safe\"]",".staticTexts[\"Load existing Safe\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        let rinkebynetwork=app.tables/*@START_MENU_TOKEN@*/.cells.staticTexts["Rinkeby"]/*[[".cells.staticTexts[\"Rinkeby\"]",".staticTexts[\"Rinkeby\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        let addSafeAddress=app.textFields["Enter Safe Address"]
        let selectENSnameOption=app.sheets.scrollViews.otherElements.buttons["Enter ENS Name"]
        let ensnameTextField = app.textFields["Enter ENS Name"]
        let confirmENSName=app.navigationBars["Enter ENS Name"].buttons["Confirm"]
        let loadSafeNavigation=app.navigationBars["Load Gnosis Safe"].buttons["Next"]
        let safenameTextField = app.textFields["Enter name"]
        // Use recording to get started writing UI tests.
        // no added safes. Load existing safe from asstes screen
        //When:
        loadExistingSafeBtn.tap()
        // select Rinkeby network
        rinkebynetwork.tap()
        //call add address options
        addSafeAddress.tap()
        // select Enter ens name as an option to add safe address
        selectENSnameOption.tap()
        // add ens name and check the address detection from ENS name
        ensnameTextField.tap()
        ensnameTextField.typeText("liltestsafe.eth")
        // need to add delay till address is detected from ens name and check that the correct address was detected
        // go from enter ens name with valid detection
        confirmENSName.tap()
        //confirm safe address
        loadSafeNavigation.tap()
        // enter safe local name before the loading flow is done
        safenameTextField.tap()
        safenameTextField.typeText("TestSafeFromENSName")
        loadSafeNavigation.tap()
        
      //  app.sheets.scrollViews.otherElements.buttons["Paste from Clipboard"].tap()
      //  app.navigationBars["Load Gnosis Safe"].buttons["Next"].tap()
                        
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //Then:
        XCTAssertTrue(app.staticTexts.element.label=="TestSafeFromENSName")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
