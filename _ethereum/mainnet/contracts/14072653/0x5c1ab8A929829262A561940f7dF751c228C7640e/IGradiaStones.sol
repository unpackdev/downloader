// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

abstract contract IGradiaStones {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual;
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
    function isWhitelisted(address user) public view virtual returns (bool);
}
