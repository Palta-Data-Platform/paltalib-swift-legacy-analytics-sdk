//
//  BatchSendControllerTests.swift
//  PaltaLibTests
//
//  Created by Vyacheslav Beltyukov on 20/10/2022.
//

import Foundation
import XCTest
import PaltaCore
@testable import PaltaLibAnalytics

final class BatchSendControllerTests: XCTestCase {
    private var composerMock: BatchComposerMock!
    private var storageMock: BatchStorageMock!
    private var senderMock: BatchSenderMock!
    private var timerMock: TimerMock!
    
    private var controller: BatchSendControllerImpl!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        composerMock = .init()
        storageMock = .init()
        senderMock = .init()
        timerMock = .init()
        
        controller = BatchSendControllerImpl(
            batchComposer: composerMock,
            batchStorage: storageMock,
            batchSender: senderMock,
            timer: timerMock
        )
    }
    
    func testSuccessfulSend() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let telemetry: Telemetry = .mock()
        let events: [Event] = (0...10).map { _ in .mock() }
        
        senderMock.result = .success(())
        
        controller.sendBatch(of: events, with: telemetry)
        
        wait(for: [isReadyCalled], timeout: 0.1)
        
        XCTAssertEqual(Set(composerMock.events ?? []), Set(events))
        XCTAssertEqual(composerMock.telemetry, telemetry)
        XCTAssertNotNil(senderMock.batch)
        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testSequentalSend() {
        controller.configurationFinished()

        let isReadyNotCalled = expectation(description: "Is Ready called")
        isReadyNotCalled.isInverted = true
        controller.isReadyCallback = isReadyNotCalled.fulfill
        
        let events1 = [Event.mock()]
        let events2 = [Event.mock()]
        
        controller.sendBatch(of: events1, with: .mock())
        
        composerMock.events = nil
        composerMock.telemetry = nil
        senderMock.batch = nil
        storageMock.savedBatch = nil
        
        controller.sendBatch(of: events2, with: .mock())
        
        wait(for: [isReadyNotCalled], timeout: 0.1)
        
        XCTAssertNil(composerMock.events)
        XCTAssertNil(senderMock.batch)
        XCTAssertNil(storageMock.savedBatch)
        XCTAssertFalse(controller.isReady)
    }
    
    func testUnknownError() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.unknown)
        
        controller.sendBatch(of: events, with: .mock())
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testSerializationError() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.badRequest)
        
        controller.sendBatch(of: events, with: .mock())
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testServerError() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.serverError(500))
        
        controller.sendBatch(of: events, with: .mock())
        
        XCTAssertNotNil(timerMock.passedInterval)
        XCTAssertFalse(storageMock.batchRemoved)
        XCTAssertFalse(controller.isReady)
        
        senderMock.result = .success(())
        timerMock.fire()
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testNoInternet() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.noInternet)
        
        controller.sendBatch(of: events, with: .mock())
        
        XCTAssertNotNil(timerMock.passedInterval)
        XCTAssertFalse(storageMock.batchRemoved)
        XCTAssertFalse(controller.isReady)
        
        senderMock.result = .success(())
        timerMock.fire()
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testTimeoutError() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.timeout)
        
        controller.sendBatch(of: events, with: .mock())
        
        XCTAssertNotNil(timerMock.passedInterval)
        XCTAssertFalse(storageMock.batchRemoved)
        XCTAssertFalse(controller.isReady)
        
        senderMock.result = .success(())
        timerMock.fire()
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testURLError() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.otherNetworkError(.cannotCreateFile))
        
        controller.sendBatch(of: events, with: .mock())
        
        XCTAssertNotNil(timerMock.passedInterval)
        XCTAssertFalse(storageMock.batchRemoved)
        XCTAssertFalse(controller.isReady)
        
        senderMock.result = .success(())
        timerMock.fire()
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testNotConfiguredError() {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(.notConfigured)
        
        controller.sendBatch(of: events, with: .mock())
        
        XCTAssertNotNil(timerMock.passedInterval)
        XCTAssertFalse(storageMock.batchRemoved)
        XCTAssertFalse(controller.isReady)
        
        senderMock.result = .success(())
        timerMock.fire()
        
        wait(for: [isReadyCalled], timeout: 0.1)

        XCTAssertNotNil(storageMock.savedBatch)
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testSendOldBatch() {
        storageMock.batchToLoad = .mock()
        senderMock.result = .failure(.noInternet)
        
        controller.configurationFinished()
        
        XCTAssertFalse(controller.isReady)
        XCTAssertNil(composerMock.events)
        XCTAssertNil(composerMock.telemetry)
        XCTAssertNotNil(senderMock.batch)
        
        senderMock.result = .success(())
        let isReadyCalled = expectation(description: "Is Ready called")
        controller.isReadyCallback = isReadyCalled.fulfill
        timerMock.fire()
        
        wait(for: [isReadyCalled], timeout: 0.1)
        
        XCTAssert(storageMock.batchRemoved)
        XCTAssert(controller.isReady)
    }
    
    func testNoSendWithoutConfig() {
        let isReadyCalled = expectation(description: "Is Ready called")
        isReadyCalled.isInverted = true
        controller.isReadyCallback = isReadyCalled.fulfill
        
        XCTAssertFalse(controller.isReady)
        
        let events = [Event.mock()]
        
        senderMock.result = .success(())
        
        controller.sendBatch(of: events, with: .mock())
        
        wait(for: [isReadyCalled], timeout: 0.1)
        
        XCTAssertNil(senderMock.batch)
        XCTAssertFalse(storageMock.batchRemoved)
        XCTAssertFalse(controller.isReady)
    }
    
    func testMaxRetryOnNoInternet() {
        checkRetryLimit(for: .noInternet, shouldLimit: false)
    }
    
    func testMaxRetryOnTimeout() {
        checkRetryLimit(for: .timeout, shouldLimit: true)
    }
    
    func testMaxRetryOnDNS() {
        checkRetryLimit(for: .dnsError(.unknown), shouldLimit: true)
    }
    
    func testMaxRetryOnSSL() {
        checkRetryLimit(for: .sslError(.unknown), shouldLimit: true)
    }
    
    func testMaxRetryOnRequiresHttps() {
        checkRetryLimit(for: .requiresHttps, shouldLimit: false)
    }

    func testMaxRetryOnCantConnectHost() {
        checkRetryLimit(for: .cantConnectToHost, shouldLimit: false)
    }

    func testMaxRetryOnBadResponse() {
        checkRetryLimit(for: .badResponse, shouldLimit: true)
    }

    func testMaxRetryOnServerError() {
        checkRetryLimit(for: .serverError(500), shouldLimit: true)
    }
    
    func testMaxRetryOnConfigMissing() {
        checkRetryLimit(for: .notConfigured, shouldLimit: false)
    }
    
    private func checkRetryLimit(for error: CategorisedNetworkError, shouldLimit: Bool, line: UInt = #line, file: StaticString = #file) {
        controller.configurationFinished()

        let isReadyCalled = expectation(description: "Is Ready called")
        isReadyCalled.isInverted = !shouldLimit
        controller.isReadyCallback = isReadyCalled.fulfill
        
        var retryCount = 0
        
        let events = [Event.mock()]
        
        senderMock.result = .failure(error)
        
        controller.sendBatch(of: events, with: .mock())
        
        repeat {
            timerMock.passedInterval = nil
            timerMock.fireAndWait()
            retryCount += 1
            
            if retryCount > 10 {
                XCTAssert(!shouldLimit, file: file, line: line)
                break
            }
        } while timerMock.passedInterval != nil
        
        XCTAssertEqual(retryCount, shouldLimit ? 10 : 11, file: file, line: line)
        
        wait(for: [isReadyCalled], timeout: 0.1)
        
        if shouldLimit {
            XCTAssert(storageMock.batchRemoved)
            XCTAssert(controller.isReady)
        } else {
            XCTAssertFalse(storageMock.batchRemoved)
            XCTAssertFalse(controller.isReady)
        }
    }
}
