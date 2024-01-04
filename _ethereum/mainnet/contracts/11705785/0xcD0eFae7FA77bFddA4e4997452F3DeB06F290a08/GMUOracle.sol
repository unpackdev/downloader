// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SimpleOracle.sol";

contract GMUOracle is SimpleOracle {
    constructor() public SimpleOracle('GMU Oracle', 1e18) {}
}
