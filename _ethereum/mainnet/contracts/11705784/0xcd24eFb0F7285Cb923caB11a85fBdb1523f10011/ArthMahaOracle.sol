// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SimpleOracle.sol";

contract ArthMahaOracle is SimpleOracle {
    constructor() public SimpleOracle('ArthMahaOracle', 1e18) {}
}
