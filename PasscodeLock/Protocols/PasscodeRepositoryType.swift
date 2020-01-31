//
//  PasscodeRepositoryType.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

public typealias PasscodeCheckHandler = (Bool) -> ()

public protocol PasscodeRepositoryType {
    
    var hasPasscode: Bool { get }
    
    func save(passcode: String)
    func check(passcode: String, handler: PasscodeCheckHandler)
    func delete()
}
