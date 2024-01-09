// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Etherrock {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}