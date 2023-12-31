// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Death and Life by MelzieQ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ╔╦╗┌─┐┌─┐┌┬┐┬ ┬  ┌─┐┌┐┌┌┬┐  ╦  ┬┌─┐┌─┐    //
//     ║║├┤ ├─┤ │ ├─┤  ├─┤│││ ││  ║  │├┤ ├┤     //
//    ═╩╝└─┘┴ ┴ ┴ ┴ ┴  ┴ ┴┘└┘─┴┘  ╩═╝┴└  └─┘    //
//    ┬┌┐┌  ┌┬┐┬ ┬┌─┐┌┬┐  ╔═╗┬─┐┌┬┐┌─┐┬─┐       //
//    ││││   │ ├─┤├─┤ │   ║ ║├┬┘ ││├┤ ├┬┘       //
//    ┴┘└┘   ┴ ┴ ┴┴ ┴ ┴   ╚═╝┴└──┴┘└─┘┴└─       //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MelzieQ is ERC721Creator {
    constructor() ERC721Creator("Death and Life by MelzieQ", "MelzieQ") {}
}
