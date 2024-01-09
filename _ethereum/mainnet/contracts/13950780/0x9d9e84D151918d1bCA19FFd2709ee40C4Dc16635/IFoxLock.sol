// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

interface IFoxLock {
    function lock(address account, uint256 amount) external;
}