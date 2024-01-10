// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface ILoot {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function getHead(uint256 tokenId) external view returns (string memory);
}

interface ILmart {
    function headId(uint256 tokenId) external pure returns (uint256);

    function tokenName(uint256 id) external view returns (string memory);
}

interface IRiftData {
    function addXP(uint256 xp, uint256 bagId) external;
}
