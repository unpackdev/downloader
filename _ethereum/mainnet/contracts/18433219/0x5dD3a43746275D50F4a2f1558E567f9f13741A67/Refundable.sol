// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.21;

interface Refundable {
    error DepositNotFound();

    event Refund(string poolName, uint256 indexed amount, address indexed depositor);

    function refund(string calldata poolName) external;
}
