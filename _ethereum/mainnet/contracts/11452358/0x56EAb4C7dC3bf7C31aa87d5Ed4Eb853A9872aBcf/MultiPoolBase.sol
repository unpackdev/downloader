// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./PoolBase.sol";

contract MultiPoolBase is PoolBase {

    // At any point in time, the amount of PWDR and tokens
    // entitled to a user that is pending to be distributed is:
    //
    //   pending_pwdr_reward = (user.shares * pool.accPwdrPerShare) - user.rewardDebt
    //   pending_token_rewards = (user.staked * pool.accTokenPerShare) - user.tokenRewardDebt
    //
    // Shares are a notional value of tokens staked, shares are given in a 1:1 ratio with tokens staked
    //  If you have any NFTs staked in the Lodge, you earn additional shares according to the boost of the NFT.
    //  PWDR rewards are calculated using shares, but token rewards are based on actual staked amounts.
    //
    // On withdraws/deposits:
    //   1. The pool's `accPwdrPerShare`, `accTokenPerShare`, and `lastReward` gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `staked` amount gets updated.
    //   4. User's `shares` amount gets updated.
    //   5. User's `rewardDebt` gets updated.

    // Info of each user.
    struct UserInfo {
        uint256 staked; // How many LP tokens the user has provided.
        uint256 shares; // user shares of the pool, needed to correctly apply nft bonuses
        uint256 rewardDebt; // PWDR Rewards. See explanation below.
        uint256 claimed; // Tracks the amount of PWDR claimed by the user.
        uint256 tokenRewardDebt; // Mapping Token Address to Rewards accrued
        uint256 tokenClaimed; // Tracks the amount of wETH claimed by the user.
    }

    // Info of each pool.
    struct PoolInfo {
        bool active;
        address token; // Address of token contract
        address lpToken; // Address of LP token (UNI-V2)
        bool lpStaked; // boolean indicating whether the pool is lp tokens
        uint256 weight; // Weight for each pool. Determines how many PWDR to distribute per block.
        uint256 lastReward; // Last block timestamp that rewards were distributed.
        uint256 totalStaked; // total actual amount of tokens staked
        uint256 totalShares; // Virtual total of tokens staked, nft stakers get add'l shares
        uint256 accPwdrPerShare; // Accumulated PWDR per share, times 1e12. See below.
        uint256 accTokenPerShare; // Accumulated ERC20 per share, times 1e12
    }

    mapping (uint256 => mapping (address => UserInfo)) public userInfo; // Pool=>User=>Info Mapping of each user that stakes in each pool
    PoolInfo[] public poolInfo; // Info of each pool

    mapping(address => bool) public contractWhitelist; // Mapping of whitelisted contracts so that certain contracts like the Aegis pool can interact with this Accumulation contract
    mapping(address => uint256) public tokenPools;

    modifier HasStakedBalance(uint256 _pid, address _address) {
        require(
            userInfo[_pid][_address].staked > 0, 
            "Must have staked balance greater than zero"
        );
        _;
    }

    modifier OnlyOriginOrAdminOrWhitelistedContract(address _address) {
        require(
            tx.origin == address(this)
            || hasPatrol("ADMIN", _address)
            || contractWhitelist[_address],
            "Only whitelisted contracts can call this function"
        ); // Only allow whitelisted contracts to prevent attacks
        _;
    }

    // Add a contract to the whitelist so that it can interact with Slopes
    function addToWhitelist(address _contractAddress) 
        public 
        HasPatrol("ADMIN")
    {
        contractWhitelist[_contractAddress] = true;
    }

    // Remove a contract from the whitelist
    function removeFromWhitelist(address _contractAddress) 
        public
        HasPatrol("ADMIN")
    {
        contractWhitelist[_contractAddress] = false;
    }
}