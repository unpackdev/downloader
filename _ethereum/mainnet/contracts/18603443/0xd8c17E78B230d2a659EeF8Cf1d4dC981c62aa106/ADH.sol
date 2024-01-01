// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Disappearing Heritage
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ███████╗ █████╗ ███╗   ██╗    //
//    ██╔════╝██╔══██╗████╗  ██║    //
//    ███████╗███████║██╔██╗ ██║    //
//    ╚════██║██╔══██║██║╚██╗██║    //
//    ███████║██║  ██║██║ ╚████║    //
//    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝    //
//                                  //
//                                  //
//////////////////////////////////////


contract ADH is ERC721Creator {
    constructor() ERC721Creator("A Disappearing Heritage", "ADH") {}
}
