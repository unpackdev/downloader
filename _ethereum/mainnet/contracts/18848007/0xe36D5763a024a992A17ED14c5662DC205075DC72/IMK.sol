// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abyssal Realm
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//      __                                   __                      //
//     /  | /                        /      /  |           /         //
//    (___|(___       ___  ___  ___ (      (___| ___  ___ (  _ _     //
//    |   )|   )\   )|___ |___ |   )|      |\   |___)|   )| | | )    //
//    |  / |__/  \_/  __/  __/ |__/||      | \  |__  |__/|| |  /     //
//                /                                                  //
//    by imkate                                                      //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract IMK is ERC721Creator {
    constructor() ERC721Creator("Abyssal Realm", "IMK") {}
}
