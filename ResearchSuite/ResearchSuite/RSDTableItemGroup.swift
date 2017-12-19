//
//  RSDTableItemGroup.swift
//  ResearchSuite
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

import Foundation

/// `RSDTableItemGroup` is a generic table item group object that can be used to display information in a tableview
/// that does not have an associated input field.
open class RSDTableItemGroup {
    
    /// The list of items (or rows) included in this group. A table group can be used to represent one or more rows.
    public let items: [RSDTableItem]
    
    /// The row index for the first row in the group.
    public let beginningRowIndex: Int
    
    /// A unique identifier that can be used to track the group.
    public let uuid = UUID()
    
    /// Determine if the current answer is valid. Also checks the case where answer is required but one has not
    /// been provided.
    public var isAnswerValid: Bool {
        return true
    }
    
    /// Default initializer.
    /// - parameters:
    ///     - beginningRowIndex: The row index for the first row in the group.
    ///     - items: The list of items (or rows) included in this group.
    public init(beginningRowIndex: Int, items: [RSDTableItem]) {
        self.beginningRowIndex = beginningRowIndex
        self.items = items
    }
}

/// `RSDInputFieldTableItemGroup` is used to represent a single input field.
open class RSDInputFieldTableItemGroup : RSDTableItemGroup {
    
    /// The input field associated with this item group.
    public let inputField: RSDInputField
    
    /// The UI hint for displaying the component of the item group.
    public let uiHint: RSDFormUIHint
    
    /// The answer type for the input field result.
    public let answerType: RSDAnswerResultType
    
    /// Default initializer.
    /// - parameters:
    ///     - beginningRowIndex: The first row of the item group.
    ///     - items: The table items included in this item group.
    ///     - inputField: The input field associated with this item group.
    ///     - uiHint: The UI hint.
    ///     - answerType: The answer type.
    public init(beginningRowIndex: Int, items: [RSDTableItem], inputField: RSDInputField, uiHint: RSDFormUIHint, answerType: RSDAnswerResultType) {
        self.inputField = inputField
        self.uiHint = uiHint
        self.answerType = answerType
        super.init(beginningRowIndex: beginningRowIndex, items: items)
    }
    
    /// Convenience initializer.
    /// - parameters:
    ///     - beginningRowIndex: The first row of the item group.
    ///     - tableItem: A single table item that can be used to build an answer.
    public init(beginningRowIndex: Int, tableItem: RSDTextInputTableItem) {
        self.inputField = tableItem.inputField
        self.uiHint = tableItem.uiHint
        self.answerType = tableItem.answerType
        super.init(beginningRowIndex: beginningRowIndex, items: [tableItem])
    }
    
    /// Convenience property for accessing the identifier associated with the item group.
    public var identifier: String {
        return inputField.identifier
    }
    
    /// The answer for this item group. This is the answer stored to the `RSDAnswerResult`. The default implementation will
    /// return the privately stored answer if set and if not, will look to see if the first table item is recognized as a table item
    /// that stores an answer on it.
    open var answer: Any {
        return _answer ?? (self.items.first as? RSDTextInputTableItem)?.answer ?? NSNull()
    }
    private var _answer: Any?
    
    /// Set the new answer value. This will throw an error if the value isn't valid. Otherwise, it will
    /// set the answer.
    /// - parameter newValue: The new value for the answer.
    /// - throws: `RSDInputFieldError` if the answer is invalid.
    open func setAnswer(_ newValue: Any?) throws {
        
        // Only validation at this level is on a single-input field. Otherwise, just set the answer and return
        guard self.items.count == 1, let textItem = self.items.first as? RSDTextInputTableItem
            else {
                _answer = newValue
                return
        }
        
        // If there is a single-input field then set the answer on that field
        try textItem.setAnswer(newValue)
    }
    
    /// Set the new answer value from a previous result. This will throw an error if the result isn't valid.
    /// Otherwise, it will set the answer.
    /// - parameter result: The result that *may* have a previous answer.
    /// - throws: `RSDInputFieldError` if the answer is invalid.
    open func setAnswer(from result: RSDResult) throws {
        guard let answerResult = result as? RSDAnswerResult,
            answerResult.answerType == answerType
            else {
                let context = RSDInputFieldError.Context(identifier: inputField.identifier, value: answer, answerResult: answerType, debugDescription: "Result answer type for \(result) not expected type.")
                throw RSDInputFieldError.invalidType(context)
        }
        try self.setAnswer(answerResult.value)
    }
    
    /// Determine if the current answer is valid. Also checks the case where answer is required but one has
    /// not been provided.
    /// - returns: A `Bool` indicating if answer is valid.
    open override var isAnswerValid: Bool {
        // if answer is NOT optional and it equals Null, then it's invalid
        let isOptional = self.items.reduce(self.inputField.isOptional) {
            $0 && (($1 as? RSDInputFieldTableItem)?.inputField.isOptional ?? true)
        }
        return isOptional || !(self.answer is NSNull)
    }
}

/// `RSDChoicePickerTableItemGroup` subclasses `RSDInputFieldTableItemGroup` to implement a single or multiple choice
/// question where the choices are presented as a list.
open class RSDChoicePickerTableItemGroup : RSDInputFieldTableItemGroup {
    
    /// Does the item group allow for multiple choices or is it single selection?
    public let singleSelection: Bool
    
    /// Default initializer.
    /// - parameters:
    ///     - beginningRowIndex: The first row of the item group.
    ///     - inputField: The input field associated with this item group.
    ///     - uiHint: The UI hint.
    ///     - choicePicker: The choice picker data source.
    ///     - answerType: The answer type.
    public init(beginningRowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint, choicePicker: RSDChoicePickerDataSource, answerType: RSDAnswerResultType? = nil) {

        // Set the items
        var items: [RSDTableItem]?
        var singleSelection: Bool = true
        if inputField.dataType.listSelectionHints.contains(uiHint),
            let choicePicker = choicePicker as? RSDChoiceOptions {
            if case .collection(let collectionType, _) = inputField.dataType, collectionType == .multipleChoice {
                singleSelection = false
            }
            items = choicePicker.choices.enumerated().map { (index, choice) -> RSDTableItem in
                RSDChoiceTableItem(rowIndex: beginningRowIndex + index, inputField: inputField, uiHint: uiHint, choice: choice)
            }
        }
        self.singleSelection = singleSelection

        // Setup the answer type if nil
        let aType: RSDAnswerResultType = answerType ?? {
            let baseType: RSDAnswerResultType.BaseType = inputField.dataType.defaultAnswerResultBaseType()
            let sequenceType: RSDAnswerResultType.SequenceType? = singleSelection ? nil : .array
            let dateFormatter: DateFormatter? = (inputField.range as? RSDDateRange)?.dateCoder?.resultFormatter
            let unit: String? = (inputField.range as? RSDNumberRange)?.unit
            return RSDAnswerResultType(baseType: baseType, sequenceType: sequenceType, dateFormat: dateFormatter?.dateFormat, unit: unit, sequenceSeparator: nil)
        }()
        
        // If this is being used as a picker source, then setup the picker
        if items == nil {
            items = [RSDTextInputTableItem(rowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint, answerType: aType)]
        }
        
        super.init(beginningRowIndex: beginningRowIndex, items: items!, inputField: inputField, uiHint: uiHint, answerType: aType)
    }
    
    // Override to set the selected items from the result.
    override open func setAnswer(from result: RSDResult) throws {
        try super.setAnswer(from: result)
        
        // Set all the previously selected items as selected
        guard let selectableItems = self.items as? [RSDChoiceTableItem] else { return }
        for input in selectableItems {
            input.selected = input.choice.isEqualToResult(result)
        }
    }
    
    /// Select or de-select an item (answer) at a specific indexPath. This is used for text choice and boolean answers.
    /// - parameters:
    ///     - selected:   A `Bool` indicating if the item should be selected.
    ///     - indexPath:  The IndexPath of the item.
    open func select(_ item: RSDChoiceTableItem, indexPath: IndexPath) throws {
        guard let selectableItems = self.items as? [RSDChoiceTableItem] else {
            let context = RSDInputFieldError.Context(identifier: inputField.identifier, value: nil, answerResult: answerType, debugDescription: "This input field does not support selection.")
            throw RSDInputFieldError.invalidType(context)
        }
        
        // To get the index of our item, add our `beginningRowIndex` to `indexPath.row`.
        let deselectOthers = singleSelection || item.choice.isExclusive
        let index =  indexPath.row - beginningRowIndex
        let selected = !item.selected
        
        // If we selected an item and this is a single-selection group, then we iterate
        // our other items and de-select them.
        var answers: [Any] = []
        for (ii, input) in selectableItems.enumerated() {
            if deselectOthers || (ii == index) || input.choice.isExclusive || (input.choice.value == nil) {
                input.selected = (ii == index) && selected
            }
            if input.selected, let value = input.choice.value {
                answers.append(value)
            }
        }
        
        // Set the answer array
        if singleSelection {
            try setAnswer(answers.first)
        } else {
            try setAnswer(answers)
        }
    }
}

/// An item group for entering text.
final class RSDTextFieldTableItemGroup : RSDInputFieldTableItemGroup {
    
    public init(beginningRowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint) {
        let tableItem = RSDTextInputTableItem(rowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint)
        super.init(beginningRowIndex: beginningRowIndex, tableItem: tableItem)
    }
}

/// An item group for entering a boolean data type.
final class RSDBooleanTableItemGroup : RSDChoicePickerTableItemGroup {
    
    public init(beginningRowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint) {
        
        let choicePicker: RSDChoicePickerDataSource
        if let picker = inputField as? RSDChoicePickerDataSource {
            choicePicker = picker
        } else {
            // TODO: syoung 10/20/2017 Implement Boolean formatter
            let choiceYes = try! RSDChoiceObject<Bool>(value: true, text: nil, iconName: nil, detail: nil, isExclusive: true)
            let choiceNo = try! RSDChoiceObject<Bool>(value: false, text: nil, iconName: nil, detail: nil, isExclusive: true)
            choicePicker = RSDChoiceOptionsObject(choices: [choiceYes, choiceNo], isOptional: inputField.isOptional)
        }
        let answerType = RSDAnswerResultType(baseType: .boolean)
        
        super.init(beginningRowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint, choicePicker: choicePicker, answerType: answerType)
    }
}

/// An item group for entering a date.
final class RSDDateTableItemGroup : RSDInputFieldTableItemGroup {
    
    public init(beginningRowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint) {
        
        var pickerSource: RSDPickerDataSource? = inputField as? RSDPickerDataSource
        var formatter: Formatter? = (inputField.range as? RSDRangeWithFormatter)?.formatter
        var dateFormatter: DateFormatter?
        
        if let dateRange = inputField.range as? RSDDateRange {
            let (src, fmt) = dateRange.dataSource()
            pickerSource = pickerSource ?? src
            formatter = formatter ?? fmt
            dateFormatter = dateRange.dateCoder?.resultFormatter
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            formatter = formatter ?? dateFormatter
            pickerSource = pickerSource ?? RSDDatePickerDataSourceObject(datePickerMode: .dateAndTime, minimumDate: nil, maximumDate: nil, minuteInterval: nil, dateFormatter: dateFormatter)
        }
        
        let answerType = RSDAnswerResultType(baseType: .date, sequenceType: nil, dateFormat: dateFormatter?.dateFormat, unit: nil, sequenceSeparator: nil)

        // TODO: syoung 12/19/2017 Refactor to use an array of RSDNumberInputTableItem to represent the
        // entry if the preferred uiHint is a text field (rather than a picker).
        let tableItem = RSDTextInputTableItem(rowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint, answerType: answerType, textFieldOptions: nil, formatter: formatter, pickerSource: pickerSource)
        
        super.init(beginningRowIndex: beginningRowIndex, tableItem: tableItem)
    }
}

/// An item group for entering a number value.
final class RSDNumberTableItemGroup : RSDInputFieldTableItemGroup {
    
    public init(beginningRowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint) {
        let tableItem = RSDNumberInputTableItem(rowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint)
        super.init(beginningRowIndex: beginningRowIndex, tableItem: tableItem)
    }
}

/// An item group for entering data requiring a multiple component format.
final class RSDMultipleComponentTableItemGroup : RSDInputFieldTableItemGroup {
    
    public init(beginningRowIndex: Int, inputField: RSDMultipleComponentInputField, uiHint: RSDFormUIHint) {
        
        let baseType: RSDAnswerResultType.BaseType = inputField.dataType.defaultAnswerResultBaseType()
        let dateFormatter: DateFormatter? = (inputField.range as? RSDDateRange)?.dateCoder?.resultFormatter
        let unit: String? = (inputField.range as? RSDNumberRange)?.unit
        let answerType = RSDAnswerResultType(baseType: baseType, sequenceType: .array, dateFormat: dateFormatter?.dateFormat, unit: unit, sequenceSeparator: inputField.separator)
        let tableItem = RSDTextInputTableItem(rowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint, answerType: answerType, textFieldOptions: nil, formatter: nil, pickerSource: inputField)
    
        // TODO: syoung 12/19/2017 Refactor to use an array of RSDTextInputTableItem objects to represent the
        // entry if the preferred uiHint is a text field (rather than a picker).
        super.init(beginningRowIndex: beginningRowIndex, tableItem: tableItem)
    }
}

/// An item group for entering data that is a human-measurement in localized units appropriate to the
/// size-range of the human (adult, child, infant).
final class RSDMeasurementTableItemGroup : RSDInputFieldTableItemGroup {
    
    public init(beginningRowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint) {
        
        var formatter: Formatter? = (inputField.range as? RSDRangeWithFormatter)?.formatter
        let baseType: RSDAnswerResultType.BaseType = .decimal
        var unit: String?
        var sequenceType: RSDAnswerResultType.SequenceType?
        var sequenceSeparator: String?
        
        if case .measurement(let measurementType, _) = inputField.dataType {
            switch measurementType {
            case .height:
                let lengthFormatter = LengthFormatter()
                lengthFormatter.isForPersonHeightUse = true
                formatter = formatter ?? lengthFormatter
                unit = unit ?? "cm"
                
            case .weight:
                let massFormatter = MassFormatter()
                massFormatter.isForPersonMassUse = true
                formatter = formatter ?? massFormatter
                unit = unit ?? "kg"
                
            case .bloodPressure:
                // TODO: syoung 12/19/2017 Refactor to use an array of RSDTextInputTableItem objects to represent the
                // entry if the preferred uiHint is a text field (rather than a picker).
                sequenceType = .array
                sequenceSeparator = "/"
            }
        } else {
            fatalError("Cannot instantiate a measurement type item group without a base data type")
        }
        
        let answerType = RSDAnswerResultType(baseType: baseType, sequenceType: sequenceType, dateFormat: nil, unit: unit, sequenceSeparator: sequenceSeparator)
        let pickerSource: RSDPickerDataSource = (inputField as? RSDPickerDataSource) ?? RSDMeasurementPickerDataSourceObject(dataType: inputField.dataType, unit: unit, formatter: formatter)
        
        let tableItem = RSDTextInputTableItem(rowIndex: beginningRowIndex, inputField: inputField, uiHint: uiHint, answerType: answerType, textFieldOptions: nil, formatter: formatter, pickerSource: pickerSource)
        
        super.init(beginningRowIndex: beginningRowIndex, tableItem: tableItem)
    }
}
