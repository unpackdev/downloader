// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolActions {
    function update() external returns (bool);
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount, address to) external returns (bool);
    function exit(uint256 amount, address to) external returns (bool);
    function claim(address to) external returns (bool);
    function restake(uint256 amount) external returns (bool);
    function unstake(uint256 amount, address to) external returns (bool);
}