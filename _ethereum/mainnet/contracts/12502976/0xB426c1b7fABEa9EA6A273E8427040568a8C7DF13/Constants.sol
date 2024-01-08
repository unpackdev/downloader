/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant TARGET_SUPPLY = 25e24; // 25M DAIQ
    uint256 private constant BOOTSTRAPPING_PRICE = 154e16; // 1.54 DAI (targeting 4.5% inflation)

    /* Oracle */
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e22; // 10,000 DAI

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 DAIQ -> 100M DAIQS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 minPeriod;
        uint256 maxPeriod;
    }

    uint256 private constant EPOCH_OFFSET = 86400; //1 day
    uint256 private constant EPOCH_MIN_PERIOD = 1800; //30 minutes
    uint256 private constant EPOCH_MAX_PERIOD = 7200; //2 hours

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 13;
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 3; // 3 epochs

    /* DAO */
    uint256 private constant DAI_ADVANCE_INCENTIVE_CAP = 150e18; //150 DAI
    uint256 private constant ADVANCE_INCENTIVE = 100e18; // 100 DAIQ
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 0; // 24 epochs fluid

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 0; // 12 epochs fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 360;
    uint256 private constant DEBT_RATIO_CAP = 40e16; // 40%
    uint256 private constant INITIAL_COUPON_REDEMPTION_PENALTY = 50e16; // 50%

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 12e18; // 12
    uint256 private constant SUPPLY_CHANGE_LIMIT = 10e16; // 10%
    uint256 private constant ORACLE_POOL_RATIO = 60; // 60%

    /**
     * Getters
     */
    function getDAIAddress() internal pure returns (address) {
        return DAI;
    }

    function getPairAddress() internal pure returns (address) {
        return address(0x26B4B107dCe673C00D59D71152136327cF6dFEBf);
    }

    function getMultisigAddress() internal pure returns (address) {
        return address(0x7c066d74dd5ff4E0f3CB881eD197d49C96cA1771);
    }

    function getMarketingMultisigAddress() internal pure returns (address) {
        return address(0x0BCbDfd1ab7c2cBb6a8612f3300f214a779cb520);
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: EPOCH_OFFSET,
            minPeriod: EPOCH_MIN_PERIOD,
            maxPeriod: EPOCH_MAX_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingTarget() internal pure returns (Decimal.D256 memory) {
        return Decimal.from(TARGET_SUPPLY);
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getDaiAdvanceIncentiveCap() internal pure returns (uint256) {
        return DAI_ADVANCE_INCENTIVE_CAP;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    
    function getInitialCouponRedemptionPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: INITIAL_COUPON_REDEMPTION_PENALTY});
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }
}
