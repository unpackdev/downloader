// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GROK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//            GGGGGGGGGGGGGRRRRRRRRRRRRRRRRR        OOOOOOOOO     KKKKKKKKK    KKKKKKK    //
//         GGG::::::::::::GR::::::::::::::::R     OO:::::::::OO   K:::::::K    K:::::K    //
//       GG:::::::::::::::GR::::::RRRRRR:::::R  OO:::::::::::::OO K:::::::K    K:::::K    //
//      G:::::GGGGGGGG::::GRR:::::R     R:::::RO:::::::OOO:::::::OK:::::::K   K::::::K    //
//     G:::::G       GGGGGG  R::::R     R:::::RO::::::O   O::::::OKK::::::K  K:::::KKK    //
//    G:::::G                R::::R     R:::::RO:::::O     O:::::O  K:::::K K:::::K       //
//    G:::::G                R::::RRRRRR:::::R O:::::O     O:::::O  K::::::K:::::K        //
//    G:::::G    GGGGGGGGGG  R:::::::::::::RR  O:::::O     O:::::O  K:::::::::::K         //
//    G:::::G    G::::::::G  R::::RRRRRR:::::R O:::::O     O:::::O  K:::::::::::K         //
//    G:::::G    GGGGG::::G  R::::R     R:::::RO:::::O     O:::::O  K::::::K:::::K        //
//    G:::::G        G::::G  R::::R     R:::::RO:::::O     O:::::O  K:::::K K:::::K       //
//     G:::::G       G::::G  R::::R     R:::::RO::::::O   O::::::OKK::::::K  K:::::KKK    //
//      G:::::GGGGGGGG::::GRR:::::R     R:::::RO:::::::OOO:::::::OK:::::::K   K::::::K    //
//       GG:::::::::::::::GR::::::R     R:::::R OO:::::::::::::OO K:::::::K    K:::::K    //
//         GGG::::::GGG:::GR::::::R     R:::::R   OO:::::::::OO   K:::::::K    K:::::K    //
//            GGGGGG   GGGGRRRRRRRR     RRRRRRR     OOOOOOOOO     KKKKKKKKK    KKKKKKK    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract Grok is ERC721Creator {
    constructor() ERC721Creator("GROK", "Grok") {}
}
