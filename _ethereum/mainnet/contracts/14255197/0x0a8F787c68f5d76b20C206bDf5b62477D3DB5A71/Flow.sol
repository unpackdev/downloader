// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeArtNFTWithClaiming.sol";

/*            _       _           _              
 *  _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __ 
 * | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 * | | | | | | | | | | | | | | | | |/ /  __/ |   
 * |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|   
 * 
 * @title Flow
 * @author minimizer <me@minimizer.art>; https://minimizer.art/
 * 
 * minimizer's second project. Holders of Waves, the genesis project, deployed to
 * 0x46f1c444a9b10173c52ee7351eBa1e49C8bC5851 on mainnet, can mint for free. 
 */
contract Flow is GenerativeArtNFTWithClaiming  {
    constructor(string memory baseURI_, address claimContractAddress_) 
    GenerativeArtNFTWithClaiming(
        "Flow",                // token name
        "MIN_1",               // token symbol, minimizer's 2nd project
        baseURI_,              // address of base URI, while minting is active
        888,                   // max supply
        5,                     // max mint at once
        1,                     // preminted tokens
        80000000000000000,     // price (0.08 ETH)
        500,                   // 5% royalty
        claimContractAddress_, // address of the Waves contract 
        "MIN_0"                // symbol of the Waves contract, to check successful deployment
    ) {}
}