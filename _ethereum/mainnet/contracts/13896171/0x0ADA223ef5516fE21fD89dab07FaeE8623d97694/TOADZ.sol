// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Cryptoadz {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}