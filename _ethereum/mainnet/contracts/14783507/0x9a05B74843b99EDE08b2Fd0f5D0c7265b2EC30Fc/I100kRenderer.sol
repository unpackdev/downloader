//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface I100kRenderer {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}