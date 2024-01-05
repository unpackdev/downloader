/*
    Copyright 2020 Dynamic Dollar Devs, based on the works of the Empty Set Squad

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
    uint256 private constant BOOTSTRAPPING_PERIOD = 150; // 150 epochs
    uint256 private constant BOOTSTRAPPING_PRICE = 154e16; // 1.54 USDC (targeting 4.5% inflation)

    /* Oracle */
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC
    uint256 private constant CONTRACTION_ORACLE_RESERVE_MINIMUM = 1e9; // 1,000 USDC

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 DSD -> 100M DSDS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant EPOCH_OFFSET = 0;
    uint256 private constant EPOCH_START = 1606348800;
    uint256 private constant EPOCH_PERIOD = 7200;

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 36;
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE_PREMIUM = 125e16; // pay out 25% more than tx fee value
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 36; // 36 epochs fluid

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 12; // 12 epochs fluid
    address private constant POOL_ADDRESS = address(0xf929fc6eC25850ce00e457c4F28cDE88A94415D8);
    address private constant CONTRACTION_POOL_ADDRESS = address(0x170cec2070399B85363b788Af2FB059DB8Ef8aeD);
    uint256 private constant CONTRACTION_POOL_TARGET_SUPPLY = 10e16; // target 10% of the supply in the CPool
    uint256 private constant CONTRACTION_POOL_TARGET_REWARD = 29e13; // 0.029% per epoch ~ 250% APY with 10% of supply in the CPool


    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 2e16; // 2%
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 25e18; // 25 > Max expansion at 1.5
    uint256 private constant ORACLE_POOL_RATIO = 35; // 35%
    uint256 private constant TREASURY_RATIO = 3; // 3%

    /* Deployed */
    address private constant DAO_ADDRESS = address(0x6Bf977ED1A09214E6209F4EA5f525261f1A2690a);
    address private constant DOLLAR_ADDRESS = address(0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3);
    address private constant CONTRACTION_DOLLAR_ADDRESS = address(0xDe25486CCb4588Ce5D9fB188fb6Af72E768a466a);
    address private constant PAIR_ADDRESS = address(0x26d8151e631608570F3c28bec769C3AfEE0d73a3); // SushiSwap pair
    address private constant CONTRACTION_PAIR_ADDRESS = address(0x4a4572D92Daf14D29C3b8d001A2d965c6A2b1515);
    address private constant TREASURY_ADDRESS = address(0xC7DA8087b8BA11f0892f1B0BFacfD44C116B303e);

    /* DIP-10 */
    uint256 private constant CDSD_REDEMPTION_RATIO = 50; // 50%
    uint256 private constant CONTRACTION_BONDING_REWARDS = 51000000000000; // ~25% APY
    uint256 private constant MAX_CDSD_BONDING_REWARDS = 970000000000000; // 0.097% per epoch -> 2x in 60 * 12 epochs
   
    /* DIP-17 */
    uint256 private constant BASE_EARNABLE_FACTOR = 1e17; // 10% - Minimum Amount of CDSD earnable for DSD burned
    uint256 private constant MAX_EARNABLE_FACTOR = 5e18; // 500% - Maximum Amount of CDSD earnable for DSD burned

    /**
     * Getters
     */
    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getContractionOracleReserveMinimum() internal pure returns (uint256) {
        return CONTRACTION_ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({ offset: EPOCH_OFFSET, start: EPOCH_START, period: EPOCH_PERIOD });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: BOOTSTRAPPING_PRICE });
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: GOVERNANCE_QUORUM });
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: GOVERNANCE_PROPOSAL_THRESHOLD });
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: GOVERNANCE_SUPER_MAJORITY });
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentivePremium() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: ADVANCE_INCENTIVE_PREMIUM });
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolAddress() internal pure returns (address) {
        return POOL_ADDRESS;
    }

    function getContractionPoolAddress() internal pure returns (address) {
        return CONTRACTION_POOL_ADDRESS;
    }

    function getContractionPoolTargetSupply() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: CONTRACTION_POOL_TARGET_SUPPLY});
    }

    function getContractionPoolTargetReward() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: CONTRACTION_POOL_TARGET_REWARD});
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: SUPPLY_CHANGE_LIMIT });
    }

    function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: SUPPLY_CHANGE_DIVISOR });
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getDaoAddress() internal pure returns (address) {
        return DAO_ADDRESS;
    }

    function getDollarAddress() internal pure returns (address) {
        return DOLLAR_ADDRESS;
    }

    function getContractionDollarAddress() internal pure returns (address) {
        return CONTRACTION_DOLLAR_ADDRESS;
    }

    function getPairAddress() internal pure returns (address) {
        return PAIR_ADDRESS;
    }

    function getContractionPairAddress() internal pure returns (address) {
        return CONTRACTION_PAIR_ADDRESS;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function getCDSDRedemptionRatio() internal pure returns (uint256) {
        return CDSD_REDEMPTION_RATIO;
    }

    function getContractionBondingRewards() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: CONTRACTION_BONDING_REWARDS});
    }

    function maxCDSDBondingRewards() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: MAX_CDSD_BONDING_REWARDS});
    }

    function getBaseEarnableFactor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BASE_EARNABLE_FACTOR});
    }

    function getMaxEarnableFactor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: MAX_EARNABLE_FACTOR});
    }
}
