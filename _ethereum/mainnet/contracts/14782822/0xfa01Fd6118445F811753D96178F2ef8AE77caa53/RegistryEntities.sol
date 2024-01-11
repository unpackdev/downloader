// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library RegistryEntities {
    struct ProtocolParametersArgs {
        // Period of time after which ticker could be canceled if no data was provided to the `oracleId`
        uint32 noDataCancellationPeriod;
        // Max fee that derivative author can set
        // it works as an upper bound for when the derivative authors set their synthetic's fee
        uint32 derivativeAuthorExecutionFeeCap;
        // Fixed part (percentage) that the derivative author receives for each redemption of market neutral positions
        // It is not set by the derivative authors themselves
        uint32 derivativeAuthorRedemptionReservePart;
        // Represents which part of derivative author reserves originated from derivative executions go to the protocol reserves
        uint32 protocolExecutionReservePart;
        // Represents which part of derivative author reserves originated from redemption of market neutral positions go to the protocol reserves
        uint32 protocolRedemptionReservePart;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
        uint32 __gapThree;
    }

    struct ProtocolAddressesArgs {
        // Address of Opium.Core contract
        address core;
        // Address of Opium.OpiumProxyFactory contract
        address opiumProxyFactory;
        // Address of Opium.OracleAggregator contract
        address oracleAggregator;
        // Address of Opium.SyntheticAggregator contract
        address syntheticAggregator;
        // Address of Opium.TokenSpender contract
        address tokenSpender;
        // Address of the recipient of execution protocol reserves
        address protocolExecutionReserveClaimer;
        // Address of the recipient of redemption protocol reserves
        address protocolRedemptionReserveClaimer;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
    }

    struct ProtocolPausabilityArgs {
        // if true, all the protocol's entry-points are paused
        bool protocolGlobal;
        // if true, no new positions can be created
        bool protocolPositionCreation;
        // if true, no new positions can be minted
        bool protocolPositionMinting;
        // if true, no new positions can be redeemed
        bool protocolPositionRedemption;
        // if true, no new positions can be executed
        bool protocolPositionExecution;
        // if true, no new positions can be cancelled
        bool protocolPositionCancellation;
        // if true, no reserves can be claimed
        bool protocolReserveClaim;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        bool __gapOne;
        bool __gapTwo;
        bool __gapThree;
        bool __gapFour;
    }
}
