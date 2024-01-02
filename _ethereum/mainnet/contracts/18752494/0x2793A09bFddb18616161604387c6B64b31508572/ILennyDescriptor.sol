// SPDX-License-Identifier: MIT

/*********************************
*                                *
*             ( ͡° ͜ʖ ͡°)           *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface ILennyDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}