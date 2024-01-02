// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./Context.sol";

contract $Context is Context {
    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() payable {
    }

    receive() external payable {}
}
