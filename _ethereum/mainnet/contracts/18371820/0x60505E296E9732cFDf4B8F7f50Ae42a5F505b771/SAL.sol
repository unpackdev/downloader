// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anthony Ai Abstracts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    ░██████╗░█████╗░██╗░░░░░    //
//    ██╔════╝██╔══██╗██║░░░░░    //
//    ╚█████╗░███████║██║░░░░░    //
//    ░╚═══██╗██╔══██║██║░░░░░    //
//    ██████╔╝██║░░██║███████╗    //
//    ╚═════╝░╚═╝░░╚═╝╚══════╝    //
//                                //
//                                //
////////////////////////////////////


contract SAL is ERC721Creator {
    constructor() ERC721Creator("Anthony Ai Abstracts", "SAL") {}
}
