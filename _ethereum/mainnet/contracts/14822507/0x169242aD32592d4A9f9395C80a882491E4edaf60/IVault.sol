/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IVault {
    function deposit(uint256 _amount) external payable;
}
