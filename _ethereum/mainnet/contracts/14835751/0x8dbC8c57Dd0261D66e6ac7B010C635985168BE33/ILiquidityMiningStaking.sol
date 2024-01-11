// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ILiquidityMiningStaking {
    function blocksWithRewardsPassed() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    /// @notice set boost reward multiplier for stakers who locked NFT
    /// @dev it allows to set reward multiplier of locked NFT even when there is no LPstaking
    /// @param _account is the user address
    /// @param _rewardMultiplier is the boost multiplier of locked NFT by user
    function setRewardMultiplier(address _account, uint256 _rewardMultiplier) external;

    function earnedSlashed(address _account) external view returns (uint256);

    function getAPY() external view returns (uint256);
}
