// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIЯRORS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//             @@@/         @@@%   @@@@       @@@@@@@@@   @@@@@@@@@           @@@@@@@        @@@@@@@@.         @@@@@@             //
//             @@@@@@     @@@@@%   @@@@    @@@@@@@@@@@@   @@@@@@@@@@@@,    @@@@@@@@@@@@@.    @@@@@@@@@@@@   @@@@@@@@@@            //
//             @@@@@@@@ @@@@@@@%   @@@@   @@@@     @@@@   @@@@     @@@@  @@@@@       @@@@@   @@@@    @@@@@  @@@@@                 //
//             @@@@ @@@@@@ @@@@%   @@@@    @@@@@@@@@@@@   @@@@@@@@@@@@   @@@@         @@@@   @@@@@@@@@@@@    @@@@@@@@@            //
//             @@@@   @@   @@@@%   @@@@     @@@@@@@@@@@   @@@@@@@@@@@     @@@@       @@@@@   @@@@@@@@@@            @@@@           //
//             @@@@        @@@@%   @@@@    @@@@    @@@@   @@@@    @@@@     @@@@@@@@@@@@@     @@@@   (@@@@  @@@@@@@@@@@@           //
//                                                                             #@@@@                           @@@@               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIRRORS is ERC721Creator {
    constructor() ERC721Creator(unicode"MIЯRORS", "MIRRORS") {}
}
