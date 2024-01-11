// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner) external returns (bool);
}