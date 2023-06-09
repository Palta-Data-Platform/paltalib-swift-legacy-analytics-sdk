//
//  AnalyticsCoreAssembly.swift
//  PaltaLibTests
//
//  Created by Vyacheslav Beltyukov on 11.04.2022.
//

import Foundation
import PaltaCore

final class AnalyticsCoreAssembly {
    let trackingOptionsProvider: TrackingOptionsProviderImpl
    let userPropertiesKeeper: UserPropertiesKeeperImpl
    let sessionManager: SessionManagerImpl
    let configurationService: ConfigurationService
    
    init(coreAssembly: CoreAssembly) {
        let trackingOptionsProvider = TrackingOptionsProviderImpl()

        let userPropertiesKeeper = UserPropertiesKeeperImpl(
            trackingOptionsProvider: trackingOptionsProvider,
            deviceInfoProvider: DeviceInfoProviderImpl(),
            userDefaults: .standard
        )
        userPropertiesKeeper.generateDeviceId()

        let sessionManager = SessionManagerImpl(
            userDefaults: .standard,
            notificationCenter: .default
        )

        let configurationService = ConfigurationService(
            userDefaults: .standard,
            httpClient: coreAssembly.httpClient
        )
        
        self.trackingOptionsProvider = trackingOptionsProvider
        self.userPropertiesKeeper = userPropertiesKeeper
        self.sessionManager = sessionManager
        self.configurationService = configurationService
    }
}
