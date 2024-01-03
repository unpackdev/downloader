// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IChi {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}
