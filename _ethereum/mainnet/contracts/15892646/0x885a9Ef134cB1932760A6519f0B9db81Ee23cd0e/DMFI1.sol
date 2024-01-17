
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dance Music for Introverts Vol. 1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                                   _           _         //
//                                                  (_ )        ( )        //
//       ___    _    _ __   ___     __   _ __   ___  | |  _   _ | |_       //
//     /'___) /'_`\ ( '__)/' _ `\ /'__`\( '__)/'___) | | ( ) ( )| '_`\     //
//    ( (___ ( (_) )| |   | ( ) |(  ___/| |  ( (___  | | | (_) || |_) )    //
//    `\____)`\___/'(_)   (_) (_)`\____)(_)  `\____)(___)`\___/'(_,__/'    //
//                                                                         //
//                                                                         //
//    Dance Music for Introverts Vol. 1                                    //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract DMFI1 is ERC721Creator {
    constructor() ERC721Creator("Dance Music for Introverts Vol. 1", "DMFI1") {}
}
