//
//  KeyValueObserver.swift
//  Example-iOS
//
//  Created by Prachi Gauriar on 7/6/2016.
//  Copyright © 2016 Ticketmaster Entertainment, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation


/// Instances of `KeyValueObserver` make it easy to use KVO without manually registering for 
/// change notifications or overriding `observeValueForKeyPath(_:ofObject:change:context:)`.
/// Upon creating a `KeyValueObserver` object, it automatically starts observing the key path
/// specified and executes its change block whenever a change is observed. When the instance
/// is deallocated, it automatically stops observing the specified key path.
class KeyValueObserver<ObservedType: NSObject> : NSObject {
    /// The object being observed.
    private let object: ObservedType

    /// The key path being observed.
    private let keyPath: String

    /// The block to invoke whenever a change is observed.
    private let changeBlock: (ObservedType) -> ()

    /// A private context variable for use when registering and deregistering from KVO
    private var context = 0

    
    /// Initializes a newly created `KeyValueObserver` instance with the specified object,
    /// key path, key-value observing options, and change block. Upon completion of this
    /// method, the new instance will be observing change notifications for the specified
    /// object and key path.
    ///
    /// - parameter object: The object to observe
    /// - parameter keyPath: The key path to observe
    /// - parameter options: The key-value observing options to use when registering for
    ///     change notifications
    /// - parameter changeBlock: The block to invoke whenever a change is observed
    init(object: ObservedType,
         keyPath: String,
         options: NSKeyValueObservingOptions = .initial,
         changeBlock: @escaping (ObservedType) -> ()) {
        self.object = object
        self.keyPath = keyPath
        self.changeBlock = changeBlock

        super.init()

        object.addObserver(self, forKeyPath: keyPath, options: options, context: &context)
    }


    deinit {
        object.removeObserver(self, forKeyPath: keyPath, context: &context)
    }


    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        changeBlock(self.object)
    }
}
