/**
* @author NiceArti (https://github.com/NiceArti) 
* To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
* @title The interface for implementing the CryptoFlatsNft smart contract 
* with a full description of each function and their implementation 
* is presented to your attention.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ICflatsDatabase.sol";

interface ICflatsDappRequirements
{
    function getDatabase() external view returns (ICflatsDatabase);
}