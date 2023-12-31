// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: on-chained
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                   __                                       __         //
//                                  /\ \                __                   /\ \        //
//      ___     ___              ___\ \ \___      __   /\_\    ___      __   \_\ \       //
//     / __`\ /' _ `\  _______  /'___\ \  _ `\  /'__`\ \/\ \ /' _ `\  /'__`\ /'_` \      //
//    /\ \L\ \/\ \/\ \/\______\/\ \__/\ \ \ \ \/\ \L\.\_\ \ \/\ \/\ \/\  __//\ \L\ \     //
//    \ \____/\ \_\ \_\/______/\ \____\\ \_\ \_\ \__/.\_\\ \_\ \_\ \_\ \____\ \___,_\    //
//     \/___/  \/_/\/_/         \/____/ \/_/\/_/\/__/\/_/ \/_/\/_/\/_/\/____/\/__,_ /    //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract ONC is ERC721Creator {
    constructor() ERC721Creator("on-chained", "ONC") {}
}
