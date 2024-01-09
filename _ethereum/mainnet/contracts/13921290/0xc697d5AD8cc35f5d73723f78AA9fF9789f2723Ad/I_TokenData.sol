// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface I_TokenData
{
    function tokenURI(uint256 tokenID) external view returns (string memory);
}