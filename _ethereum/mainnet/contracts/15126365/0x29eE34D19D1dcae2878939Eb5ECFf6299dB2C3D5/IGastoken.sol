// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IGastoken {
    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256 freed);
}
