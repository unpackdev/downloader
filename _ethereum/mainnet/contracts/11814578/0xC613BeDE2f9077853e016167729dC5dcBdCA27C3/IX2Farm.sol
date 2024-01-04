// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Farm {
    function cumulativeRewardPerToken() external view returns (uint256);
    function claimableReward(address account) external view returns (uint256);
    function previousCumulatedRewardPerToken(address account) external view returns (uint256);
}
