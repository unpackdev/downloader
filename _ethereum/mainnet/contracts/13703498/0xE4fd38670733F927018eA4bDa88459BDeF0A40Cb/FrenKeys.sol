// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;


import "./BaseToken.sol";

contract FrenKeys is BaseToken {
    constructor(string memory name, string memory symbol)
        BaseToken(name, symbol) { }

}