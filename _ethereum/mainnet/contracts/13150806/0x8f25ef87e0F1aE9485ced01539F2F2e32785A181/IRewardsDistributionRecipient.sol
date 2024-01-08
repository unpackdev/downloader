pragma solidity 0.8.2;

import "./IERC20.sol";

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;
    function getRewardToken() external view returns (IERC20);
}