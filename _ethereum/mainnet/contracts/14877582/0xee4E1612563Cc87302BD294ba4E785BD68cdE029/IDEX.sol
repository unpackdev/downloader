// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IDEX {
   function addBlindBoxData(address collection, address to, uint256 tokenId, uint256 royalty, address from) external;
   }