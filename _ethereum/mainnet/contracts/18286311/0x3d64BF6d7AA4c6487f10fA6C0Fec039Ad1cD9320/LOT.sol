// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lot Lizards
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//                           )/_            //
//                 _.--..---"-,--c_         //
//            \L..'           ._O__)_       //
//    ,-.     _.+  _  \..--( /              //
//      `\.-''__.-' \ (     \_              //
//        `'''       `\__   /\              //
//                    ')                    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract LOT is ERC721Creator {
    constructor() ERC721Creator("Lot Lizards", "LOT") {}
}
