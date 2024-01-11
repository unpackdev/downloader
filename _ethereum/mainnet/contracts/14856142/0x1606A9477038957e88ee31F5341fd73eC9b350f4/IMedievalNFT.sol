// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMedievalNFT{
    function tokenLevel(uint256 tokenId) view external returns (uint256);
    function seed(uint256 tokenId) view external returns (uint256);
    function tokenOccupation(uint256 tokenId) view  external returns (uint16);
    function strength(uint256 tokenId) view external returns(uint256);
    function house(uint256 tokenId) view external returns(uint256);
}

