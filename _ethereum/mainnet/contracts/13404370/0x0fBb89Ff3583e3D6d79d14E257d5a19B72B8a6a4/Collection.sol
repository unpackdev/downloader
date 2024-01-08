// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Collection {
    function ownerOf(uint256 tokenId) public virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);

    function balanceOf(address owner) external virtual view returns (uint256 balance);

    function totalSupply() public virtual view returns (uint256);
}
