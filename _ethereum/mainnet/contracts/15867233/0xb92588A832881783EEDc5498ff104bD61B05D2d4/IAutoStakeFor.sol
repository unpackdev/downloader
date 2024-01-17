// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IAutoStakeFor {
    function stakeFor(address _for, uint256 amount) external;
    function rewardsDuration() external view returns(uint256);
    function earned(address _account) external view returns(uint256);

}
