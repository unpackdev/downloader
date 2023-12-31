// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMuonNodeStaking {
    struct User {
        uint256 balance;
        uint256 paidReward;
        uint256 paidRewardPerToken;
        uint256 pendingRewards;
        uint256 tokenId;
    }

    function users(address stakerAddress)
        external
        view
        returns (User memory user);

    function earned(address stakerAddress) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function setMuonNodeTier(address stakerAddress, uint8 tier) external;
}
