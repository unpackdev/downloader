// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";

contract NFTPriceFormulaStorage is OwnableUpgradeable {
    /** mapping formula type with price (constant number) */
    mapping(uint256 => uint256) public formulaPrices;
}
