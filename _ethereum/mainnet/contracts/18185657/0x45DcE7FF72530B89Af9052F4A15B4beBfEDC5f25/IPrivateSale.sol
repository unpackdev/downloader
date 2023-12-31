// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IPrivateSale {
    error NotWhitelisted();
    error NotOwner();
    error NotUpgrader();
    error InvalidAmount();
    error InvalidInput();
    error CapExceeded();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address caller, address to, uint256 amount);

    struct WhitelistItem {
        address user;
        uint256 cap;
    }
}
