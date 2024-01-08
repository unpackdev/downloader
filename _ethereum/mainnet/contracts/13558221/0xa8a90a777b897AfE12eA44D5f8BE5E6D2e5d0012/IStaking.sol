// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function stakedToken() external view returns (address);

    function totalStaked() external view returns (uint256);

    function getUserBalance(address user) external view returns (uint256);

    function initialize(address token) external;

    function deposit(uint256 amount, address sender) external returns (bool);

    function withdraw(uint256 amount, address sender) external returns (bool);

    function addReward(uint256 amountReward) external;

    function claimDividends(address user) external returns (uint256);

    function availDividends(address user) external view returns (uint256);
}
