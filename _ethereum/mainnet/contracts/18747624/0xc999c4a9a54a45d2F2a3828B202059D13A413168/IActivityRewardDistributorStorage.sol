// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20.sol";

import "./IPrimexDNS.sol";
import "./ITraderBalanceVault.sol";

interface IActivityRewardDistributorStorage {
    /*
     * @param oldBalance last updated balance for user
     * @param fixedReward the accumulated value of the reward at the time lastUpdatedRewardIndex
     * @param lastUpdatedRewardIndex last index with which the user's reward was accumulated
     */
    struct UserInfo {
        uint256 fixedReward;
        uint256 lastUpdatedRewardIndex;
        uint256 oldBalance;
    }

    /*
     * @param users data to calculate users rewards in this bucket
     * @param rewardIndex an index that accumulates user rewards
     * @param lastUpdatedTimestamp timestamp of the last update of user activity
     * @param rewardPerToken current reward for one token(PToken or DebtToken of bucket)
     * @param isFinished Shows that the bucket has distributed all the rewards
     * @param fixedReward reward distributed by a bucket over the past period
     * with a certain reward per day or with the entire reward fully distributed
     * @param lastUpdatedRewardTimestamp timestamp of last fixed reward update
     * @param rewardPerDay current reward distributed for 1 day
     * @param totalReward Full distributable reward
     * @param endTimestamp end time of the distribution of rewards, which is calculated relative to the rewardPerDay and totalReward
     */
    struct BucketInfo {
        mapping(address => UserInfo) users;
        //accumulated reward per token
        uint256 rewardIndex;
        uint256 lastUpdatedTimestamp;
        uint256 rewardPerToken;
        uint256 scaledTotalSupply;
        bool isFinished;
        // setted by admin's actions
        uint256 fixedReward;
        uint256 lastUpdatedRewardTimestamp;
        uint256 rewardPerDay;
        uint256 totalReward;
        uint256 endTimestamp;
    }

    function pmx() external returns (IERC20);

    function dns() external returns (IPrimexDNS);

    function registry() external returns (address);

    function traderBalanceVault() external returns (ITraderBalanceVault);

    function treasury() external view returns (address);
}
