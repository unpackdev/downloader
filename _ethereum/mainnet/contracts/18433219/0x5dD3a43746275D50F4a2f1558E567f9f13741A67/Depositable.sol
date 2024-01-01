// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.21;

/**
 * @dev Structure of a deposit
 */
struct DepositRecord {
    uint112 amount;
    uint8 nonce;
}

interface Depositable {
    event Deposit(string poolName, uint256 indexed amount, address indexed from);

    function deposit(string calldata poolName, uint256 amount, bytes memory sig) external;

    function deposited(string calldata poolName, address depositor) external view returns (uint256);
}
