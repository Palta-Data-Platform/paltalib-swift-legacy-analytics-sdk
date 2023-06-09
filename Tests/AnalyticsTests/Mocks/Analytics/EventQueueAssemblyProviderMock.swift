//
//  EventQueueAssemblyProviderMock.swift
//  PaltaLibAnalytics
//
//  Created by Vyacheslav Beltyukov on 18/05/2022.
//

import Foundation
import PaltaCore
@testable import PaltaLibAnalytics

final class EventQueueAssemblyProviderMock: EventQueueAssemblyProvider {
    func newEventQueueAssembly() throws -> EventQueueAssembly {
        try .init(coreAssembly: .init(), analyticsCoreAssembly: .init(coreAssembly: .init()))
    }
}
