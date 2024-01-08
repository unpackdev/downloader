// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SharedDataTypes {
    // struct for returning snapshot values
    struct StakeSnapshot {
        // initial block number snapshoted
        uint256 startBlock;
        // end block number snapshoted
        uint256 endBlock;
        // staked amount at initial block
        uint256 stakedAmount;
        // total value locked at end block
        uint256 tokenTVL;
    }

    // general staker user information
    struct StakerUser {
        // snapshotted stakes of the user per token (token => block.number => stakedAmount)
        mapping(address => mapping(uint256 => uint256)) stakedAmountSnapshots;
        // snapshotted stakes of the user per token keys (token => block.number[])
        mapping(address => uint256[]) stakedAmountKeys;
        // current stakes of the user per token
        mapping(address => uint256) stakedAmount;
        // total amount of holder tokens
        uint256 zcxhtStakedAmount;
    }

    // information for stakeable tokens
    struct StakeableToken {
        // snapshotted total value locked (TVL) (block.number => totalValueLocked)
        mapping(uint256 => uint256) totalValueLockedSnapshots;
        // snapshotted total value locked (TVL) keys (block.number[])
        uint256[] totalValueLockedKeys;
        // current total value locked (TVL)
        uint256 totalValueLocked;
        uint256 weight;
        bool active;
    }

    // POOL DATA

    // data object for a user stake on a pool
    struct PoolStakerUser {
        // saved / withdrawn rewards of user
        uint256 totalSavedRewards;
        // total purchased allocation
        uint256 totalPurchasedAllocation;
        // native address, if necessary
        string nativeAddress;
        // date/time when user has claimed the reward
        uint256 claimedTime;
    }

    // flat data type of stake for UI
    struct FlatPoolStakerUser {
        address[] tokens;
        uint256[] amounts;
        uint256 pendingRewards;
        uint256 totalPurchasedAllocation;
        uint256 totalSavedRewards;
        uint256 claimedTime;
        PoolState state;
        UserPoolState userState;
    }

    // UI information for pool
    // data will be fetched via github token repository
    // blockchain / cAddress being the most relevant values
    // for fetching the correct token data
    struct PoolInfo {
        // token name
        string name;
        // name of blockchain, as written on github
        string blockchain;
        // tokens contract address on chain
        string cAddress;
    }

    // possible states of the reward pool
    enum PoolState {
        pendingStaking,
        staking,
        pendingPayment,
        payment,
        pendingDistribution,
        distribution,
        retired
    }

    // possible states of the reward pool's user
    enum UserPoolState {
        notclaimed,
        claimed,
        rejected,
        missed
    }

    // input data for new reward pools
    struct PoolInputData {
        // total rewards to distribute
        uint256 totalRewards;
        // start block for distribution
        uint256 startBlock;
        // end block for distribution
        uint256 endBlock;
        // erc token address
        address token;
        // pool type
        uint8 poolType;
        // information about the reward token
        PoolInfo tokenInfo;
    }

    struct PoolData {
        PoolState state;
        // pool information for the ui
        PoolInfo info;
        // start block of staking rewards
        uint256 startBlock;
        // end block of staking rewards
        uint256 endBlock;
        // start block of payment period
        uint256 paymentStartBlock;
        // end block of payment period
        uint256 paymentEndBlock;
        // start block of distribution period
        uint256 distributionStartBlock;
        // end block of distribution period
        uint256 distributionEndBlock;
        // total rewards for allocation
        uint256 totalRewards;
        // rewards per block
        uint256 rewardsPerBlock;
        // price of a single payment token
        uint256 rewardTokenPrice;
        // type of the pool
        uint8 poolType;
        // address of payment token
        address paymentToken;
        // address of reward token
        address token;
    }
}
