
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solo Species
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//     oooooooo8    ooooooo  ooooo         ooooooo         oooooooo8 oooooooooo ooooooooooo  oooooooo8 ooooo ooooooooooo  oooooooo8      //
//    888         o888   888o 888        o888   888o      888         888    888 888    88 o888     88  888   888    88  888             //
//     888oooooo  888     888 888        888     888       888oooooo  888oooo88  888ooo8   888          888   888ooo8     888oooooo      //
//            888 888o   o888 888      o 888o   o888              888 888        888    oo 888o     oo  888   888    oo          888     //
//    o88oooo888    88ooo88  o888ooooo88   88ooo88        o88oooo888 o888o      o888ooo8888 888oooo88  o888o o888ooo8888 o88oooo888      //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOLO is ERC721Creator {
    constructor() ERC721Creator("Solo Species", "SOLO") {}
}
