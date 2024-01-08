//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPostalCodeProvider {
    function getTokenId(uint256 tokenId) external view returns (uint256);
}
