// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Bayc {
    function balanceOf(address owner) external virtual view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external virtual view returns (uint256 tokenId);
}
