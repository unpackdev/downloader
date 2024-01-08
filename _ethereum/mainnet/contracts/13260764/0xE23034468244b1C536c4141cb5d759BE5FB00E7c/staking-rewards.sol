// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IStakingRewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function stake(uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 amount) external;

    function transferOperator(address newOperator_) external;
}
