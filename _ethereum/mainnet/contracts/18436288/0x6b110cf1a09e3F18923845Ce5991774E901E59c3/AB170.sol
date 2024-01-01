// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Go Around 2023 ANNETTE BACK X Let Yourself Go by Mpozzecco
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//     █████  ██████  ███████  █████                                                   //
//    ██   ██ ██   ██ ██      ██   ██                                                  //
//    ███████ ██████  █████   ███████                                                  //
//    ██   ██ ██   ██ ██      ██   ██                                                  //
//    ██   ██ ██████  ██      ██   ██                                                  //
//                                                                                     //
//    This is a contract for the sale of digital art created by                        //
//    Annette Back in collaboration with Mpozzzeco.                                    //
//                                                                                     //
//    Animated art was created by using the artwork "Let Yourself Go" by Mpozzecco”    //
//    as a base and backround.                                                         //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract AB170 is ERC1155Creator {
    constructor() ERC1155Creator("Go Around 2023 ANNETTE BACK X Let Yourself Go by Mpozzecco", "AB170") {}
}
