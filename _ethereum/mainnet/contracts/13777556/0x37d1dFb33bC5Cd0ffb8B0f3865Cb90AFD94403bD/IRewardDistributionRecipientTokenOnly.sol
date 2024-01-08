// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./IERC20.sol";

interface IRewardDistributionRecipientTokenOnly {
    function rewardToken() external view returns(IERC20);
    function notifyRewardAmount(uint256 reward) external;
    function setRewardDistribution(address rewardDistribution) external;
}
