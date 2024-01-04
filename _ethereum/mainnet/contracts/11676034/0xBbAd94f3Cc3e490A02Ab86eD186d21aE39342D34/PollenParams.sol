// This file is generated for the "mainnet" network
// by the 'generate-PollenAddresses_sol.js' script.
// Do not edit it directly - updates will be lost.
// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;


/// @dev Network-dependant params (i.e. addresses, block numbers, etc..)
contract PollenParams {

    // Pollen contracts addresses
    address internal constant pollenDaoAddress = 0x99c0268759d26616AeC761c28336eccd72CCa39A;
    address internal constant plnTokenAddress = 0xF4db951000acb9fdeA6A9bCB4afDe42dd52311C7;
    address internal constant stemTokenAddress = 0xd12ABa72Cad68a63D9C5c6EBE5461fe8fA774B60;
    address internal constant rateQuoterAddress = 0xB7692BBC55C0a8B768E5b523d068B5552fbF7187;

    // STEM minting params
    uint32 internal constant mintStartBlock = 11565019; // Jan-01-2021 00:00:00 +UTC
    uint32 internal constant mintBlocks = 9200000; // ~ 46 months
    uint32 internal constant extraMintBlocks = 600000; // ~ 92 days

    // Default voting terms
    uint32 internal constant defaultVotingExpiryDelay = 12 * 3600;
    uint32 internal constant defaultExecutionOpenDelay = 6 * 3600;
    uint32 internal constant defaultExecutionExpiryDelay = 24 * 3600;
}
