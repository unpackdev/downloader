// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IERC721GenMint {
    function mint(address artist, address to, uint value) external;
}
