// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./DefinitiveAssets.sol";

interface ICoreRewardsV1 {
    event RewardsClaimed(IERC20[] rewardTokens, uint256[] rewardAmounts, uint256[] feeAmounts);

    function unclaimedRewards() external view returns (IERC20[] memory, uint256[] memory);

    function claimAllRewards(uint256 feePct) external returns (IERC20[] memory, uint256[] memory);
}
