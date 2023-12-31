// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.21;

contract Avatar {
    mapping(uint16 => bool) public hasMintedTraits;

    function transferFrom(address from, address to, uint256 tokenId) external {}

    function externalToInternalMapping(
        uint256 _from
    ) external returns (uint256) {}

    function getAvatarTraits(
        uint256 tokenId
    ) external view returns (uint16[] memory) {}

    function ownerOf(uint256 tokenId) external view returns (address) {}
}
