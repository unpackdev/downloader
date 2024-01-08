// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./NFTCultureCollectionBase.sol";

/**
 * @title The Gallery by NFT Culture wrapper contract
 *
 *oooooooo_oo____________________oooo___________ooo___ooo___________________________
 *___oo____oo_ooo___ooooo______oo____oo__ooooo___oo____oo____ooooo__oo_ooo___o___oo_
 *___oo____ooo___o_oo____o____oo________oo___oo__oo____oo___oo____o_ooo___o__o___oo_
 *___oo____oo____o_ooooooo____oo____ooo_oo___oo__oo____oo___ooooooo_oo_______o___oo_
 *___oo____oo____o_oo__________oo____oo_oo___oo__oo____oo___oo______oo________ooooo_
 *___oo____oo____o__ooooo________oooo____oooo_o_ooooo_ooooo__ooooo__oo______o____oo_
 *___________________________________________________________________________ooooo__
 *
 * Credit to https://patorjk.com/ for text generator.
 */
contract TheGalleryByNFTCulture is NFTCultureCollectionBase {
    constructor()
        NFTCultureCollectionBase(
            'The Gallery by NFT Culture',
            'https://gateway.pinata.cloud/ipfs/QmNrPi8VYbjorH9Ms4BShUFerAn7CfG6CJqWcSRb5oN4bW/{id}.json', //V4B
            0,
            0x5d75c1b764AFd64fe02a28B5eFF79E2f81DB5bad, // The NFTCult contract on mainnet.
            0x8C811d9E8F4b734066cF2832168421504FA441b0  // The NFTCultForgeComponents contract on mainnet.
        )
    {
        // Implementation version: 1
    }
}