
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT Doll
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//    NN   NN FFFFFFF TTTTTTT    DDDDD          lll lll     //
//    NNN  NN FF        TTT      DD  DD   oooo  lll lll     //
//    NN N NN FFFF      TTT      DD   DD oo  oo lll lll     //
//    NN  NNN FF        TTT      DD   DD oo  oo lll lll     //
//    NN   NN FF        TTT      DDDDDD   oooo  lll lll     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract Doll is ERC721Creator {
    constructor() ERC721Creator("NFT Doll", "Doll") {}
}
