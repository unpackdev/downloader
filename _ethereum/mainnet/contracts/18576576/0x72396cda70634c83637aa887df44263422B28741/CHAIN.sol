// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chain Reaction
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                          //
//                                                                                                                                                          //
//      oooooooo8 ooooo ooooo      o      ooooo oooo   oooo      oooooooooo  ooooooooooo      o       oooooooo8 ooooooooooo ooooo  ooooooo  oooo   oooo     //
//    o888     88  888   888      888      888   8888o  88        888    888  888    88      888    o888     88 88  888  88  888 o888   888o 8888o  88      //
//    888          888ooo888     8  88     888   88 888o88        888oooo88   888ooo8       8  88   888             888      888 888     888 88 888o88      //
//    888o     oo  888   888    8oooo88    888   88   8888        888  88o    888    oo    8oooo88  888o     oo     888      888 888o   o888 88   8888      //
//     888oooo88  o888o o888o o88o  o888o o888o o88o    88       o888o  88o8 o888ooo8888 o88o  o888o 888oooo88     o888o    o888o  88ooo88  o88o    88      //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CHAIN is ERC721Creator {
    constructor() ERC721Creator("Chain Reaction", "CHAIN") {}
}
