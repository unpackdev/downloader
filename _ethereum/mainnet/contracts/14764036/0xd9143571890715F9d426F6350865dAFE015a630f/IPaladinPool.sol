// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

interface IPaladinPool {
    function deposit(uint256 _amount) external returns (uint256);
}
