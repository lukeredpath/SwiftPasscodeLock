//
//  EnterPasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

public let PasscodeLockIncorrectPasscodeNotification = Notification.Name("passcode.lock.incorrect.passcode.notification")

struct EnterPasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction: Bool
    var isTouchIDAllowed = true
    
    fileprivate var incorrectPasscodeAttemptsKey = "incorrectPasscodeAttemps"
    private var incorrectPasscodeAttempts: Int {
        get {
            return UserDefaults.standard.integer(forKey: incorrectPasscodeAttemptsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: incorrectPasscodeAttemptsKey)
        }
    }
    var isNotificationSent = false
    
    init(allowCancellation: Bool = false, incorrectPasscodeAttempts: Int = 0, notifiedMaximumAttempts: Bool = false) {
        
        isCancellableAction = allowCancellation
        title = localizedStringFor(key: "PasscodeLockEnterTitle", comment: "Enter passcode title")
        description = localizedStringFor(key: "PasscodeLockEnterDescription", comment: "Enter passcode description")
        isNotificationSent = notifiedMaximumAttempts
        
        self.incorrectPasscodeAttempts = incorrectPasscodeAttempts
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        lock.repository.check(passcode: passcode) { result in
            if result {
                lock.changeState(self.successful())
                lock.delegate?.passcodeLockDidSucceed(lock)
                
            } else {

                lock.changeState(self.failedAttempted(
                    attemptNumber: self.incorrectPasscodeAttempts + 1,
                    maximumPermittedAttempts: lock.configuration.maximumInccorectPasscodeAttempts
                ))
                lock.delegate?.passcodeLockDidFail(lock)
            }
        }
    }
    
    fileprivate func successful() -> PasscodeLockStateType {
        return EnterPasscodeState(allowCancellation: isCancellableAction, incorrectPasscodeAttempts: 0)
    }
    
    fileprivate func failedAttempted(attemptNumber: Int, maximumPermittedAttempts: Int) -> PasscodeLockStateType {
        var notifiedMaximumAttempts = isNotificationSent
        
        if attemptNumber >= maximumPermittedAttempts && !notifiedMaximumAttempts {
            NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
            notifiedMaximumAttempts = true
        }
        return EnterPasscodeState(
            allowCancellation: isCancellableAction,
            incorrectPasscodeAttempts: attemptNumber,
            notifiedMaximumAttempts: notifiedMaximumAttempts
        )
    }
}
