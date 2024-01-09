
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1of1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//    ░█████╗░███╗░░░███╗██╗    //
//    ██╔══██╗████╗░████║██║    //
//    ██║░░██║██╔████╔██║██║    //
//    ██║░░██║██║╚██╔╝██║██║    //
//    ╚█████╔╝██║░╚═╝░██║██║    //
//    ░╚════╝░╚═╝░░░░░╚═╝╚═╝    //
//                              //
//                              //
//////////////////////////////////


contract ofo is ERC721Creator {
    constructor() ERC721Creator("1of1", "ofo") {}
}
