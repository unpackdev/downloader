// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CUTLOSS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    ░█████╗░██╗░░░██╗████████╗██╗░░░░░░█████╗░░██████╗░██████╗    //
//    ██╔══██╗██║░░░██║╚══██╔══╝██║░░░░░██╔══██╗██╔════╝██╔════╝    //
//    ██║░░╚═╝██║░░░██║░░░██║░░░██║░░░░░██║░░██║╚█████╗░╚█████╗░    //
//    ██║░░██╗██║░░░██║░░░██║░░░██║░░░░░██║░░██║░╚═══██╗░╚═══██╗    //
//    ╚█████╔╝╚██████╔╝░░░██║░░░███████╗╚█████╔╝██████╔╝██████╔     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract CL is ERC721Creator {
    constructor() ERC721Creator("CUTLOSS", "CL") {}
}
