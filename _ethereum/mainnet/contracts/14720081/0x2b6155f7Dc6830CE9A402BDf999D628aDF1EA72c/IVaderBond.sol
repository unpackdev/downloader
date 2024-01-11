// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "ISafelyOwnable.sol";

interface IVaderBond is ISafelyOwnable {
    function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint);
    function initialize(
        uint _controlVariable,
        uint _vestingTerm,
        uint _minPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external;
}