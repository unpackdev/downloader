// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I KNOW RIGHT creations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ██╗██╗  ██╗██████╗     //
//    ██║██║ ██╔╝██╔══██╗    //
//    ██║█████╔╝ ██████╔╝    //
//    ██║██╔═██╗ ██╔══██╗    //
//    ██║██║  ██╗██║  ██║    //
//    ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝    //
//                           //
//                           //
//                           //
///////////////////////////////


contract IKR is ERC721Creator {
    constructor() ERC721Creator("I KNOW RIGHT creations", "IKR") {}
}
