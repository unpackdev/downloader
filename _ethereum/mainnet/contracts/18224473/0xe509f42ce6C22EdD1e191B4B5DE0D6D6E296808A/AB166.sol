// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABFA1-ISeeYou-D
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//     █████  ██████  ███████  █████                                     //
//    ██   ██ ██   ██ ██      ██   ██                                    //
//    ███████ ██████  █████   ███████                                    //
//    ██   ██ ██   ██ ██      ██   ██                                    //
//    ██   ██ ██████  ██      ██   ██                                    //
//                                                                       //
//                                                                       //
//    //This is a contract for the sale of digital art                   //
//    created by Annette Back, based on the original painting            //
//    by Annette Back "I See You". The painting was created in 2017.     //
//    The digital art was created in 2023.                               //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract AB166 is ERC1155Creator {
    constructor() ERC1155Creator("ABFA1-ISeeYou-D", "AB166") {}
}
