
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Royal Highness “Token”
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    The Royal Highness Token is the premier hub for crypto enthusiasts         //
//    and cannabis connoisseurs on the blockchain. A collection of 100           //
//    Royal Highness Token chilling in the metaverse: membership to the          //
//    Royal Highness Token confers exclusive real-world and on-chain             //
//    benefits and is reserved only to the owners of the Royal Highness          //
//    Token NFT collection Each NFT will beLinked to a physical                  //
//    product that can be claimed on the Website. With everything from           //
//    T-shirts, Hats, and Hoodies Once NFT is purchased it will act as a         //
//    key to the website with benefits of Whitelist options and Early Access     //
//    On all Future Drops plus a lifetime of Highness. Join The Family &         //
//    Smoke The Finest with Royal Highness                                       //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract RHT is ERC721Creator {
    constructor() ERC721Creator(unicode"Royal Highness “Token”", "RHT") {}
}
