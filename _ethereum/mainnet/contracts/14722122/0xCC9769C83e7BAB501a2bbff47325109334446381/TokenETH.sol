// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract TokenETH is Token {
    // creating a token for TPC
    constructor() Token("Wrapped TPC", "WTPC", 50000000 ether) {}
}
