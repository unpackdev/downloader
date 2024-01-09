// SPDX-License-Identifier: MIT
/**
 * Created on 2021-01-16
 * @summary: Jibrel Aave Tranches Protocol Storage
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;

import "./OwnableUpgradeable.sol";

contract JAaveStorage is OwnableUpgradeable {
/* WARNING: NEVER RE-ORDER VARIABLES! Always double-check that new variables are added APPEND-ONLY. Re-ordering variables can permanently BREAK the deployed proxy contract.*/
    //address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    //address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint16 public constant AAVE_REFERRAL_CODE = 0;

    uint256 public constant PERCENT_DIVIDER = 10000;  // percentage divider

    struct TrancheAddresses {
        address buyerCoinAddress;       // ETH (ETH_ADDR) or DAI or other supported tokens
        address aTokenAddress;          // aETH or aDAI or other aToken
        address ATrancheAddress;
        address BTrancheAddress;
    }

    struct TrancheParameters {
        uint256 trancheAFixedPercentage;    // fixed percentage (i.e. 4% = 0.04 * 10^18 = 40000000000000000)
        uint256 trancheALastActionBlock;
        uint256 storedTrancheAPrice;
        uint256 trancheACurrentRPB;
        uint16 redemptionPercentage;        // percentage with 2 decimals (divided by 10000, i.e. 95% is 9500)
        uint8 underlyingDecimals;
    }

    address public adminToolsAddress;
    address public feesCollectorAddress;
    address public tranchesDeployerAddress;
    address public lendingPoolAddressProvider;
    address public wethGatewayAddress;
    address public aaveIncentiveControllerAddress;
    address public wrappedEthAddress;

    uint256 public tranchePairsCounter;
    uint256 public totalBlocksPerYear; 
    uint32 public redeemTimeout;

    mapping(uint256 => TrancheAddresses) public trancheAddresses;
    mapping(uint256 => TrancheParameters) public trancheParameters;
    // last block number where the user withdrew/deposited tokens
    mapping(address => uint256) public lastActivity;
    // enabling / disabling tranches for fund deposit
    mapping(uint256 => bool) public trancheDepositEnabled;
    address public rewardsToken;  // slice rewards
}


contract JAaveStorageV2 is JAaveStorage {
    struct StakingDetails {
        uint256 startTime;
        uint256 amount;
    }

    address public incentivesControllerAddress;

    // user => trancheNum => counter
    mapping (address => mapping(uint256 => uint256)) public stakeCounterTrA;
    mapping (address => mapping(uint256 => uint256)) public stakeCounterTrB;
    // user => trancheNum => stakeCounter => struct
    mapping (address => mapping (uint256 => mapping (uint256 => StakingDetails))) public stakingDetailsTrancheA;
    mapping (address => mapping (uint256 => mapping (uint256 => StakingDetails))) public stakingDetailsTrancheB;
}