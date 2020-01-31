//
//  RemovePasscodeState.swift
//  PasscodeLock
//
//  Created by Kevin Seidel on 06/10/16.
//  Copyright © 2016 Yanko Dimitrov. All rights reserved.
//

import Foundation

struct RemovePasscodeState: PasscodeLockStateType {
    let title: String
    let description: String
    let isCancellableAction = false
    var isTouchIDAllowed: Bool { return false }
    
    private var isNotificationSent = false
    
    fileprivate var incorrectPasscodeAttemptsKey = "incorrectPasscodeAttemps"
    private var incorrectPasscodeAttempts: Int {
        get {
            return UserDefaults.standard.integer(forKey: incorrectPasscodeAttemptsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: incorrectPasscodeAttemptsKey)
        }
    }
    
    init(incorrectPasscodeAttempts: Int = 0, notifiedMaximumAttempts: Bool = false) {
        
        title = localizedStringFor(key: "PasscodeLockEnterTitle", comment: "Enter passcode title")
        description = localizedStringFor(key: "PasscodeLockEnterDescription", comment: "Enter passcode description")
        isNotificationSent = notifiedMaximumAttempts
        
        self.incorrectPasscodeAttempts = incorrectPasscodeAttempts
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        lock.repository.check(passcode: passcode) { result in
            if result {
                lock.repository.delete()
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
        return RemovePasscodeState(incorrectPasscodeAttempts: 0)
    }
    
    fileprivate func failedAttempted(attemptNumber: Int, maximumPermittedAttempts: Int) -> PasscodeLockStateType {
        var notifiedMaximumAttempts = isNotificationSent
        
        if attemptNumber >= maximumPermittedAttempts && !notifiedMaximumAttempts {
            NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
            notifiedMaximumAttempts = true
        }
        return RemovePasscodeState(
            incorrectPasscodeAttempts: attemptNumber,
            notifiedMaximumAttempts: notifiedMaximumAttempts
        )
    }
}
