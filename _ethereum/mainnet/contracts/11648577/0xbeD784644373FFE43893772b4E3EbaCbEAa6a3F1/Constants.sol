/*
    Copyright 2020 VTD team, based on the works of Dynamic Dollar Devs and Empty Set Squad

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
import "./IOracle.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 36; // 36 epochs IMPORTANT
    uint256 private constant BOOTSTRAPPING_PERIOD_PHASE1 = 0; // set to 0
    uint256 private constant BOOTSTRAPPING_PRICE = 196e16; // 1.96 pegged token (targeting 8% inflation)

    /* Oracle */
    //IMPORTANT 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 deprecated
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); 
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e9; // 1,000 pegged token, 1e9 IMPORTANT

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 VTD -> 100M VTDD

    /* Epoch */
    uint256 private constant EPOCH_START = 1609405200;
    uint256 private constant EPOCH_BASE = 7200; //two hours IMPORTANT
    uint256 private constant EPOCH_GROWTH_CONSTANT = 12000; //1 hour
    uint256 private constant P1_EPOCH_BASE = 300; // IMPORTANT
    uint256 private constant P1_EPOCH_GROWTH_CONSTANT = 12000; // IMPORTANT 12000
    uint256 private constant ADVANCE_LOTTERY_TIME = 91; // deprecated

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 8; // 1 dayish governance period IMPORTANT
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 51e16; // 51%
    uint256 private constant GOVERNANCE_FASTTRACK_PERIOD = 3; // 3 epochs
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 14400; // 4 hours in case multi-lp has a critical bug

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 50e18; // 50 VTD IMPORTANT
    uint256 private constant ADVANCE_INCENTIVE_BOOTSTRAP = 50e18; // 50 VTD deprecated
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 18; // 18 epoch fluid IMPORTANT

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 9; // 9 epoch fluid IMPORTANT

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 180; //30 days
    uint256 private constant DEBT_RATIO_CAP = 35e16; // 35%
    uint256 private constant INITIAL_COUPON_REDEMPTION_PENALTY = 50e16; // 50%
    uint256 private constant COUPON_REDEMPTION_PENALTY_DECAY = 3600; // 1 hour

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 10e16; // 10%
    uint256 private constant EPOCH_GROWTH_BETA = 90e16; // 90%
    uint256 private constant ORACLE_POOL_RATIO = 40; // 40% IMPORTANT Increased to 40% for 2 pools

    // Pegs
    uint256 private constant USDC_START = 240;
    uint256 private constant USDT_START = 120;
    uint256 private constant WBTC_START = 180;

    // IMPORTANT, double check addresses
    address private constant USDC_POOL = address(0xD3DD32395271bAC888dAAF58Aa7FAF635D6d459F);
    address private constant USDT_POOL = address(0x649f1A91a9693C94747e95C9CE3d9A952Ef652A9); 
    address private constant WETH_POOL = address(0x26C6ee0F68f9D6cE8dd9d9A8dD972B04D7b94289); 
    address private constant WBTC_POOL = address(0x8951303cB54F013b41Bcf762F6210bdc9292c1Ac); 
    address private constant DSD_POOL = address(0x623EA23a36bF98a065701B08Be1Ad17246d0E337);

    address private constant USDC_ORACLE = address(0x3121a778536FaBCe3AC903FE2df242097b79eefD);
    address private constant USDT_ORACLE = address(0xB518894Be07239C2e78323244617765aDf593E86); 
    address private constant WETH_ORACLE = address(0x22d1EFAE32841FA741B1DD30eA6E8cF514D57DE9); 
    address private constant WBTC_ORACLE = address(0xa86b4cf024a49CB47eEa037874bF0B1ae7702F21); 
    address private constant DSD_ORACLE = address(0x5e3485B75cdD6Ba8C71Df43b7e8e62dB37357a13);

    /**
     * Getters
     */
    function getEpochStart() internal pure returns (uint256) {
        return EPOCH_START;
    }

    function getP1EpochBase() internal pure returns (uint256) {
        return P1_EPOCH_BASE;
    }

    function getP1EpochGrowthConstant() internal pure returns (uint256) {
        return P1_EPOCH_GROWTH_CONSTANT;
    }

    function getEpochBase() internal pure returns (uint256) {
        return EPOCH_BASE;
    }

    function getEpochGrowthConstant() internal pure returns (uint256) {
        return EPOCH_GROWTH_CONSTANT;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getAdvanceLotteryTime() internal pure returns (uint256){
        return ADVANCE_LOTTERY_TIME;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getPhaseOnePeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD_PHASE1;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

     function getFastTrackPeriod() internal pure returns (uint256) {
        return GOVERNANCE_FASTTRACK_PERIOD;
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

    function getAdvanceIncentiveBootstrap() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_BOOTSTRAP;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    
    function getInitialCouponRedemptionPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: INITIAL_COUPON_REDEMPTION_PENALTY});
    }

    function getCouponRedemptionPenaltyDecay() internal pure returns (uint256) {
        return COUPON_REDEMPTION_PENALTY_DECAY;
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getEpochGrowthBeta() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: EPOCH_GROWTH_BETA});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getWbtcStart() internal pure returns (uint256) {
        return WBTC_START;
    }

    function getUsdtStart() internal pure returns (uint256) {
        return USDT_START;
    }

    function getUsdcStart() internal pure returns (uint256) {
        return USDC_START;
    }

// pools
    function getUsdcPool() internal pure returns (address) {
        return USDC_POOL;
    }

    function getUsdtPool() internal pure returns (address) {
        return USDT_POOL;
    }

    function getEthPool() internal pure returns (address) {
        return WETH_POOL;
    }

    function getWbtcPool() internal pure returns (address) {
        return WBTC_POOL;
    }

    function getDsdPool() internal pure returns (address) {
        return DSD_POOL;
    }

// oracles
    function getUsdcOracle() internal pure returns (IOracle) {
        return IOracle(USDC_ORACLE);
    }

    function getUsdtOracle() internal pure returns (IOracle) {
        return IOracle(USDT_ORACLE);
    }

    function getEthOracle() internal pure returns (IOracle) {
        return IOracle(WETH_ORACLE);
    }

    function getWbtcOracle() internal pure returns (IOracle) {
        return IOracle(WBTC_ORACLE);
    }

    function getDsdOracle() internal pure returns (IOracle) {
        return IOracle(DSD_ORACLE);
    }
}
