
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glass Cryptopunk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//    This is an exceptional collection made of colored glass cubes and is currently loaded in this store in the form of 1000 pieces over time and will be auctioned at the lowest price.     //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GCC is ERC721Creator {
    constructor() ERC721Creator("Glass Cryptopunk", "GCC") {}
}
