
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Niftyphile
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    llllllllll          lllll    lllllllllllllll    000000000000000            //
//    lllll lllll         lllll    llllllllllllll1    0000000000000000           //
//    lllll  lllll        lllll    lllll              00000        00000         //
//    lllll   lllll       lllll    lllll              00000         00000        //
//    lllll    lllll      lllll    llll1llllllllll    00000        00000         //
//    lllll     lllll     lllll    lllllllllllllll    0000000000000000           //
//    lllll      lllll    lllll    lllll              000000000000000            //
//    lllll       lllll   lllll    lllll              00000                      //
//    lllll        lllll  lllll    lllll              00000                      //
//    lllll         lllll lllll    lllll              00000                      //
//    lllll          llllllllll    lllll              00000                      //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract NFP is ERC721Creator {
    constructor() ERC721Creator("Niftyphile", "NFP") {}
}
