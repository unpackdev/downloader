// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMNFTBlackListManager {
   function addOwner(address owner) external;

   function addToBlackList(address user) external;

   function removeFromBlackList(address user) external;

   function isBlackListed(address user) external view returns (bool);

   function viewBlackListedUsers() external view returns (address[] memory);
}