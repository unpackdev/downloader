// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @notice Bounty struct requirements.
struct Bounty {
    // Address of the target gauge.
    address gauge;
    // Manager.
    address manager;
    // Address of the ERC20 used for rewards.
    address rewardToken;
    // Number of periods.
    uint8 numberOfPeriods;
    // Timestamp where the bounty become unclaimable.
    uint256 endTimestamp;
    // Max Price per vote.
    uint256 maxRewardPerVote;
    // Total Reward Added.
    uint256 totalRewardAmount;
}

interface IPlatform {
    function batchClaimFor(address[] calldata users, uint256 bountyId) external returns(uint256);
    function bounties(uint256 id) external view returns(Bounty memory);
    function claimable(address user, uint256 id) external view returns(uint256);
    function createBounty(address gauge, address manager, address rewardToken, uint8 numberOfPeriods, uint256 maxRewardPerVote, uint256 totalRewardAmount, address[] calldata blacklist, bool upgradeable) external returns(uint256);
    function setWhitelisted(address a, bool _isWhitelisted) external;
    function setRecipient(address r) external;
}