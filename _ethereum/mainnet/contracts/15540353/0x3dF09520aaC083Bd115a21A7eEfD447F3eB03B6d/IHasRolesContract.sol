// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./IHasRolesContract.sol";

abstract contract $IHasRolesContract is IHasRolesContract {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}
