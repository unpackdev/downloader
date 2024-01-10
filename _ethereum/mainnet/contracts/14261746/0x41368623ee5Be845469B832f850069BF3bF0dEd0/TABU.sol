
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TABUNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    oooooooo_oo__________________ooooooo____oo_______oo______oo_ooo___________________    //
//    ___oo____oo_ooo___ooooo______oo____oo________oooooo__oooooo__oo____ooooo__oo_ooo__    //
//    ___oo____ooo___o_oo____o_____oo____oo___oo__oo___oo_oo___oo__oo___oo____o_ooo___o_    //
//    ___oo____oo____o_ooooooo_____ooooooo____oo__oo___oo_oo___oo__oo___ooooooo_oo______    //
//    ___oo____oo____o_oo__________oo____oo___oo__oo___oo_oo___oo__oo___oo______oo______    //
//    ___oo____oo____o__ooooo______oo_____oo_oooo__oooooo__oooooo_ooooo__ooooo__oo______    //
//    __________________________________________________________________________________    //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract TABU is ERC721Creator {
    constructor() ERC721Creator("TABUNFT", "TABU") {}
}
