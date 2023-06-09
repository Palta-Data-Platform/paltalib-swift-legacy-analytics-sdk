//
//  EventMock.swift
//  PaltaLibTests
//
//  Created by Vyacheslav Beltyukov on 01.04.2022.
//

import Foundation
import PaltaCore
@testable import PaltaLibAnalytics

extension Event {
    static let mockUUID = UUID()

    static func mock(uuid: UUID = Event.mockUUID, timestamp: Int? = nil, properties: [String: Any] = [:]) -> Event {
        Event(
            eventType: "event",
            eventProperties: CodableDictionary(properties),
            apiProperties: [:],
            userProperties: [:],
            groups: [:],
            groupProperties: [:],
            sessionId: 1,
            timestamp: timestamp ?? .currentTimestamp(),
            userId: nil,
            deviceId: nil,
            platform: nil,
            appVersion: nil,
            osName: nil,
            osVersion: nil,
            deviceModel: nil,
            deviceManufacturer: nil,
            carrier: nil,
            country: nil,
            language: nil,
            timezone: "GMT+X",
            insertId: uuid,
            sequenceNumber: 0,
            idfa: nil,
            idfv: nil
        )
    }
}

extension Array where Element == Event {
    static func mock(count: Int) -> [Element] {
        (1...count).map { _ in
            Event.mock()
        }
    }
}
