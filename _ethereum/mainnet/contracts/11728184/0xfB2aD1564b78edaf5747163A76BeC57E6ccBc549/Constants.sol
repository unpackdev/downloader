/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

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
    // QSD #3
    uint256 private constant BOOTSTRAPPING_PERIOD = 72;
    uint256 private constant BOOTSTRAPPING_PRICE = 11e17; // 1.10 DAI

    /* Oracle */
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 10000e18; // 10,000 DAI

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 ESD -> 100M ESDS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant PREVIOUS_EPOCH_OFFSET = 0;
    uint256 private constant PREVIOUS_EPOCH_START = 0;
    uint256 private constant PREVIOUS_EPOCH_PERIOD = 0;

    // QSD #1
    uint256 private constant CURRENT_EPOCH_OFFSET = 0;
    uint256 private constant CURRENT_EPOCH_START =  1612008000;// 2020/01/30 12:00 UTC;
    uint256 private constant CURRENT_EPOCH_PERIOD = 14400; // 4 hours

    /* Governance */
    // QSD #C.a
    uint256 private constant GOVERNANCE_MAX_SUPPLY = 999999999e18; // 999,999,999
    uint256 private constant GOVERNANCE_DISTRIBUTED_PER_BLOCK = 9e16; // 0.09

    // QSD #C.g
    uint256 private constant GOVERNANCE_PERIOD = 9; // 9 epochs
    uint256 private constant GOVERNANCE_EXPIRATION = 2; // 2 + 1 epochs
    uint256 private constant GOVERNANCE_QUORUM = 33e16; // 33%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 9e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 ESD    
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 1; // 1 epochs fluid

    /* Pool */
    // QSD #9
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 1; // 1 epochs fluid

    /* Market */
    uint256 private constant DEBT_RATIO_CAP = 15e16; // 15%

    /* Regulator (post-bootstrap) */
    // QSD #2
    uint256 private constant SUPPLY_CHANGE_LIMIT = 54e15; // 5.4% Expansion/Contraction limit
    uint256 private constant POOL_BONDING_RATIO = 67; // 67%
    uint256 private constant POOL_LP_RATIO = 23; // 23%
    uint256 private constant TREASURY_RATIO = 5; // 5%
    uint256 private constant GOV_STAKING_RATIO = 5; // 5%

    /* External */
    address private constant TREASURY_ADDRESS = address(0x61c32f08B0cbe61feF4166f09363504b4b5F38d8);

    /**
     * Getters
     */

    function getDaiAddress() internal pure returns (address) {
        return DAI;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getPreviousEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: PREVIOUS_EPOCH_OFFSET,
            start: PREVIOUS_EPOCH_START,
            period: PREVIOUS_EPOCH_PERIOD
        });
    }

    function getCurrentEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: CURRENT_EPOCH_OFFSET,
            start: CURRENT_EPOCH_START,
            period: CURRENT_EPOCH_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
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

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }
    
    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getPoolLPRatio() internal pure returns (uint256) {
        return POOL_LP_RATIO;
    }

    function getPoolBondingRatio() internal pure returns (uint256) {
        return POOL_BONDING_RATIO;
    }

    function getGovStakingRatio() internal pure returns (uint256) {
        return GOV_STAKING_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function getGovernanceTokenMaxSupply() internal pure returns (uint256) {
        return GOVERNANCE_MAX_SUPPLY;
    }

    function getGovernanceTokenPerBlock() internal pure returns (uint256) {
        return GOVERNANCE_DISTRIBUTED_PER_BLOCK;
    }
}
