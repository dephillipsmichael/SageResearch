//
//  RSDMotionAuthorization.swift
//  Research (iOS)
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
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
import CoreMotion

fileprivate let _userDefaultsKey = "rsd_MotionAuthorizationStatus"

/// `RSDMotionAuthorization` is a wrapper for the CoreMotion library that allows a general-purpose
/// step or task to query this library for authorization if and only if that library is required by the
/// application.
///
/// - seealso: `RSDPermissionsStepViewController`
public class RSDMotionAuthorization {
    
    /// Returns authorization status for `.motion` permission.
    public static func authorizationStatus() -> RSDAuthorizationStatus {
        return _cachedAuthorizationStatus()
    }
    
    /// Looks for a cached value and returns that if found.
    private static func _cachedAuthorizationStatus() -> RSDAuthorizationStatus {
        if let cachedStatus = UserDefaults.standard.object(forKey: _userDefaultsKey) as? NSNumber {
            return cachedStatus.boolValue ? .authorized : .previouslyDenied
        } else {
            return .notDetermined
        }
    }
    
    /// Retain the pedometer while it's being queried.
    private static var pedometer: CMPedometer?

    /// Request authorization for access to the motion and fitness sensors.
    static public func requestAuthorization(_ completion: @escaping ((RSDAuthorizationStatus, Error?) -> Void)) {
        
        // Request permission to use the pedometer.
        pedometer = CMPedometer()
        let now = Date()
        pedometer!.queryPedometerData(from: now.addingTimeInterval(-2*60), to: now) { (_, error) in
            DispatchQueue.main.async {
                // Brittle work-around for limitations of getting "motion & fitness" authorization status. The 104 code is sometimes thrown
                // even if the app has the proper permissions. Ignore it. syoung 03/22/2018
                if let err = error, (err as NSError).code != 104 {
                    debugPrint("Failed to query pedometer: \(err)")
                    setCachedAuthorization(false)
                    let error = RSDPermissionError.notAuthorized(.motion, .denied)
                    completion(.denied, error)
                } else {
                    pedometer = nil
                    setCachedAuthorization(true)
                    completion(.authorized, nil)
                }
            }
        }
    }
    
    /// Set the state of the cached authorization.
    static func setCachedAuthorization(_ authorized: Bool) {
        UserDefaults.standard.set(authorized, forKey: _userDefaultsKey)
    }
}
