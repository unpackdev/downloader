// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPartyLandMinter {
    function mintBatch() external;
    function exists(uint256 tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId, address owner) external view returns (address);
}
