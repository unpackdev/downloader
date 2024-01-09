
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRAINPASTA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//    Cartoonist, Free figuration, outsider art.                                                                                                  //
//    I grew up drawing cartoons, I sold my arts on the streets, and I've always doodled on my notes, art is my escape and it always has been.    //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BP is ERC721Creator {
    constructor() ERC721Creator("BRAINPASTA", "BP") {}
}
