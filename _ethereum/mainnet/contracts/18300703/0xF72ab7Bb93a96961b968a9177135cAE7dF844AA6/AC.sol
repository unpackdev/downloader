// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hispania
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//    "Hispania" collection is an intimate and contemporary exploration of the essence and evolution of my cultural heritage bridging the ancestral and the avant-garde.    //
//    A visual journey that intertwines digital painting and artificial intelligence with the rich cultural tapestry of Spain.                                              //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AC is ERC721Creator {
    constructor() ERC721Creator("Hispania", "AC") {}
}
