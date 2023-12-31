// SPDX-License-Identifier: MIT

/// @title TechWontSaveUs descriptor interface

pragma solidity >=0.8.10 <0.9.0;

interface ITokenDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
