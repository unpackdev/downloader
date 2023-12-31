// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFxRoot{
    function sendMessageToChild(uint256 tokenID, address newOwner, bool isMigration) external ;
}