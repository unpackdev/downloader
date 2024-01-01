// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lichterloh print editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//     / . _  /__/_ _  _ / _  /_    //
//    / / /_ / //  /_'/ / /_// /    //
//                                  //
//                                  //
//      _  _ . _ _/_                //
//     /_// / / //                  //
//    /                             //
//                                  //
//     _   _/ ._/_ . _  _   _       //
//    /_'/_/ / /  / /_// /_\        //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LLPrints is ERC721Creator {
    constructor() ERC721Creator("lichterloh print editions", "LLPrints") {}
}
