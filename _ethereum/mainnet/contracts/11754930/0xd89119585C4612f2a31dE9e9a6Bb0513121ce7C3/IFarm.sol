// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

// Adapted from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/interface/ITrueFarm.sol
interface IFarm {
    function rewardToken() external view returns (IERC20);
    function stakingToken() external view returns (IERC20);
    function totalStaked() external view returns (uint256);
    function stake(uint256 amount) external;
    function unstake(address receiver, uint256 amount) external;
    function claim(address receiver) external;
    function exit(address receiver, uint256 amount) external;
}
