//
//  AnswerResultTypeJSONTests.swift
//  ResearchTests_iOS
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import XCTest
@testable import Research

class AnswerResultTypeJSONTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Use a statically defined timezone.
        rsd_ISO8601TimestampFormatter.timeZone = TimeZone(secondsFromGMT: Int(-2.5 * 60 * 60))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAnswerResultObject_String_Codable() {
        do {
            let expectedObject = "hello"
            let expectedJson = "hello"

            let answerType = RSDAnswerResultType(baseType: .string)
            let objectValue = try answerType.jsonDecode(from: expectedJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? String, expectedObject)
            XCTAssertEqual(jsonValue as? String, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_Data_Codable() {
        do {
            let expectedObject = Data(base64Encoded: "abcd")
            let expectedJson = "abcd"
            
            let answerType = RSDAnswerResultType(baseType: .data)
            let objectValue = try answerType.jsonDecode(from: expectedJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Data, expectedObject)
            XCTAssertEqual((jsonValue as? String)?.lowercased(with: Locale(identifier: "en_US")), expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_Bool_Codable() {
         do {
            let expectedObject = true
            let expectedJson = NSNumber(value: true)
            
            let answerType = RSDAnswerResultType(baseType: .boolean)
            let objectValue = try answerType.jsonDecode(from: expectedJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Bool, expectedObject)
            XCTAssertEqual(jsonValue as? NSNumber, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_Int_Codable() {
        do {
            let expectedObject = 12
            let expectedJson = NSNumber(value: 12)
            
            let answerType = RSDAnswerResultType(baseType: .integer)
            let objectValue = try answerType.jsonDecode(from: expectedJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Int, expectedObject)
            XCTAssertEqual(jsonValue as? NSNumber, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_Double_Codable() {
        do {
            let expectedObject = 12.5
            let expectedJson = NSNumber(value: 12.5)
            
            let answerType = RSDAnswerResultType(baseType: .decimal)
            let objectValue = try answerType.jsonDecode(from: expectedJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Double, expectedObject)
            XCTAssertEqual(jsonValue as? NSNumber, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_Date_Codable() {

        do {

            let expectedJson = "2016-02-20"
            
            let answerType = RSDAnswerResultType(baseType: .date, sequenceType: nil, formDataType: nil, dateFormat: "yyyy-MM-dd")
            let objectValue = try answerType.jsonDecode(from: expectedJson)
            
            if let date = objectValue as? Date {
                let calendar = Calendar(identifier: .iso8601)
                let calendarComponents: Set<Calendar.Component> = [.year, .month, .day]
                let comp = calendar.dateComponents(calendarComponents, from: date)
                XCTAssertEqual(comp.year, 2016)
                XCTAssertEqual(comp.month, 2)
                XCTAssertEqual(comp.day, 20)
                
                let jsonValue = try answerType.jsonEncode(from: date)
                XCTAssertEqual(jsonValue as? String, expectedJson)
            }
            else {
                XCTFail("Failed to decode String to a Date: \(String(describing: objectValue))")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_StringArray_Codable() {
        do {
            let expectedObject = ["alpha", "beta", "gamma"]
            let expectedJson = ["alpha", "beta", "gamma"]
            let inputJson: RSDJSONSerializable = ["alpha", "beta", "gamma"]
            
            let answerType = RSDAnswerResultType(baseType: .string, sequenceType: .array)
            let objectValue = try answerType.jsonDecode(from: inputJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [String], expectedObject)
            XCTAssertEqual(jsonValue as? [String], expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_IntegerArray_Codable() {
        do {
            let expectedObject = [65, 47, 99]
            let expectedJson = [65, 47, 99]
            let inputJson: RSDJSONSerializable = [65, 47, 99]
            
            let answerType = RSDAnswerResultType(baseType: .integer, sequenceType: .array)
            let objectValue = try answerType.jsonDecode(from: inputJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [Int], expectedObject)
            XCTAssertEqual(jsonValue as? [Int], expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerResultObject_DoubleArray_Codable() {
        do {
            let expectedObject = [65.3, 47.2, 99.8]
            let expectedJson = [65.3, 47.2, 99.8]
            let inputJson: RSDJSONSerializable = [65.3, 47.2, 99.8]
            
            let answerType = RSDAnswerResultType(baseType: .decimal, sequenceType: .array)
            let objectValue = try answerType.jsonDecode(from: inputJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [Double], expectedObject)
            XCTAssertEqual(jsonValue as? [Double], expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testAnswerResultObject_FractionArray_Codable() {
        do {
            let expectedObject = [RSDFraction(floatLiteral: 0.25), RSDFraction(floatLiteral: 0.5), RSDFraction(floatLiteral: 0.75)]
            let expectedJson = [0.25, 0.5, 0.75]
            let inputJson: RSDJSONSerializable = [0.25, 0.5, 0.75]
            
            let answerType = RSDAnswerResultType(baseType: .decimal, sequenceType: .array, formDataType: .collection(.multipleChoice, .fraction))
            let objectValue = try answerType.jsonDecode(from: inputJson)
            let jsonValue = try answerType.jsonEncode(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [RSDFraction], expectedObject)
            XCTAssertEqual(jsonValue as? [Double], expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
}
