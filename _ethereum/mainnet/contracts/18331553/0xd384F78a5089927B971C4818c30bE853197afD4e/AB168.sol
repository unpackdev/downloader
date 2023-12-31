// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chazak-Strong
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//     █████  ██████  ███████  █████                                                          //
//    ██   ██ ██   ██ ██      ██   ██                                                         //
//    ███████ ██████  █████   ███████                                                         //
//    ██   ██ ██   ██ ██      ██   ██                                                         //
//    ██   ██ ██████  ██      ██   ██                                                         //
//                                                                                            //
//                                                                                            //
//    //This is a contract for the sale of digital art created by Annette Back.               //
//    It is a jpg of the painting "Chazak", which means Strong in hebrew.                     //
//    Ironically this painting was finished a week before the massacre on October 7, 2023.    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract AB168 is ERC721Creator {
    constructor() ERC721Creator("Chazak-Strong", "AB168") {}
}
