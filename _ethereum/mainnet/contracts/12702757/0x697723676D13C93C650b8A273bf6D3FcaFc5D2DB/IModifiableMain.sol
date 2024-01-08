// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IModifiableMain {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function getTraitsOfTokenId(uint256 tokenId) external view returns (uint256 length, uint256 color);
    function startingIndex() external view returns (uint256);
    function isMintedBeforeReveal(uint256) external view returns (bool);
}