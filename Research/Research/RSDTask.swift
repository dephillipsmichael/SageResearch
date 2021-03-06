//
//  RSDTask.swift
//  Research
//
//  Copyright © 2017-2018 Sage Bionetworks. All rights reserved.
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

/// `RSDTask` is the interface for running a task. It includes information about how to calculate progress,
/// validation, and the order of display for the steps.
///
/// - seealso: `RSDTaskController` and `RSDTaskInfoStep`
public protocol RSDTask : RSDUIActionHandler {
    
    /// A short string that uniquely identifies the task.
    var identifier: String { get }
    
    /// Additional information about the result schema.
    var schemaInfo: RSDSchemaInfo? { get }
    
    /// Copyright information for the task.
    var copyright: String? { get }
    
    /// The step navigator for this task.
    var stepNavigator: RSDStepNavigator { get }
    
    /// A list of asynchronous actions to run on the task.
    var asyncActions: [RSDAsyncActionConfiguration]? { get }
    
    /// Instantiate a task result that is appropriate for this task.
    ///
    /// - returns: A task result for this task.
    func instantiateTaskResult() -> RSDTaskResult

    /// Validate the task to check for any model configuration that should throw an error.
    /// - throws: An error appropriate to the failed validation.
    func validate() throws
}

extension RSDTask {
    
    /// Filter the `asyncActions` and return only those actions to start with this step. This will return the
    /// configurations where the `startStepIdentifier` matches the current step as well as configurations
    /// where the `startStepIdentifier` is `nil` if and only if `isFirstStep` equals `true`.
    ///
    /// - parameters:
    ///     - step:         The step that is about to be displayed.
    ///     - isFirstStep:  `true` if this is the first step in the task, otherwise `false`.
    /// - returns: The array of async actions to start.
    public func asyncActionsToStart(at step: RSDStep, isFirstStep: Bool) -> [RSDAsyncActionConfiguration] {
        guard let actions = self.asyncActions else { return [] }
        return actions.filter {
            ($0.startStepIdentifier == step.identifier) || ($0.startStepIdentifier == nil && isFirstStep)
        }
    }
}

/// An extension of the task to allow replacing the step navigator or inserting async actions.
///
/// - seealso: `RSDCopyStepNavigator`
public protocol RSDCopyTask : RSDTask, RSDCopyWithIdentifier, RSDTaskTransformer {
    
    /// Copy the step to a new instance with the given identifier, but otherwise, equal.
    /// - parameters:
    ///     - identifier: The new identifier.
    ///     - schemaInfo: The schema info.
    func copy(with identifier: String, schemaInfo: RSDSchemaInfo?) -> Self
    
    /// Return a copy of the task that includes the async action.
    /// - parameter asyncAction: The async action configuration to insert.
    func copyAndInsert(_ asyncAction: RSDAsyncActionConfiguration) -> Self
    
    /// Return a copy of the task that replaces the step navigator with the new copy.
    /// - parameter stepNavigator: The step navigator to insert.
    func copyAndReplace(_ stepNavigator: RSDStepNavigator) -> Self
}

extension RSDCopyTask {
    
    /// Returns `0`.
    public var estimatedFetchTime: TimeInterval {
        return 0
    }
    
    /// Fetch the task for this task info. Use the given factory to transform the task.
    ///
    /// - parameters:
    ///     - factory: The factory to use for creating the task and steps.
    ///     - taskIdentifier: The task info for the task (if applicable).
    ///     - schemaInfo: The schema info for the task (if applicable).
    ///     - callback: The callback with the task or an error if the task failed, run on the main thread.
    public func fetchTask(with factory: RSDFactory, taskIdentifier: String, schemaInfo: RSDSchemaInfo?, callback: @escaping RSDTaskFetchCompletionHandler) {
        DispatchQueue.main.async {
            let copy = self.copy(with: taskIdentifier, schemaInfo: schemaInfo)
            callback(taskIdentifier, copy, nil)
        }
    }
}
