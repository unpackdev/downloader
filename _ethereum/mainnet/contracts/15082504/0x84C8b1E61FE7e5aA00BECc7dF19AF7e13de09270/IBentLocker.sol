// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBentLocker {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function claimAll() external;
}
