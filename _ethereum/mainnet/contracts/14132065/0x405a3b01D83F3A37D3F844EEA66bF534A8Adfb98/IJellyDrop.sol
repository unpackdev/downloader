pragma solidity 0.8.6;

struct RewardInfo {
    /// @notice Sets the token to be claimable or not (cannot claim if it set to false).
    bool tokensClaimable;
    /// @notice Epoch unix timestamp in seconds when the airdrop starts to decay
    uint48 startTimestamp;
    /// @notice Jelly streaming period
    uint32 streamDuration;
    /// @notice Jelly claim period, 0 for unlimited
    uint48 claimExpiry;
    /// @notice Reward multiplier
    uint128 multiplier;
}
interface IJellyDrop {
    function list() external view returns (address);
    function rewardsToken() external view returns (address);
    function rewardsPaid() external view returns (uint256);
    function rewardInfo() external view returns (RewardInfo memory);
}

