// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// iykyk
contract KeyID {
    function doIt(bytes4 stuff) public pure returns (uint32) {
        return uint32(stuff);
    }
}