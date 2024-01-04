// SPDX-License-Identifier: None
pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Slingshot Abstract Module
/// @dev   the only purpose of this is to allow for easy verification when adding new module
abstract contract ISlingshotModule {
    function slingshotPing() public pure returns (bool) {
        return true;
    }
}
