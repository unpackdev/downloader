// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./IDEXRouter.sol";

abstract contract $IDEXRouter is IDEXRouter {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() payable {
    }

    receive() external payable {}
}
