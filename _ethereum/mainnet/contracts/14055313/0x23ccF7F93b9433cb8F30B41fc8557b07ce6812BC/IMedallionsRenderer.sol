// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMedallionsRenderer {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}