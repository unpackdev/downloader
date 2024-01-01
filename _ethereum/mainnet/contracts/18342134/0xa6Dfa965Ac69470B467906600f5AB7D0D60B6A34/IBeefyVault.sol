// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBeefyVault {
    function deposit(uint256 amount) external;
    function withdraw(uint256 shares) external;
    function want() external pure returns (address);
    function balance() external pure returns (uint256);
    function strategy() external pure returns (address);
    function migrationDeposit(uint _amount, address _owner) external;
    function migrationWithdraw(uint _shares, address _owner) external returns(uint256);
}