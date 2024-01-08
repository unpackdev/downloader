// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IVaderBond {
    function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint);
}