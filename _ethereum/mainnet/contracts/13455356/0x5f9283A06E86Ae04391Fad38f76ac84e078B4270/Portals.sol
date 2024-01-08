//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title:  Portals
// @desc:   An NFT photography collection of 111 door photos taken between 2017 and 2021
// @artist: https://twitter.com/officialgambi
// @author: https://twitter.com/giaset
// @url:    https://www.gambi.art

import "./MintWithPresale.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//    8888888b.                  888             888             //
//    888   Y88b                 888             888             //
//    888    888                 888             888             //
//    888   d88P .d88b.  888d888 888888  8888b.  888 .d8888b     //
//    8888888P" d88""88b 888P"   888        "88b 888 88K         //
//    888       888  888 888     888    .d888888 888 "Y8888b.    //
//    888       Y88..88P 888     Y88b.  888  888 888      X88    //
//    888        "Y88P"  888      "Y888 "Y888888 888  88888P'    //
//                                                               //
///////////////////////////////////////////////////////////////////

contract Portals is MintWithPresale {
    uint256 public constant MAX_PER_WALLET_AND_MINT = 3;
    uint256 public constant MAX_SUPPLY = 111;
    uint256 public constant TOKEN_PRICE = 0.111 ether;

    constructor(string memory baseTokenURI)
        MintWithPresale(
            "Portals",
            "PRTLS",
            baseTokenURI,
            MAX_PER_WALLET_AND_MINT,
            MAX_SUPPLY,
            TOKEN_PRICE
        )
    {}
}
