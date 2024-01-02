// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.20;

interface IStarknetBridge {
    function deposit(uint256 amount, uint256 l2Recipient) external payable;

    function withdraw(uint256 amount, address recipient) external;
}
