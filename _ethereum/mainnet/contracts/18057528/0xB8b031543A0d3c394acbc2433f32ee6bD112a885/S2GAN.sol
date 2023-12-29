// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shortcut2GAN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    (¯`·¯`·.¸¸.·´¯`·.¸¸.·´¯`·´¯)                                           //
//    ( \                      / )                                           //
//     ( ) Shortcut's GAN-Art ( )                                            //
//      (/                    \)                                             //
//       (.·´¯`·.¸¸.·´¯`·.¸¸.·)                                              //
//                                                                           //
//    A collection of artworks, that were created and curated by             //
//    crypto-artist "Shortcut" based on various AI tools and                 //
//    'Generative Adversarial Networks' (like StyleGAN, BigGAN,              //
//    AttnGAN, Adaptive Style Transfer and Sketch to Image).                 //
//                                                                           //
//    Owning the respective NFT grants you the non-exclusive right           //
//    to display and print the artwork even commercially. For example        //
//    to showcase it in an exhibition, to publish it an art-book,            //
//    and to print posters or postcards.                                     //
//                                                                           //
//    Please respect artist royalties!                                       //
//    If you collected any NFT of this collection on a secondary market,     //
//    that does not automatically collect and forward royalties to my        //
//    creator wallet (shortcut2.eth), above rights will be limited to        //
//    non-commercial use of the art until either buyer or seller pays at     //
//    least 10% royalties to my creator wallet.                              //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract S2GAN is ERC721Creator {
    constructor() ERC721Creator("Shortcut2GAN", "S2GAN") {}
}
