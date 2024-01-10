// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Math.sol";

/// @dev 2 * log2((x_init + K) / x)
uint256 constant LOG_DENOM = 2885390080;


/// @dev The round unit, K.
uint128 constant K = 0.00001 ether;

uint128 constant INITIAL_ROUNDS = 10000 ether;

struct BidderAndTimeOut {
    address bidder;
    uint64 timeOut;
}

struct BidderQueue {
    mapping(uint128 => BidderAndTimeOut) queue;
    uint128 head;
    uint128 tail;
}

struct BidInfo {
    bool bidded;
    uint128 amount;
}

struct PairInfo {
    address baseToken;
    address nftAddress;
    uint256 metaNftId;
    uint256 tokenId;
    bytes32 descriptionHash;

    mapping(address => BidInfo) metaNftInfo;
    mapping(address => BidInfo) nftInfo;
    mapping(address => DistUserInfo) distUsers;
    mapping(address => uint128) roundBalanceOf;
    string[] tags;

    BidderQueue metaNftQueue;
    BidderQueue nftQueue;

    uint128 actualBaseReserve;
    uint128 bidBaseReserve;
    uint128 cumulativeRewardPerRound;
    uint128 extraRewardParameter;
    uint128 initBaseReserve;
    uint128 minBaseReserve;
    uint128 mintBaseReserve;
    uint128 roundTotalSupply;
    uint128 tradingVolume;

    uint32 lastBlockNumber;
    uint32 version;

    bool activated;
    bool innerLock;
    bool outerLock;
}

struct DistUserInfo {
    uint128 minRoundReserve;
    uint128 lastCumulativeRewardPerRound;
}

struct DistPoolInfo {
    uint128 rewardParameter;
    uint128 gasReward;
}

struct AppStorage {
    /// Meta NFT
    address metaNFT;
    /// PIL staking contract address
    address stakingContract;
    /// UniswapV3 Postion NFT
    address uniV3Pos;
    /// UniswapV3 Factory
    address uniV3Factory;
    /// Registered Base tokens
    address[] baseTokens;
    /// Pilgrim Treasury address
    address treasury;
    /// WETH
    address weth;
    /// Pilgrim token
    address pil;

    mapping(uint256 => mapping(address => bool)) transactionHistory;
    mapping(address => mapping(uint256 => uint256[])) metaNftIds;
    mapping(uint256 => PairInfo) pairs;

    /// metaNftId => reward amount
    mapping(uint256 => uint128) pairRewards;
    /// user address => reward amount
    mapping(address => uint128) userRewards;

    /// base token address => cumulative fees
    mapping(address => uint128) cumulativeFees;

    /// base token address => PIL distribution pool info
    mapping(address => DistPoolInfo) distPools;
    /// token0 => (token1 => extraRewardParameter)
    mapping(address => mapping(address => uint32)) uniV3ExtraRewardParams;

    uint32 rewardEpoch;
    uint32 bidTimeout;
    uint32 roundFeeNumerator;
    uint32 baseFeeNumerator;
    uint32 nftFeeNumerator;
    }

library LibAppStorage {
    function _diamondStorage() internal pure returns (AppStorage storage _ds) {
        assembly {
            _ds.slot := 0
        }
    }
}
